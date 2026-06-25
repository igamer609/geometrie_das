class_name EditorUISystem
extends Node

signal id_selected(new_id : int, button : Button)
signal swipe_toggled(state : bool)
signal start_song_preview
signal stop_song_preview
signal start_playtest_pressed
signal pause_playtest_pressed
signal resume_playtest_pressed
signal stop_playtest_pressed

@export var editor : Editor
@export var obj_system : Node
@export var cam_controller : EditorCameraController
@export var save_load : Node

@export var ui : CanvasLayer
@export var editor_menu : ColorRect
@export var editor_menu_container : Control

@export var top_bar : Control
@export var action_grid : GridContainer

@export var item_tab : TabContainer
@export var edit_tab : Control
@export var editor_tabs : Control
@export var move_container : Control
@export var other_edit_buttons : GridContainer
@export var quick_options : GridContainer

@export var editor_layer_spinbox : GDNumberSpin

@export_category("Toggle Buttons")
@export var song_preview_button : TextureButton
@export var playtest_toggle : TextureButton
@export var playtest_pause_button : TextureButton 

var menu_state : bool = false

func _ready() -> void:
	
	editor.playtesting_started.connect(_start_playtesting)
	editor.playtesting_started.connect(_stopped_playtesting)
	obj_system.updated_selection.connect(_update_selection_action_buttons)
	obj_system.updated_clipboard.connect(_update_clipboard_action_buttons)
	
	_initialise_actions()
	_initialise_edit_btn()
	_initialise_items()
	_initialise_tabs()
	_initialise_top_bar()
	_initialise_menu_buttons()

func _initialise_items() -> void:
	var btn_group = ButtonGroup.new()
	
	for button in item_tab.find_children("*", "Button"):
		button.button_group = btn_group
		button.select_item.connect(select_item_id.bind(button))

func _initialise_actions() -> void:
	for button in action_grid.get_children():
		match button.name:
			"Copy": button.pressed.connect(obj_system.copy_objects);
			"Paste": button.pressed.connect(obj_system.paste_objects);
			"Duplicate": button.pressed.connect(obj_system.duplicate_objects);
			"Deselect": button.pressed.connect(obj_system.deselect);
			"EditObj": button.pressed.connect(_create_object_edit_menu)
	
	editor_layer_spinbox.value_changed.connect(editor._set_editor_layer)

func _initialise_top_bar() -> void:
	for button in top_bar.get_children():
		match button.name:
			"Delete": button.pressed.connect(obj_system.delete_objects)
			"Menu": button.pressed.connect(_change_menu_state)
			"LevelSettings": button.pressed.connect(_open_level_settings)
			"Undo": button.pressed.connect(obj_system.history.undo)
			"Redo": button.pressed.connect(obj_system.history.redo)
			"ZoomIn": button.pressed.connect(cam_controller._zoom.bind(0.3))
			"ZoomOut": button.pressed.connect(cam_controller._zoom.bind(-0.3))
			"PlaySong": button.pressed.connect(_toggle_song_preview)

func select_item_id(new_id : int, button : Button) -> void:
	id_selected.emit(new_id, button)

func _initialise_tabs():
	var tab_group = ButtonGroup.new()
	for tab in editor_tabs.get_children():
		tab.button_group = tab_group
		if tab.name == "Build":
			tab.pressed.connect(_change_editor_mode.bind(editor.EditorMode.BUILD))
		elif tab.name == "Edit":
			tab.pressed.connect(_change_editor_mode.bind(editor.EditorMode.EDIT))

func _initialise_edit_btn():
	for move_group : Control in move_container.get_children():
		for button : Button in move_group.get_children():
			if button.is_in_group("16_unit"):
				button.pressed.connect(obj_system.move_objects.bind(button.name, 1))
			elif button.is_in_group("8_unit"):
				button.pressed.connect(obj_system.move_objects.bind(button.name, 0.5))
			elif button.is_in_group("1_unit"):
				button.pressed.connect(obj_system.move_objects.bind(button.name, 0.1))
	for button : Button in other_edit_buttons.get_children():
		if button.is_in_group("rot_right"):
			button.pressed.connect(obj_system.rotate_objects.bind(1))
		elif button.is_in_group("rot_left"):
			button.pressed.connect(obj_system.rotate_objects.bind(-1))
	for button : Button in quick_options.get_children():
		button.toggled.connect(_forward_swipe_toggle)

