extends Node2D

@export var current_id = 0
@export var selected_objects = []
@export var clipboard = []
@export var swipe_obj_pos = []

@onready var obj_base = preload("res://Objects/object.tscn")

@onready var camera = $Camera
@onready var level = $Level
@onready var ui = $Editor_Object/UI_Layer

@onready var editor_tabs = $Editor_Object/UI_Layer/Actions/Viewport/Tabs
@onready var top_bar = $Editor_Object/UI_Layer/TopBar

@onready var item_tab = $Editor_Object/UI_Layer/Actions/Viewport/Items
@onready var edit_tab = $Editor_Object/UI_Layer/Actions/Viewport/Edit

@onready var action_grid = $Editor_Object/UI_Layer/Actions/ObjectActions/ActionGrid
@onready var action_buttons = [$Editor_Object/UI_Layer/Actions/ObjectActions/ActionGrid/Copy, $Editor_Object/UI_Layer/Actions/ObjectActions/ActionGrid/Paste, $Editor_Object/UI_Layer/Actions/ObjectActions/ActionGrid/Duplicate, $Editor_Object/UI_Layer/Actions/ObjectActions/ActionGrid/Deselect, $Editor_Object/UI_Layer/TopBar/Delete]

var edit_mode = "Build"
var select_mode = "swipe"
var swipe = false
var menu_state = "closed"

var level_data = {"name" : "", "author" : "", "difficulty" : 0, "version" : 1.1, "song_id" : 0}

var selection_center = null

const TEMPLATE_OBJ_DICT = {
	"id" : 1,
	"transform" : [],
	"other" : {}
}

# Called when the node enters the scene tree for the first time.
func _ready():
	initialise_tabs()
	
	initialise_items()
	initialise_edit_btn()
	initialise_actions()
	
	initialise_top_bar()

func save_level():
	var save_data = {
		"info" : level_data,
		"objects" : []
	}

	for obj in level.get_children():
		if obj.is_class("StaticBody2D"):
			var obj_info = TEMPLATE_OBJ_DICT.duplicate()

			obj_info.id = obj.obj_res.id
			obj_info["transform"] = [var_to_str(obj.global_position), obj.global_rotation]

			if obj.obj_res.is_trigger:
				obj_info["other"]["trigger_info"] = obj.trigger.get_info()

			save_data["objects"].append(obj_info)
	
	print(save_data)
	
	if not DirAccess.dir_exists_absolute("user://saved_levels/"):
		DirAccess.make_dir_absolute("user://saved_levels/")
	
	var save_file = FileAccess.open("user://saved_levels/" + save_data["info"]["name"] + ".gdaslvl", FileAccess.WRITE)
	var save_string = JSON.stringify(save_data)
	
	save_file.store_line(save_string)
	
	return true

func load_obj(id, pos, rot, other):
	var item = load("res://Objects/obj_ids/" + str(int(id)) + ".tres")
	
	var object = obj_base.instantiate()
	object.obj_res = item
	
	object.global_position = pos
	object.global_rotation = rot
	
	object.selected.connect(select_object.bind(false))
	level.add_child(object)

func load_level_file():
	print("hello")
	
	var file_dialogue = FileDialog.new()
	file_dialogue.access = FileDialog.ACCESS_FILESYSTEM
	file_dialogue.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialogue.show_hidden_files = true
	file_dialogue.title = "Select level file "
	file_dialogue.add_filter("*.gdaslvl", "Geometrie Das Levels")
	
	ui.add_child(file_dialogue)
	file_dialogue.popup_centered(Vector2i(700, 500))
	
	await file_dialogue.file_selected
	
	
	
	var file_path = file_dialogue.current_path
	get_tree().queue_delete(file_dialogue)
	
	var lvl_file = FileAccess.open(file_path, FileAccess.READ)
	var lvl_info = JSON.parse_string(lvl_file.get_line())
	
	if lvl_info.has("objects") and lvl_info.has("name") and lvl_info.has("author"):
		load_level(lvl_info["objects"])
		level_data = lvl_info
	else:
		$Editor_Object/Menu_Layer/AcceptDialog.visible = true

func load_level(objects):
	select_all()
	delete_objects()
	
	for obj in objects:
		load_obj(obj["id"], str_to_var(obj["transform"][0]), obj["transform"][1], obj["other"])

func load_level_from_info(lvl_info):
	level_data = lvl_info["info"]
	
	if lvl_info.has("objects"):
		load_level(lvl_info["objects"])
	
	save_level()
	return true

