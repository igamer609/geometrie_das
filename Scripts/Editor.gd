# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Node2D

enum EditorMode {BUILD, EDIT}
enum SelectionMode {SINGLE, SWIPE}

var current_id : int = 0
var selected_objects : Array = []
var clipboard : Array = []
var swiping : bool = false
var swipe_start : Vector2
var swipe_rect : Rect2

@onready var obj_base = preload("res://Objects/object.tscn")

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
var select_index : int = 0
var zoom_multiplier : float = 1.0

var edit_mode : EditorMode = EditorMode.BUILD
var select_mode : SelectionMode = SelectionMode.SINGLE
var menu_state = false

var level_data = {"local_id": 0, "name" : "", "author" : "", "difficulty" : 0, "version" : (str(Engine.get_version_info()["major"]) + "." + str(Engine.get_version_info()["minor"])), "song_id" : 0, "last_uid" : 0, "song_offset" : 0, "verified" : 0, "published_id" : -1}

var selection_center = null

const TEMPLATE_OBJ_DICT = {
	"obj_id" : 1,
	"uid" : 0,
	"transform" : [],
	"other" : {}
}

func _ready():
	_initialise_tabs()
	_initialise_items()
	_initialise_edit_btn()
	_initialise_actions()
	_initialise_top_bar()

func _save_level():
	var save_data = {
		"info" : level_data,
		"objects" : []
	}

	save_data["objects"] = _get_data_of_objects(level.get_children())
	
	if not DirAccess.dir_exists_absolute("user://saved_levels/"):
		DirAccess.make_dir_absolute("user://saved_levels/")
	
	if not save_data["info"].has("local_id"):
		print(save_data["info"])
		save_data["info"]["local_id"] = _generate_unique_id()
	
	var save_file : FileAccess = FileAccess.open("user://saved_levels/" +str( int(save_data["info"]["local_id"])) + ".gdaslvl", FileAccess.WRITE)
	var save_string : String = JSON.stringify(save_data)
	
	var success : bool = save_file.store_line(save_string)
	
	return success

func _get_data_of_objects(objects : Array[Node]):
	var obj_data : Array[Dictionary] = []
	for obj in objects:
		if obj.is_class("StaticBody2D"):
			var obj_info = TEMPLATE_OBJ_DICT.duplicate()

			obj_info.obj_id = obj.obj_res.id
			obj_info.uid = obj.uid
			obj_info["transform"] = [var_to_str(obj.global_position), obj.global_rotation]

			if obj.obj_res.is_trigger:
				obj_info["other"]["trigger_info"] = obj.trigger.get_info()
			
			obj_data.append(obj_info)
	
	return obj_data

func _load_obj(obj_id : int, uid : int, pos : Vector2, rot : float, other : Dictionary) -> Node2D: 
	var item = ResourceLibrary.library[obj_id]
	
	var object : GDObject = obj_base.instantiate()
	object.uid = uid
	object.obj_res = item
	
	object.global_position = pos
	object.global_rotation = rot
	object.other = other
	
	level.add_child(object)
	return object

func _generate_unique_id() -> int:
	var time : int = Time.get_unix_time_from_system()
	var rand : int = randi() % 10000 + 1
	return time * 10000 + rand

func _load_level_file():
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
	
	var lvl_file = FileAccess.open(file_path, FileAccess.READ)
	var lvl_info = JSON.parse_string(lvl_file.get_line())
	
	if lvl_info.has("objects") and lvl_info.has("name") and lvl_info.has("author") and lvl_info.has("local_id"):
		_load_level(lvl_info["objects"])
		level_data = lvl_info
		
		if level_data["last_uid"] > 0:
			last_uid = level_data["last_uid"]
		
	else:
		$Editor_Object/Menu_Layer/AcceptDialog.visible = true

func _load_level(objects):
	select_all()
	delete_objects()
	
	for obj in objects:
		_load_obj(obj["obj_id"], obj["uid"] , str_to_var(obj["transform"][0]), obj["transform"][1], obj["other"])

func load_level_from_info(lvl_info):
	level_data = lvl_info["info"]
	
	if lvl_info.has("objects"):
		_load_level(lvl_info["objects"])
	
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
	
	for container in item_tab.get_children():
		for button in container.get_children():
			button.button_group = btn_group
			button.select_item.connect(select_item_id)

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
	TransitionScene.change_scene("res://Scenes/Menus/CreateTab.tscn")

func _save_and_play():
	_save_level()
	
	var save_data = {
		"info" : level_data,
		"objects" : []
	}

	save_data["objects"] = _get_data_of_objects(level.get_children())
	
	EditorTransition.load_game(save_data, false, true)

func _exit():
	var dialog = $Editor_Object/Menu_Layer/EditorMenu/ExitDialog
	dialog.visible = true
	await dialog.confirmed
	MenuMusic.start_music()
	TransitionScene.change_scene("res://Scenes/Menus/CreateTab.tscn")

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
		# var object : Node2D = result["collider"] -- used in debug print statements
		objects.append(result["collider"])
	
	return objects

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if edit_mode == EditorMode.BUILD && current_id != 0:
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
			if swiping:
				swiping = false
				queue_redraw()
				_box_select()
	
	if event is InputEventMouseMotion:
		if event.button_mask in [MOUSE_BUTTON_MASK_MIDDLE, MOUSE_BUTTON_MASK_RIGHT]:
			camera.global_position -= event.relative * 0.50
			
			update_grid_position()
		elif event.button_mask in [MOUSE_BUTTON_LEFT] and swiping:
			swipe_rect = Rect2(swipe_start, get_global_mouse_position() - swipe_start)
			queue_redraw()

