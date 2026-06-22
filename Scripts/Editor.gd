# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

#might need some refactoring and division into smaller components

extends Node2D

signal load_level_data(level_data : LevelData)
signal finished_loading_level

@export var input_controller : Node
@export var obj_system : Node
@export var cam_controller : Node
@export var ui_system : Node

enum EditorMode {BUILD, EDIT}
enum SelectionMode {SINGLE, SWIPE}
const BASE_SPEED : float = 127.35

var level_meta : LevelMeta = LevelMeta.new()
var _level_path : String

var current_editor_layer : int
var edit_mode : EditorMode = EditorMode.BUILD
var select_mode : SelectionMode = SelectionMode.SINGLE
var swipe_button_state : bool = false
var swipe_action_state : bool = false

var is_playtesting : bool = false
var playtest_player : Player = null
var trail : Line2D = null
var death_marker : Sprite2D = null
var playtest_death_location : Vector2

func _ready() -> void:
	obj_system.loaded_objects.connect(_finished_loading)
	input_controller.swipe_key_pressed.connect(_swipe_action_pressed)
	input_controller.swipe_key_released.connect(_swipe_action_released)
	ui_system.swipe_toggled.connect(_toggle_swipe_button_state)
	ColorManager.channel_changed.connect(_update_palette)

func _draw() -> void:
	if cam_controller.swiping && edit_mode == EditorMode.EDIT:
		draw_rect(cam_controller.swipe_rect, Color(0, 1, 0, 1), false)

func _toggle_swipe_button_state(state : bool) -> void:
	swipe_button_state = state
	if(swipe_button_state):
		select_mode = SelectionMode.SWIPE
	elif(!swipe_action_state && !swipe_action_state):
		select_mode = SelectionMode.SINGLE

func _swipe_action_pressed() -> void:
	swipe_action_state = true
	select_mode = SelectionMode.SWIPE

func _swipe_action_released() -> void:
	swipe_action_state = false
	if(!swipe_button_state):
		select_mode = SelectionMode.SINGLE

func _is_on_editor_layer(object : GDObject) -> bool:
	return object.editor_layer == current_editor_layer or current_editor_layer < 0

func _set_editor_layer(new_layer : int) -> void:
	current_editor_layer = new_layer
	RenderingServer.global_shader_parameter_set("current_editor_layer", new_layer)

func initialize_level_data(level_data : LevelData, level_path : String) -> void:
	_level_path = level_path
	load_level_data.emit(level_data)

func _finished_loading() -> void:
	finished_loading_level.emit()



#func _process(delta):
	#
	#if Input.is_action_just_pressed("RotateLeft"):
		#rotate_objects(-1)
	#if Input.is_action_just_pressed("RotateRight"):
		#rotate_objects(1)
	#
	#if Input.is_action_just_pressed("MoveUp"):
		#move_objects("Up", 1)
	#if Input.is_action_just_pressed("MoveDown"):
		#move_objects("Down", 1)
	#if Input.is_action_just_pressed("MoveLeft"):
		#move_objects("Left", 1)
	#if Input.is_action_just_pressed("MoveRight") and not Input.is_action_just_pressed("Duplicate"):
		#move_objects("Right", 1)
	#
	#if Input.is_action_just_pressed("Undo"):
		#history.undo()
	#if Input.is_action_just_pressed("Redo"):
		#history.redo()
	#
	#if  not swipe_toggle.button_pressed:
		#select_mode = SelectionMode.SINGLE
	#
	#if Input.is_action_pressed("Swipe") or swipe_toggle.button_pressed:
		#select_mode = SelectionMode.SWIPE
	#
	#if Input.is_action_just_pressed("Duplicate"):
		#duplicate_objects()
	#
	#if Input.is_action_just_pressed("Copy"):
		#copy_objects()
	#
	#if Input.is_action_just_pressed("Paste"):
		#paste_objects()
	#
	#if Input.is_action_just_pressed("Delete"):
		#delete_objects()
	#
	#if(song_preview_playing):
		#update_song_preview_bar(delta)
	#check_actions()

# --------- Update editor elements on input or process ----------

##Updates position of the grid in relation to the center and rect size of the camera


# --------- Operation Methods (for undo-redo system) -----------



func _update_palette(channel_id : int, color : Color) -> void:
	level_meta.color_palette.set_channel(channel_id, color)

# ---------------- Open sub-menus -------------------------
