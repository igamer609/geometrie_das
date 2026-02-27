# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

#might need some refactoring and division into smaller components

extends Node2D

enum EditorMode {BUILD, EDIT}
enum SelectionMode {SINGLE, SWIPE}

var current_id : int = 0
var selected_objects : Array = []
var clipboard : Array = []
var swiping : bool = false
var swipe_start : Vector2
var swipe_rect : Rect2

var obj_base = ResourceLibrary.scenes["GDObject"]

@onready var camera : Camera2D = $Camera
@onready var level : Node2D = $Level
@onready var ui : CanvasLayer = $Editor_Object/UI_Layer
@onready var grid : Sprite2D = $Grid/GridSprite

@onready var editor_tabs : VBoxContainer = $Editor_Object/UI_Layer/Actions/Viewport/Tabs
@onready var top_bar : Control = $Editor_Object/UI_Layer/TopBar

@onready var item_tab : TabContainer = $Editor_Object/UI_Layer/Actions/Viewport/Items
@onready var edit_tab : Control = $Editor_Object/UI_Layer/Actions/Viewport/Edit
@onready var move_container : Control = $Editor_Object/UI_Layer/Actions/Viewport/Edit/MoveButtons
@onready var edit_other_actions : GridContainer = $Editor_Object/UI_Layer/Actions/Viewport/Edit/OtherButtons
@onready var swipe_toggle : Button = $Editor_Object/UI_Layer/Actions/Viewport/QuickOptions/Swipe

@onready var action_grid = $Editor_Object/UI_Layer/Actions/ObjectActions/ActionGrid
@onready var action_buttons = [$Editor_Object/UI_Layer/Actions/ObjectActions/ActionGrid/Copy, $Editor_Object/UI_Layer/Actions/ObjectActions/ActionGrid/Paste, $Editor_Object/UI_Layer/Actions/ObjectActions/ActionGrid/Duplicate, $Editor_Object/UI_Layer/Actions/ObjectActions/ActionGrid/Deselect, $Editor_Object/UI_Layer/TopBar/Delete]

var last_uid : int = 0

var history = UndoRedo.new()

var last_click_pos : Vector2
var last_grid_pos : Vector2
var select_index : int = 0
var zoom_multiplier : float = 1.0

var edit_mode : EditorMode = EditorMode.BUILD
var select_mode : SelectionMode = SelectionMode.SINGLE
var menu_state = false

var _level_meta : LevelMeta = LevelMeta.new()
var _level_path : String

var _current_spacial_index : Dictionary[Vector2, Array] = {}

var selection_center = null

const TEMPLATE_OBJ_DICT = {
	"obj_id" : 1,
	"uid" : 0,
	"transform" : [],
	"other" : {}
}

func _ready() -> void:
	_initialise_tabs()
	_initialise_items()
	_initialise_edit_btn()
	_initialise_actions()
	_initialise_top_bar()

func _save_level() -> bool:
	_level_meta.verified = 0
	var saved_objects : Array[LevelObject] = _get_data_of_objects(level.get_children())
	
	var save_data = LevelData.from_dict({
		"meta" : _level_meta,
		"objects" : []
	})
	save_data.objects = saved_objects
	
	if save_data.meta.title.is_empty():
		save_data.meta.title = "Untitled " + save_data.meta.local_id
	
	var error : Error = ResourceSaver.save(save_data, _level_path)
	
	if error == Error.OK:
		if ResourceLibrary.current_registry.type != LevelRegistry.RegistryType.CREATED:
			ResourceLibrary.load_registry( LevelRegistry.RegistryType.CREATED)
		
		var entry_data : LevelRegistryEntry = LevelRegistryEntry.generate_entry(save_data.meta, _level_path)
		ResourceLibrary.current_registry.updade_entry(save_data.meta.local_id, entry_data, true)
	
	return error

func _get_data_of_objects(objects : Array[Node]) -> Array:
	objects.sort_custom(func(a : Node, b : Node) : return b.global_position.x > a.global_position.x)
	
	if objects.size() > 0:
		var last_object_x = objects.back().global_position.x
		_level_meta.length =( last_object_x + 348) / 130
	else:
		_level_meta.length = 1
	
	var obj_data : Array[LevelObject] = []
	for obj : GDObject in objects:
		var obj_info : LevelObject = LevelObject.new()

		obj_info.obj_id = obj.obj_res.id
		obj_info.uid = obj.uid
		obj_info.transform = [var_to_str(obj.global_position), obj.global_rotation]

		if obj.trigger:
			obj_info.other["trigger"] = obj.trigger.get_info()
		
		obj_data.append(obj_info)
	return obj_data

