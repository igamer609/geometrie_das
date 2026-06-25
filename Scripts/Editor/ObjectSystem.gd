extends Node

signal loaded_objects
signal updated_selection(selected_objects : Array[GDObject])
signal updated_clipboard(clipboard : Array)

@export var editor : Node2D
@export var input_controller : Node

@export var level : Node2D
@export var camera : Camera2D

var history = UndoRedo.new()
var last_uid : int = 0

var current_id : int = 0
var selected_objects : Array[GDObject] = []
var clipboard : Array = []
var selection_center : Node2D = null

var _current_spacial_index : Dictionary[Vector2, Array] = {}
var material_cache : MaterialCache = MaterialCache.new()

var last_click_pos : Vector2
var last_grid_pos : Vector2
var select_index : int = 0

func _ready() -> void:
	editor.load_level_data.connect(_load_level)
	input_controller.place_pressed.connect(place_object)
	input_controller.place_swiped.connect(place_with_check)
	input_controller.select_single.connect(_on_single_selection)
	input_controller.swipe_finished.connect(_box_select)
	input_controller.move.connect(move_objects)
	input_controller.rotate.connect(rotate_objects)

func select_item_id(new_id : int, button : Button) -> void:
	if(new_id > 0 and new_id != current_id):
		current_id = new_id
	else:
		current_id = 0
		button.button_pressed = false

func _load_level(level_data : LevelData) -> void:
	for obj : LevelObject in level_data.objects:
		_load_obj(obj.obj_id , str_to_var(obj.transform[0]), obj.transform[1], obj.other)
	
	loaded_objects.emit()

func _load_obj(obj_id : int,  pos : Vector2, rot : float, other : Dictionary) -> GDObject: 
	last_uid += 1
	var object : GDObject = GDObject.create_object(obj_id, last_uid, pos, rot, other, material_cache)
	
	if not _current_spacial_index.has(pos):
		_current_spacial_index[pos] = []
	_current_spacial_index[pos].append(object)
	
	level.add_child(object)
	return object

func _duplicate_obj(obj : GDObject, new_pos : Vector2, new_rot : float) -> GDObject:
	last_uid += 1
	var object : GDObject = GDObject.duplicate_object(obj, last_uid, new_pos, new_rot)
	
	if not _current_spacial_index.has(new_pos):
		_current_spacial_index[new_pos] = []
	_current_spacial_index[new_pos].append(object)
	
	level.add_child(object)
	return object

func _is_same_object_at_pos(pos : Vector2) -> bool:
	if not _current_spacial_index.has(pos):
		return false
	else:
		if not _current_spacial_index[pos].is_empty():
			for object : GDObject in _current_spacial_index[pos]:
				if object.obj_res.id == current_id:
					return true
	
	return false

func get_objects_at_point(pos : Vector2):
	var space : PhysicsDirectSpaceState2D = editor.get_world_2d().direct_space_state
	var query_parameters : PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query_parameters.position = pos
	var results : Array[Dictionary] = space.intersect_point(query_parameters)
	
	var objects : Array = []
	for result : Dictionary in results:
		if result["collider"].is_in_group("Object"):
			if editor._is_on_editor_layer(result["collider"] as GDObject): 
				objects.append(result["collider"])
	
	return objects

func _update_obj_ref_position(obj : GDObject, old_pos : Vector2, pos : Vector2) -> void:
	
	if _current_spacial_index.has(old_pos):
		
		var obj_array : Array = _current_spacial_index[old_pos]
		obj_array.erase(obj)
		
		if obj_array.is_empty():
			_current_spacial_index.erase(old_pos)
	
	obj.global_position = pos
	
	if not _current_spacial_index.has(pos):
		_current_spacial_index[pos] = []
	
	_current_spacial_index[pos].append(obj)

func _on_single_selection(click_pos : Vector2) -> void:
	if click_pos != last_click_pos:
		select_index = 0
		last_click_pos = click_pos
	
	var selection : Array = get_objects_at_point(click_pos)
	if  len(selection) == 0:
		deselect()
		return
	
	select_single(selection[select_index])
	
	if select_index < (len(selection) - 1):
		select_index += 1

func _box_select(start_pos : Vector2) -> void:
	
	var swipe_rect : Rect2 = Rect2(start_pos, editor.get_global_mouse_position() - start_pos)
	
	for object in level.get_children():
		if object.is_in_group("Object"):
			var obj_rect : Rect2 = object.get_selection_rect().abs()
			swipe_rect = swipe_rect.abs()
			if swipe_rect.intersects(obj_rect) and editor._is_on_editor_layer(object):
				select_object(object)
	
	updated_selection.emit(selected_objects)