func _draw() -> void:
	if swiping:
		draw_rect(swipe_rect, Color(0, 1, 0, 1), false)

func _zoom(amount : float):
	zoom_multiplier += amount
	zoom_multiplier = clamp(zoom_multiplier, 0.5, 2)
	
	camera.zoom = Vector2(3 * zoom_multiplier, 3 * zoom_multiplier)
	update_grid_position()

func _box_select():
	for object in level.get_children():
		if object.is_class("StaticBody2D"):
			var obj_rect : Rect2 = object.get_selection_rect().abs()
			swipe_rect = swipe_rect.abs()
			if swipe_rect.intersects(obj_rect):
				select_object(object)

func select_item_id(new_id):
	if new_id and new_id != current_id:
		current_id = new_id

func place_object(return_obj = false):
	
	last_uid += 1
	var pos : Vector2 = get_global_mouse_position()
	pos.x = snapped(pos.x - 8, 16)
	pos.y = snapped(pos.y - 8, 16)
	
	if len(selected_objects) == 1 and selected_objects[0].obj_res.id == current_id:
		history.create_action("Place object")
		
		var object : Node2D = _load_obj(current_id, last_uid, pos,  0,  selected_objects[0].other)
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
		var item : GD_Object = ResourceLibrary.library[current_id]
		history.create_action("Place object")
		
		var object : Node2D = obj_base.instantiate()
		object.obj_res = item
		object.uid = last_uid
		object.global_position = pos
		
		history.add_do_method(_add_object_to_level.bind(object))
		history.add_do_reference(object)
		history.add_undo_method(_remove_object_from_level.bind(object))
		history.commit_action()
		
		select_single(object)
		
		if return_obj:
			return object

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

func update_selection_center():
	if len(selected_objects) >= 2:
		if selection_center:
			get_tree().queue_delete(selection_center)
		
		selection_center = Node2D.new()
		
		var obj_positions = ([])
		
		for object in selected_objects:
			obj_positions.append([object.global_position.x + 8 * cos(object.global_rotation), object.global_position.y + 8 * cos(object.global_rotation)])
		
		var average_x = 0
		var average_y = 0
		
		for vector2 in obj_positions:
			average_x += (round(vector2[0]) / len(obj_positions))
			average_y += (round(vector2[1]) / len(obj_positions))
		
		selection_center.global_position = Vector2(snapped(average_x, 1), snapped(average_y, 1))
		
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
	var objects_to_delete = selected_objects.duplicate()
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
	
	for object in moved_obj:
		
		if not is_instance_valid(object):
			continue
		
		history.add_undo_property(object, "global_position", object.global_position)
		
		if direction == "Up":
			object.global_position.y -= roundi(amount * 16)
		elif direction == "Down":
			object.global_position.y += roundi(amount * 16)
		elif direction == "Left":
			object.global_position.x -= roundi(amount * 16)
		elif direction == "Right":
			object.global_position.x += roundi(amount * 16)
		
		print(object.global_position)
		
		history.add_do_property(object, "global_position", object.global_position)
		
		update_selection_center()
	
	history.commit_action()

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
		
		if selected_objects[0].obj_res.is_trigger:
			for child in selected_objects[0].get_children():
				if child.name == "embedded_scene":
					child.global_rotation = 0
	
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
			var item = load("res://Objects/obj_ids/" + str(object[0].obj_res.id) + ".tres")
		
			var new_object = obj_base.instantiate()
			new_object.obj_res = item
			
			new_object.global_position = Vector2(snapped((camera.to_global(object[1])).x, 16) , snapped((camera.to_global(object[1])).y, 16) )
			new_object.global_rotation = object[2]
			
			pasted_objects.append(new_object)
			
			history.add_do_method(_add_object_to_level.bind(new_object))
			history.add_do_reference(new_object)
			history.add_undo_method(_remove_object_from_level.bind(new_object))
		
		history.commit_action()
		
		for object in pasted_objects:
			select_object(object, true)
		

func duplicate_objects():
	var objects_to_duplicate = selected_objects.duplicate()
	deselect()
	
	history.create_action("Duplicate")
	
	for obj in objects_to_duplicate:
		
		var item = load("res://Objects/obj_ids/" + str(obj.obj_res.id) + ".tres")
	
		var object = obj_base.instantiate()
		object.obj_res = item
		
		object.global_position = obj.global_position
		object.global_rotation = obj.global_rotation
		
		level.add_child(object)
		select_object(object, true)
		
		history.add_do_method(_add_object_to_level.bind(object))
		history.add_do_reference(object)
		history.add_undo_method(_remove_object_from_level.bind(object))
	
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

func _remove_object_from_level(object : Node2D):
	remove_from_selection(object)
	level.remove_child(object)