func initialise_top_bar():
	for button in top_bar.get_children():
		if button.name == "Delete":
			button.pressed.connect(delete_objects)
		if button.name == "Menu":
			button.pressed.connect(change_menu_state)
			print("open")

func initialise_tabs():
	var tab_group = ButtonGroup.new()
	
	for tab in editor_tabs.get_children():
		tab.button_group = tab_group
		
		if tab.name == "Build":
			tab.pressed.connect(change_editor_mode.bind("Build"))
		elif tab.name == "Edit":
			tab.pressed.connect(change_editor_mode.bind("Edit"))

func initialise_items():
	var btn_group = ButtonGroup.new()
	
	for container in item_tab.get_children():
		for button in container.get_children():
			button.button_group = btn_group
			button.select_item.connect(select_item_id)

func initialise_edit_btn():
	for button in edit_tab.get_children():
		if button.is_in_group("one_block"):
			button.pressed.connect(move_objects.bind(button.name, 1))
	
	$Editor_Object/Menu_Layer/EditorMenu/VBoxContainer/Load.pressed.connect(load_level_file)
	$Editor_Object/Menu_Layer/EditorMenu/VBoxContainer/Save.pressed.connect(save_level)
	$Editor_Object/Menu_Layer/EditorMenu/VBoxContainer/Resume.pressed.connect(change_menu_state)
	$Editor_Object/Menu_Layer/EditorMenu/VBoxContainer/SaveAndExit.pressed.connect(save_and_exit)
	$Editor_Object/Menu_Layer/EditorMenu/VBoxContainer/Exit.pressed.connect(exit)

func change_menu_state():
	if menu_state == "closed":
		$Editor_Object/Menu_Layer/EditorMenu.visible = true
		menu_state = "opened"
	elif menu_state == "opened":
		$Editor_Object/Menu_Layer/EditorMenu.visible = false
		menu_state = "closed"

func save_and_exit():
	save_level()
	
	MenuMusic.start_music()
	TransitionScene.change_scene("res://Scenes/Menus/EditorTab.tscn")

func exit():
	var dialog = $Editor_Object/Menu_Layer/EditorMenu/ExitDialog
	dialog.visible = true
	
	await dialog.confirmed
	
	MenuMusic.start_music()
	TransitionScene.change_scene("res://Scenes/Menus/EditorTab.tscn")
	

func change_editor_mode(new_mode):
	print(new_mode)
	
	if new_mode != edit_mode:
		edit_mode = new_mode
		
		if edit_mode == "Build":
			item_tab.visible = true
			edit_tab.visible = false
		if edit_mode == "Edit":
			item_tab.visible = false
			edit_tab.visible = true

func initialise_actions():
	for button in action_grid.get_children():
		if button.name == "Copy":
			button.pressed.connect(copy_objects)
		elif button.name == "Paste":
			button.pressed.connect(paste_objects)
		elif button.name == "Duplicate":
			button.pressed.connect(duplicate_objects)
		elif button.name == "Deselect":
			button.pressed.connect(deselect)

func _unhandled_input(event):
	if Input.is_action_just_pressed("Jump"):
		if current_id != 0 and edit_mode == "Build":
			place_object()
		if edit_mode == "Edit" and not Input.is_action_just_pressed("Jump"):
			deselect()
	
	if event is InputEventMouseMotion:
		if event.button_mask in [MOUSE_BUTTON_MASK_MIDDLE, MOUSE_BUTTON_MASK_RIGHT]:
			camera.global_position -= event.relative * 0.25

func select_item_id(new_id):
	if new_id and new_id != current_id:
		current_id = new_id
		print("selected item " + str(current_id))

func place_object(return_obj = false):
	var item = load("res://Objects/obj_ids/" + str(current_id) + ".tres")
	
	var object = obj_base.instantiate()
	object.obj_res = item
	object.selected.connect(select_object.bind(false))
	
	object.global_position = get_global_mouse_position()
	
	object.global_position.x = snapped(object.global_position.x, 16) - 8
	object.global_position.y = snapped(object.global_position.y, 16)
	
	level.add_child(object)
	
	select_object(object, true)
	
	if return_obj:
		return object