func place_object(return_obj : bool = true) -> GDObject:
	
	if(current_id <= 0):
		return null
	
	var pos : Vector2 = editor.get_global_mouse_position()
	pos.x = snapped(pos.x - 8, 16)
	pos.y = snapped(pos.y - 8, 16)
	
	if _is_same_object_at_pos(pos):
		return
	
	if selected_objects.size() == 1 and selected_objects[0].obj_res.id == current_id:
		history.create_action("Place object")
		
		var new_other : Dictionary = selected_objects[0].other.duplicate(true)
		if editor.current_editor_layer >= 0:
			new_other["editor_layer"] = editor.current_editor_layer
		else: 
			new_other["editor_layer"] = 0

		var object : Node2D = _load_obj(current_id, pos,  0,  new_other)
		
		var rot_center : Node2D = Node2D.new()
		rot_center.global_position = object.get_child(0).global_position
		
		level.add_child(rot_center)
		object.reparent(rot_center)
		rot_center.rotate(selected_objects[0].global_rotation)
		var new_pos : Vector2 = object.global_position
		var new_rot : float = object.global_rotation
		
		object.reparent(level)
		object.global_position = new_pos
		object.global_rotation = new_rot
		get_tree().queue_delete(rot_center)
		
		history.add_do_method(_add_object_to_level.bind(object))
		history.add_do_method(select_single.bind(object))
		history.add_do_reference(object)
		history.add_undo_method(_remove_object_from_level.bind(object))
		history.commit_action()
		
		select_single(object)
		
		if return_obj:
			return object
	else:
		history.create_action("Place object")
		
		var other : Dictionary = {
			"editor_layer" : editor.current_editor_layer
		}
		
		if editor.current_editor_layer < 0:
			other["editor_layer"] = 0
		
		var object : Node2D = _load_obj(current_id, pos, 0, other)
		
		history.add_do_method(_add_object_to_level.bind(object))
		history.add_do_reference(object)
		history.add_undo_method(_remove_object_from_level.bind(object))
		history.commit_action()
		
		select_single(object)
		
		if return_obj:
			return object
	
	return

func place_with_check() -> void:
	var current_grid_pos : Vector2 = editor.get_global_mouse_position()
	current_grid_pos.x = snapped(current_grid_pos.x - 8, 16)
	current_grid_pos.y = snapped(current_grid_pos.y - 8, 16)
			
	if(current_id != 0 && current_grid_pos != last_grid_pos):
		place_object()
		last_grid_pos = current_grid_pos

func select_object(object : Node2D, pasted : bool = false):
	if object  not in selected_objects:
		
		selected_objects.append(object)
		if pasted:
			object.select()
		else:
			object.select()
		
		if not is_instance_valid(object):
			selected_objects.erase(object)
		
		update_selection_center()
	else:
		pass

func select_single(object):
	deselect()
	select_object(object)
	updated_selection.emit(selected_objects)

func select_all():
	deselect()
	
	for object in level.get_children():
		if object.is_class("StaticBody2D"):
			select_object(object, false)
	
	updated_selection.emit(selected_objects)

# To be changed! Has to use formula for calculating center of gravity for n objects (x = x1 + x2 + ... + xn / n, same for y)
func update_selection_center():
	if len(selected_objects) >= 2:
		if selection_center:
			get_tree().queue_delete(selection_center)
		
		selection_center = Node2D.new()
		
		var sum_x : float = 0
		var sum_y : float = 0
		
		for object in selected_objects:
			sum_x += object.global_position.x + 8
			sum_y += object.global_position.y + 8
		
		selection_center.global_position = Vector2(sum_x / selected_objects.size(), sum_y / selected_objects.size())
		selection_center.remove_from_group("Object")
		level.add_child(selection_center)
	else:
		if selection_center:
			get_tree().queue_delete(selection_center)

func deselect():
	for obj : Node2D in selected_objects:
		if is_instance_valid(obj):
			obj.deselect()
		else:
			printerr("Attempted to deselect previously freed objects. Checking certainty of all objects.")
			var unknown_objects = selected_objects
			selected_objects = []
			
			for unknown_state_obj in unknown_objects:
				if is_instance_valid(unknown_state_obj):
					select_object(unknown_state_obj, false)
	
	selected_objects.clear()
	updated_selection.emit(selected_objects)
	
	if selection_center:
		get_tree().queue_delete(selection_center)

func remove_from_selection(obj : Node2D):
	var obj_index : int = selected_objects.find(obj)
	if obj_index > -1:
		selected_objects.remove_at(obj_index)
		obj.deselect()
	updated_selection.emit(selected_objects)

func delete_objects():
	var objects_to_delete = selected_objects.duplicate(true)
	deselect()
	
	history.create_action("Delete")
	
	for obj : GDObject in objects_to_delete:
		
		history.add_undo_method(_add_object_to_level.bind(obj))
		if(obj.is_selected):
			history.add_undo_method(select_object.bind(obj))
		history.add_undo_reference(obj)
		
		history.add_do_method(_remove_object_from_level.bind(obj))
		history.add_do_method(remove_from_selection.bind(obj))
		history.add_do_reference(obj)
	
	history.commit_action()