func _load_obj(obj_id : int,  pos : Vector2, rot : float, other : Dictionary) -> Node2D: 
	last_uid += 1
	var object : GDObject = GDObject.create_object(obj_id, last_uid, pos, rot, other)
	
	if not _current_spacial_index.has(pos):
		_current_spacial_index[pos] = []
	_current_spacial_index[pos].append(object)
	
	level.add_child(object)
	return object

func _generate_unique_id() -> int:
	var time : int =int(Time.get_unix_time_from_system())
	var rand : int = randi() % 10000 + 1
	return time * 10000 + rand

func _load_level_file() -> void:
	var file_dialogue = FileDialog.new()
	file_dialogue.access = FileDialog.ACCESS_FILESYSTEM
	file_dialogue.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialogue.show_hidden_files = true
	file_dialogue.title = "Select level file "
	file_dialogue.add_filter("*.gdaslvl", "Geometrie Das level")
	
	ui.add_child(file_dialogue)
	file_dialogue.popup_centered(Vector2i(700, 500))
	
	await file_dialogue.file_selected
	
	var file_path = file_dialogue.current_path
	get_tree().queue_delete(file_dialogue)
	
	var lvl_data : LevelData = load(file_path)
	_level_path = file_path
	
	if lvl_data.has("objects") and lvl_data.meta.has("title") and lvl_data.meta.has("author") and lvl_data.meta.has("local_id"):
		_load_level(lvl_data.objects)
		_level_meta = lvl_data.meta
		
		if _level_meta.last_uid > 0:
			last_uid = _level_meta.last_uid
		
	else:
		$Editor_Object/Menu_Layer/AcceptDialog.visible = true

func _load_level(objects : Array) -> void:
	select_all()
	delete_objects()
	
	for obj : LevelObject in objects:
		_load_obj(obj.obj_id , str_to_var(obj.transform[0]), obj.transform[1], obj.other)

func load_level_from_data(lvl_data : LevelData, path) ->  bool:
	_level_meta = lvl_data.meta
	_level_path = path
	
	if _level_meta.local_id.is_empty():
		_level_meta.local_id = str(_generate_unique_id())
	
	if _level_meta.title.is_empty():
		_level_meta.title = "Untitled " + _level_meta.local_id
	
	_load_level(lvl_data.objects)
	
	_save_level()
	return true

func _initialise_top_bar():
	for button in top_bar.get_children():
		if button.name == "Delete":
			button.pressed.connect(delete_objects)
		elif button.name == "Menu":
			button.pressed.connect(_change_menu_state)
		elif button.name == "Undo":
			button.pressed.connect(history.undo)
		elif button.name == "Redo":
			button.pressed.connect(history.redo)
		elif button.name == "ZoomIn":
			button.pressed.connect(_zoom.bind(0.3))
		elif button.name == "ZoomOut":
			button.pressed.connect(_zoom.bind(-0.3))

func _initialise_tabs():
	var tab_group = ButtonGroup.new()
	for tab in editor_tabs.get_children():
		tab.button_group = tab_group
		if tab.name == "Build":
			tab.pressed.connect(_change_editor_mode.bind(EditorMode.BUILD))
		elif tab.name == "Edit":
			tab.pressed.connect(_change_editor_mode.bind(EditorMode.EDIT))

func _initialise_items():
	var btn_group = ButtonGroup.new()
	
	for button in item_tab.find_children("*", "Button"):
		button.button_group = btn_group
		button.select_item.connect(select_item_id.bind(button))