func select_object(object, just_built, pasted = false):
	if object not in selected_objects:
		if just_built:
			deselect()
		
		if edit_mode == "Edit" or just_built or pasted:
			selected_objects.append(object)
			object.modulate = Color(0, 255, 0)
		
		if not is_instance_valid(object):
			selected_objects.erase(object)
		
		update_selection_center()
	else:
		pass

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
		
		selection_center.global_position = Vector2(snapped(average_x, 8), snapped(average_y, 8))
		
		print(selection_center.global_position)
		level.add_child(selection_center)
	else:
		if selection_center:
			get_tree().queue_delete(selection_center)

func deselect():
	for obj in selected_objects:
		if is_instance_valid(obj):
			obj.modulate = Color(255, 255, 255)
		else:
			print("found previously freed object!")
			var unknown_objects = selected_objects
			selected_objects = []
			
			for unknown_state_obj in unknown_objects:
				if is_instance_valid(unknown_state_obj):
					select_object(unknown_state_obj, false)
	
	print("deselected " + str(len(selected_objects)))
	
	selected_objects = []
	
	if selection_center:
		get_tree().queue_delete(selection_center)

func delete_objects():
	var objects_to_delete = selected_objects
	deselect()
	
	for obj in objects_to_delete:
		obj.queue_free()
	

func move_objects(direction, amount : int):
	var moved_obj = selected_objects
	
	for object in moved_obj:
		if direction == "Up":
			object.global_position.y -= amount * 16
		elif direction == "Down":
			object.global_position.y += amount * 16
		elif direction == "Left":
			object.global_position.x -= amount * 16
		elif direction == "Right":
			object.global_position.x += amount * 16
		
		update_selection_center()
	

func rotate_objects(direction):
	
	if selection_center and len(selected_objects) >= 2:
		for object in selected_objects:
			object.reparent(selection_center)
			selection_center.rotate(deg_to_rad(direction * 90))
			
			var obj_position = object.global_position
			var obj_rotation = object.global_rotation
			
			object.reparent(level)
			
			object.global_position = obj_position
			object.global_rotation = obj_rotation
			
			selection_center.global_rotation = 0
	elif len(selected_objects) == 1:
		var rot_center = Node2D.new()
		rot_center.global_position = selected_objects[0].get_child(0).global_position
		level.add_child(rot_center)

		selected_objects[0].reparent(rot_center)
		rot_center.rotate(deg_to_rad(direction * 90))
		var new_pos = selected_objects[0].global_position
		var new_rot = selected_objects[0].global_rotation
		selected_objects[0].reparent(level)
		selected_objects[0].global_position = new_pos
		selected_objects[0].global_rotation = new_rot
		get_tree().queue_delete(rot_center)
		
		if selected_objects[0].obj_res.is_trigger:
			for child in selected_objects[0].get_children():
				if child.name == "embedded_scene":
					child.global_rotation = 0

func copy_objects():
	clipboard = []
	
	for object in selected_objects:
		var obj_pos = camera.to_local(object.global_position)
		var obj_rot = object.global_rotation
		
		clipboard.append([object, obj_pos, obj_rot])

func paste_objects():
	if len(clipboard) >= 1:
		deselect()
		
		var pasted_objects = []
		
		for object in clipboard:
			var item = load("res://Objects/obj_ids/" + str(object[0].obj_res.id) + ".tres")
		
			var new_object = obj_base.instantiate()
			new_object.obj_res = item
			new_object.selected.connect(select_object.bind(false))
			
			new_object.global_position = Vector2(snapped((camera.to_global(object[1])).x, 16) - 8, snapped((camera.to_global(object[1])).y, 16) )
			new_object.global_rotation = object[2]
			
			level.add_child(new_object)
			
			print(new_object.global_position)
			
			pasted_objects.append(new_object)
		
		for object in pasted_objects:
			select_object(object, false, true)

func duplicate_objects():
	var objects_to_duplicate = selected_objects
	deselect()
	
	for obj in objects_to_duplicate:
		print(str(obj.obj_res.id))
		
		var item = load("res://Objects/obj_ids/" + str(obj.obj_res.id) + ".tres")
	
		var object = obj_base.instantiate()
		object.obj_res = item
		object.selected.connect(select_object.bind(false))
		
		object.global_position = obj.global_position
		object.global_rotation = obj.global_rotation
		
		level.add_child(object)
		select_object(object, false, true)
	
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
	
	if Input.is_action_just_pressed("Duplicate"):
		duplicate_objects()
	
	if Input.is_action_just_pressed("Copy"):
		copy_objects()
	
	if Input.is_action_just_pressed("Paste"):
		paste_objects()
	
	check_actions()