func move_objects(direction, amount : float) -> void:
	history.create_action("Move")
	
	for object : GDObject in selected_objects:
		
		if not is_instance_valid(object):
			continue
		
		var old_pos : Vector2 = object.global_position
		var new_pos : Vector2 = object.global_position
		
		if direction == "Up":
			new_pos.y -= roundi(amount * 16)
		elif direction == "Down":
			new_pos.y += roundi(amount * 16)
		elif direction == "Left":
			new_pos.x -= roundi(amount * 16)
		elif direction == "Right":
			new_pos.x += roundi(amount * 16)
		
		history.add_undo_method(_update_obj_ref_position.bind(object, new_pos, old_pos))
		history.add_do_method(_update_obj_ref_position.bind(object, old_pos, new_pos))
	
	history.commit_action()
	update_selection_center()

func rotate_objects(direction : int):
	
	history.create_action("Rotate")
	
	if selection_center and len(selected_objects) >= 2:
		for object in selected_objects:
			history.add_undo_property(object, "global_rotation", object.global_rotation)
			history.add_undo_property(object, "global_position", object.global_position)
			object.reparent(selection_center)
			selection_center.rotate(deg_to_rad(direction * 90))
			
			var obj_position = object.global_position
			var obj_rotation = object.global_rotation
			
			object.reparent(level)
			
			object.global_position = obj_position
			object.global_rotation = obj_rotation
			
			history.add_do_property(object, "global_rotation", object.global_rotation)
			history.add_do_property(object, "global_position", object.global_position)
			
			selection_center.global_rotation = 0
	elif len(selected_objects) == 1:
		var rot_center : Node2D = Node2D.new()
		rot_center.global_position = selected_objects[0].get_child(0).global_position
		level.add_child(rot_center)
		history.add_undo_property(selected_objects[0], "global_rotation", selected_objects[0].global_rotation)
		history.add_undo_property(selected_objects[0], "global_position", selected_objects[0].global_position)
		
		if selected_objects[0].is_inside_tree():
			selected_objects[0].reparent(rot_center)
		else:
			selected_objects[0].parent = rot_center
		
		rot_center.rotate(deg_to_rad(direction * 90))
		var new_pos : Vector2 = selected_objects[0].global_position
		var new_rot : float = selected_objects[0].global_rotation
		selected_objects[0].reparent(level)
		selected_objects[0].global_position = new_pos
		selected_objects[0].global_rotation = new_rot
		get_tree().queue_delete(rot_center)
		
		history.add_do_property(selected_objects[0], "global_rotation", selected_objects[0].global_rotation)
		history.add_do_property(selected_objects[0], "global_position", selected_objects[0].global_position)
	
	history.commit_action()

func copy_objects():
	clipboard.clear()
	
	for object : GDObject in selected_objects:
		var obj_pos = camera.to_local(object.global_position)
		var obj_rot = object.global_rotation
		var  obj_other = object.other
		
		clipboard.append([object, obj_pos, obj_rot, obj_other])
	
	updated_clipboard.emit(clipboard)

func paste_objects():
	if len(clipboard) >= 1:
		
		history.create_action("Paste")
		
		deselect()
		
		var pasted_objects = []
		
		for object in clipboard:
			var projected_pos : Vector2 = Vector2(snapped((camera.to_global(object[1])).x, 16) , snapped((camera.to_global(object[1])).y, 16))
			var new_object : GDObject = _duplicate_obj(object[0], projected_pos, object[2])
			
			pasted_objects.append(new_object)
			
			history.add_do_method(_add_object_to_level.bind(new_object))
			history.add_do_reference(new_object)
			history.add_undo_method(_remove_object_from_level.bind(new_object))
		
		history.commit_action()
		
		for object in pasted_objects:
			select_object(object, true)
		

func duplicate_objects():
	var objects_to_duplicate = selected_objects.duplicate(true)
	deselect()
	
	history.create_action("Duplicate")
	
	for obj : GDObject in objects_to_duplicate:
		
		var object = _duplicate_obj(obj, obj.global_position, obj.global_rotation)

		select_object(object, true)
		
		history.add_do_method(_add_object_to_level.bind(object))
		history.add_do_reference(object)
		history.add_undo_method(_remove_object_from_level.bind(object))
		history.add_undo_reference(object)
	
	history.commit_action()
	
	update_selection_center()

func _add_object_to_level(object : Node2D):
	if object.get_parent() != level:
		object._show()
		level.add_child(object)
		if(_current_spacial_index.has(object.global_position)):
			_current_spacial_index[object.global_position].append(object)

func _remove_object_from_level(object : Node2D):
	remove_from_selection(object)
	
	if _current_spacial_index.has(object.global_position):
		_current_spacial_index[object.global_position].erase(object)
		if(_current_spacial_index[object.global_position].size() == 0):
			_current_spacial_index.erase(object.global_position)
	if object.get_parent() == level:
		object._hide()
		level.remove_child(object)
	else:
		pass