func _initialise_edit_btn():
	for move_group : Control in move_container.get_children():
		for button : Button in move_group.get_children():
			if button.is_in_group("16_unit"):
				button.pressed.connect(move_objects.bind(button.name, 1))
			elif button.is_in_group("8_unit"):
				button.pressed.connect(move_objects.bind(button.name, 0.5))
			elif button.is_in_group("1_unit"):
				button.pressed.connect(move_objects.bind(button.name, 0.1))
	for button : Button in edit_other_actions.get_children():
		if button.is_in_group("rot_right"):
			button.pressed.connect(rotate_objects.bind(1))
		elif button.is_in_group("rot_left"):
			button.pressed.connect(rotate_objects.bind(-1))
	
	$Editor_Object/Menu_Layer/EditorMenu/VBoxContainer/Load.pressed.connect(_load_level_file)
	$Editor_Object/Menu_Layer/EditorMenu/VBoxContainer/Save.pressed.connect(_save_level)
	$Editor_Object/Menu_Layer/EditorMenu/VBoxContainer/Resume.pressed.connect(_change_menu_state)
	$Editor_Object/Menu_Layer/EditorMenu/VBoxContainer/SaveAndExit.pressed.connect(_save_and_exit)
	$Editor_Object/Menu_Layer/EditorMenu/VBoxContainer/SaveAndPlay.pressed.connect(_save_and_play)
	$Editor_Object/Menu_Layer/EditorMenu/VBoxContainer/Exit.pressed.connect(_exit)

func _change_menu_state():
	menu_state = !menu_state
	$Editor_Object/Menu_Layer/EditorMenu.visible = menu_state

func _save_and_exit():
	_save_level()
	
	MenuMusic.start_music()
	history.clear_history()
	EditorTransition.load_level_edit_menu(LevelRegistryEntry.generate_entry(_level_meta, _level_path))

func _save_and_play():
	_save_level()
	
	history.clear_history()
	EditorTransition.load_game_from_entry(LevelRegistryEntry.generate_entry(_level_meta, _level_path), true, "res://Scenes/Menus/LevelEditingMenu.tscn")

func _exit():
	var dialog = $Editor_Object/Menu_Layer/EditorMenu/ExitDialog
	dialog.visible = true
	await dialog.confirmed
	MenuMusic.start_music()
	
	var lvl_res : LevelData = load(_level_path) as LevelData
	
	history.clear_history()
	EditorTransition.load_level_edit_menu(LevelRegistryEntry.generate_entry(_level_meta, _level_path))

func _change_editor_mode(new_mode):
	if new_mode != edit_mode:
		edit_mode = new_mode
		if edit_mode == EditorMode.BUILD:
			item_tab.visible = true
			edit_tab.visible = false
		if edit_mode == EditorMode.EDIT:
			item_tab.visible = false
			edit_tab.visible = true

func _initialise_actions():
	for button in action_grid.get_children():
		match button.name:
			"Copy": button.pressed.connect(copy_objects);
			"Paste": button.pressed.connect(paste_objects);
			"Duplicate": button.pressed.connect(duplicate_objects);
			"Deselect": button.pressed.connect(deselect);

func get_objects_at_point(pos : Vector2):
	var space : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query_parameters : PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query_parameters.position = pos
	var results : Array[Dictionary] = space.intersect_point(query_parameters)
	
	var objects : Array = []
	for result in results:
		if result["collider"].is_in_group("Object"):
			objects.append(result["collider"])
	
	return objects

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if edit_mode == EditorMode.BUILD && current_id != 0:
				if  select_mode == SelectionMode.SINGLE:
					place_object()
				elif select_mode == SelectionMode.SWIPE:
					swiping = true
					place_object()
			elif edit_mode == EditorMode.EDIT:
				if select_mode == SelectionMode.SINGLE:
					var click_pos : Vector2 = get_global_mouse_position()
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
					
				if select_mode == SelectionMode.SWIPE:
					swiping = true
					swipe_start = get_global_mouse_position()
		if not event.pressed:
			last_click_pos = Vector2.ZERO
			if swiping:
				swiping = false
				queue_redraw()
				if edit_mode == EditorMode.EDIT:
					_box_select()
	
	if event is InputEventMouseMotion:
		if event.button_mask in [MOUSE_BUTTON_MASK_MIDDLE, MOUSE_BUTTON_MASK_RIGHT]:
			camera.global_position -= event.relative * 0.50
			update_grid_position()
		elif event.button_mask in [MOUSE_BUTTON_LEFT] and swiping and edit_mode == EditorMode.EDIT:
			swipe_rect = Rect2(swipe_start, get_global_mouse_position() - swipe_start)
			queue_redraw()
		elif event.button_mask in [MOUSE_BUTTON_LEFT] and swiping and edit_mode == EditorMode.BUILD:
			
			var current_grid_pos : Vector2 = get_global_mouse_position()
			current_grid_pos.x = snapped(current_grid_pos.x - 8, 16)
			current_grid_pos.y = snapped(current_grid_pos.y - 8, 16)
			
			if current_id != 0 and current_grid_pos != last_grid_pos:
				place_object()
				last_grid_pos = current_grid_pos