func _initialise_menu_buttons() -> void:
	for button : Button in editor_menu_container.get_children():
		match button.name:
			"Resume": button.pressed.connect(_change_menu_state)
			"Save": button.pressed.connect(save_load._save_level)
			"SaveAndPlay": button.pressed.connect(save_load._save_and_play)
			"SaveAndExit":button.pressed.connect(save_load._save_and_exit)
			"Exit": button.pressed.connect(save_load._exit)

func _change_editor_mode(new_mode):
	if new_mode != editor.edit_mode:
		editor.edit_mode = new_mode
		if editor.edit_mode == editor.EditorMode.BUILD:
			item_tab.visible = true
			edit_tab.visible = false
		if editor.edit_mode == editor.EditorMode.EDIT:
			item_tab.visible = false
			edit_tab.visible = true

func _change_menu_state():
	menu_state = !menu_state
	editor_menu.visible = !editor_menu.visible

func _forward_swipe_toggle(state : bool) -> void:
	swipe_toggled.emit(state)

func _create_object_edit_menu() -> void:
	var all_regular : bool = true
	var all_triggers : bool = true
	var trigger_types : Array[int] = []
	
	for object : GDObject in obj_system.selected_objects:
		if(object.trigger): 
			all_regular = false
			if(!trigger_types.has(object.trigger.trigger_id)):
				trigger_types.append(object.trigger.trigger_id)
		else: all_triggers = false
	
	if(all_regular):
		var obj_edit_menu = ResourceLibrary.scenes["GenericObjectEdit"].instantiate()
		obj_edit_menu.target_objects = obj_system.selected_objects
		ui.add_child(obj_edit_menu)
	elif(all_triggers):
		if(trigger_types.size() == 1 && trigger_types[0] == 1):
			var obj_edit_menu = ResourceLibrary.scenes["ColorTriggerEdit"].instantiate()
			obj_edit_menu.target_triggers = obj_system.selected_objects
			ui.add_child(obj_edit_menu)

func _open_level_settings() -> void:
	var settings_menu = ResourceLibrary.scenes["LevelSettings"].instantiate()
	settings_menu.level = editor.level_meta
	ui.add_child(settings_menu)

func _update_selection_action_buttons(selection : Array[GDObject]):
	
	var check : bool = true
	if(len(selection) > 0): check = false
	
	for button : Button in action_grid.get_children():
		match(button.name):
			"Copy": button.disabled = check
			"Duplicate": button.disabled = check
			"EditObj": button.disabled = check
			"Deselect": button.disabled = check

func _update_clipboard_action_buttons(clipboard : Array):
	
	var check : bool = true
	if(len(clipboard) > 0): check = false
	
	for button : Button in action_grid.get_children():
		match(button.name):
			"Paste": button.disabled = check

func _toggle_song_preview() -> void:
	
	var button_icon : TextureRect = song_preview_button.get_child(0)
	
	if(song_preview_button.button_pressed):
		button_icon.texture.region = Rect2(70.0, 39.0, 21.0, 21.0)
		button_icon.texture.margin = Rect2(0, 0, 0, 0)
		song_preview_button.texture_normal.region = Rect2(96, 0, 32, 32)
		song_preview_button.set_pressed_no_signal(false)
		stop_song_preview.emit()
		return
	
	button_icon.texture.region = Rect2(116.0, 49.0, 11.0, 11.0)
	button_icon.texture.margin = Rect2(3, 3, 6, 6)
	song_preview_button.texture_normal.region = Rect2(0, 0, 32, 32)
	start_song_preview.emit()

func _toggle_playtest(pressed : bool) -> void:
	if(pressed):
		_start_playtesting(null)
	else:
		_stopped_playtesting()

func _update_playtest_buttons(is_paused : bool) -> void:
	
	var pause_button_icon : TextureRect = playtest_pause_button.get_child(0)
	
	if(is_paused):
		pause_button_icon.texture.rect = Rect2(70, 39, 21, 21)
	else:
		pause_button_icon.texture.rect = Rect2(115, 32, 15, 16)

func _start_playtesting(_player : Player) -> void:
	if(song_preview_button.button_pressed):
		_toggle_song_preview()
	
	playtest_pause_button.show()
	

func _stopped_playtesting() -> void:
	playtest_pause_button.hide()
