# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name Editor
extends Node2D

signal load_level_data(level_data : LevelData)
signal finished_loading_level

signal playtesting_started(player : Player)
signal playtesting_paused()
signal playtesting_resumed()
signal playtesting_stopped()

@export var input_controller : Node
@export var obj_system : Node
@export var cam_controller : Node
@export var ui_system : Node

enum EditorMode {BUILD, EDIT}
enum SelectionMode {SINGLE, SWIPE}
const BASE_SPEED : float = 127.35

var level_meta : LevelMeta = LevelMeta.new()
var level_path : String

var current_editor_layer : int
var edit_mode : EditorMode = EditorMode.BUILD
var select_mode : SelectionMode = SelectionMode.SINGLE
var swipe_button_state : bool = false
var swipe_action_state : bool = false

var is_playtesting : bool = false
var playtest_player : Player = null
var trail : Line2D = null

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

func initialize_level_data(level_data : LevelData, _level_path : String) -> void:
	level_path = _level_path
	load_level_data.emit(level_data)

func _finished_loading() -> void:
	finished_loading_level.emit()

func _update_palette(channel_id : int, color : Color) -> void:
	level_meta.color_palette.set_channel(channel_id, color)

func _start_playtest() -> void:
	if(playtest_player):
		playtest_player.queue_free()
	
	playtest_player = Player.new()
	playtest_player.global_position = Vector2(0, 8)
	add_child(playtest_player)
	
	playtesting_started.emit(playtest_player)

func _stop_playtest() -> void:
	if(playtest_player):
		playtest_player.queue_free()
	
	playtesting_stopped.emit()

func _pause_playtest() -> void:
	if(playtest_player):
		playtest_player.can_move = false
	playtesting_paused.emit()

func _resume_playtest() -> void:
	playtesting_resumed.emit()