func _draw() -> void:
	if swiping && edit_mode == EditorMode.EDIT:
		draw_rect(swipe_rect, Color(0, 1, 0, 1), false)

func _zoom(amount : float):
	zoom_multiplier += amount
	zoom_multiplier = clamp(zoom_multiplier, 0.3, 2.1)
	
	#TransitionScene.show_message("x" + str(zoom_multiplier))
	
	camera.zoom = Vector2(3 * zoom_multiplier, 3 * zoom_multiplier)
	update_grid_position()

func _box_select():
	for object in level.get_children():
		if object.is_in_group("Object"):
			var obj_rect : Rect2 = object.get_selection_rect().abs()
			swipe_rect = swipe_rect.abs()
			if swipe_rect.intersects(obj_rect):
				select_object(object)

func select_item_id(new_id : int, button : Button):
	if new_id and new_id != current_id:
		current_id = new_id
	else:
		current_id = 0
		button.button_pressed = false

func _is_same_object_at_pos(pos : Vector2) -> bool:
	if not _current_spacial_index.has(pos):
		return false
	else:
		if not _current_spacial_index[pos].is_empty():
			for object : GDObject in _current_spacial_index[pos]:
				if object.obj_res.id == current_id:
					return true
	
	return false

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

func place_object(return_obj : bool = true) -> GDObject:
	
	var pos : Vector2 = get_global_mouse_position()
	pos.x = snapped(pos.x - 8, 16)
	pos.y = snapped(pos.y - 8, 16)
	
	if _is_same_object_at_pos(pos):
		return
	
	if selected_objects.size() == 1 and selected_objects[0].obj_res.id == current_id:
		history.create_action("Place object")
		
		var object : Node2D = _load_obj(current_id, pos,  0,  selected_objects[0].other)
		
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
		history.add_do_reference(object)
		history.add_undo_method(_remove_object_from_level.bind(object))
		history.commit_action()
		
		select_single(object)
		if return_obj:
			return object
	else:
		history.create_action("Place object")
		
		var other : Dictionary = {}
		
		var object : Node2D = _load_obj(current_id, pos, 0, other)
		
		history.add_do_method(_add_object_to_level.bind(object))
		history.add_do_reference(object)
		history.add_undo_method(_remove_object_from_level.bind(object))
		history.commit_action()
		
		select_single(object)
		
		if return_obj:
			return object
	
	return

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

func select_all():
	deselect()
	
	for object in level.get_children():
		if object.is_class("StaticBody2D"):
			select_object(object, false)

# To be changed! Has to use formula for calculating center of gravity for n objects (x = x1 + x2 + ... + xn / n, same for y)
func update_selection_center():
	if len(selected_objects) >= 2:
		if selection_center:
			get_tree().queue_delete(selection_center)
		
		selection_center = Node2D.new()
		
		var obj_positions = ([])
		
		for object in selected_objects:
			obj_positions.append([object.global_position.x + 8 * cos(object.global_rotation), object.global_position.y + 8 * cos(object.global_rotation)])
		
		var average_x : float = 0
		var average_y : float = 0
		
		for vector2 in obj_positions:
			average_x += (vector2[0] / len(obj_positions))
			average_y += (vector2[1] / len(obj_positions))
		
		selection_center.global_position = Vector2(average_x, average_y)
		
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
	
	if selection_center:
		get_tree().queue_delete(selection_center)

func remove_from_selection(obj : Node2D):
	var obj_index : int = selected_objects.find(obj)
	if obj_index > -1:
		selected_objects.remove_at(obj_index)
		obj.deselect()

func delete_objects():
	var objects_to_delete = selected_objects.duplicate(true)
	deselect()
	
	history.create_action("Delete")
	
	for obj in objects_to_delete:
		
		history.add_undo_method(_add_object_to_level.bind(obj))
		history.add_undo_reference(obj)
		
		history.add_do_method(_remove_object_from_level.bind(obj))
		history.add_do_reference(obj)
	
	history.commit_action()
	

func move_objects(direction, amount : float) -> void:
	var moved_obj = selected_objects
	
	history.create_action("Move")
	
	for object : GDObject in moved_obj:
		
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

func rotate_objects(direction):
	
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
	
	for object in selected_objects:
		var obj_pos = camera.to_local(object.global_position)
		var obj_rot = object.global_rotation
		
		clipboard.append([object, obj_pos, obj_rot])

func paste_objects():
	if len(clipboard) >= 1:
		
		history.create_action("Paste")
		
		deselect()
		
		var pasted_objects = []
		
		for object in clipboard:
			var new_object : GDObject = _load_obj(object[0].obj_res.id, Vector2(snapped((camera.to_global(object[1])).x, 16) , snapped((camera.to_global(object[1])).y, 16) ), object[2], object[3])
			
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
		
		var object = _load_obj(obj.obj_res.id, obj.global_position, obj.global_rotation, obj.other)

		select_object(object, true)
		
		history.add_do_method(_add_object_to_level.bind(object))
		history.add_do_reference(object)
		history.add_undo_method(_remove_object_from_level.bind(object))
		history.add_undo_reference(object)
	
	history.commit_action()
	
	update_selection_center()

func check_actions():
	if len(selected_objects) > 0:
		action_buttons[0].disabled = false
		action_buttons[2].disabled = false
		action_buttons[3].disabled = false
		action_buttons[4].disabled = false
	else:
		action_buttons[0].disabled = true
		action_buttons[2].disabled = true
		action_buttons[3].disabled = true
		action_buttons[4].disabled = true
	
	if len(clipboard) > 0:
		action_buttons[1].disabled = false
	else:
		action_buttons[1].disabled = true

func _process(_delta):
	
	if Input.is_action_just_pressed("RotateLeft"):
		rotate_objects(-1)
	if Input.is_action_just_pressed("RotateRight"):
		rotate_objects(1)
	
	if Input.is_action_just_pressed("MoveUp"):
		move_objects("Up", 1)
	if Input.is_action_just_pressed("MoveDown"):
		move_objects("Down", 1)
	if Input.is_action_just_pressed("MoveLeft"):
		move_objects("Left", 1)
	if Input.is_action_just_pressed("MoveRight") and not Input.is_action_just_pressed("Duplicate"):
		move_objects("Right", 1)
	
	if Input.is_action_just_pressed("Undo"):
		history.undo()
	if Input.is_action_just_pressed("Redo"):
		history.redo()
	
	if  not swipe_toggle.button_pressed:
		select_mode = SelectionMode.SINGLE
	
	if Input.is_action_pressed("Swipe") or swipe_toggle.button_pressed:
		select_mode = SelectionMode.SWIPE
	
	if Input.is_action_just_pressed("Duplicate"):
		duplicate_objects()
	
	if Input.is_action_just_pressed("Copy"):
		copy_objects()
	
	if Input.is_action_just_pressed("Paste"):
		paste_objects()
	
	if Input.is_action_just_pressed("Delete"):
		delete_objects()
	
	check_actions()

# --------- Update editor elements on input or process ----------

##Updates position of the grid in relation to the center of the camera
func update_grid_position():
	var camera_pos : Vector2 = camera.global_position
	var target_grid_position : Vector2 = Vector2(snapped(camera_pos.x  - (grid.region_rect.size.x / 4), 16), snapped(camera_pos.y + (grid.region_rect.size.y / 4), 16))
	
	var camera_rect : Vector2 = get_viewport_rect().size * 3 / camera.zoom
	grid.region_rect.size = camera_rect
	
	if target_grid_position.x < 0:
		target_grid_position.x = 0
	
	grid.global_position = target_grid_position

# --------- Operation Methods (for undo-redo system) -----------

func _add_object_to_level(object : Node2D):
	if object.get_parent() != level:
		level.add_child(object)
		
		_current_spacial_index[object.global_position].append(object)

func _remove_object_from_level(object : Node2D):
	remove_from_selection(object)
	
	if _current_spacial_index.has(object.global_position):
		_current_spacial_index[object.global_position].erase(object)
	if object.get_parent() == level:
		level.remove_child(object)
	else:
		pass
