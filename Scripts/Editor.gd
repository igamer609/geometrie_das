# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name Editor
extends Node2D

signal load_level_data(level_data : LevelData)
signal finished_loading_level

signal playtesting_gamemode_changed(ground_pos: Vector2, gap : int)
signal playtesting_started(player : Player)
signal playtesting_paused()
signal playtesting_resumed()
signal playtesting_stopped(on_death : bool, last_location : Vector2)

const player_scene : PackedScene = preload("res://Scenes/Player.tscn")

@export var input_controller : EditorInputController
@export var obj_system : EditorObjectSystem
@export var cam_controller : EditorCameraController
@export var ui_system : EditorUISystem

@export_category("Solid Objects")
@export var ground_col : StaticBody2D
@export var ceiling_col : StaticBody2D

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

var playtest_player : Player = null

func _ready() -> void:
	obj_system.loaded_objects.connect(_finished_loading)
	input_controller.swipe_key_pressed.connect(_swipe_action_pressed)
	input_controller.swipe_key_released.connect(_swipe_action_released)
	
	ui_system.swipe_toggled.connect(_toggle_swipe_button_state)
	
	ui_system.start_playtest_pressed.connect(_start_playtest)
	ui_system.pause_playtest_pressed.connect(_pause_playtest)
	ui_system.resume_playtest_pressed.connect(_resume_playtest)
	ui_system.stop_playtest_pressed.connect(_stop_playtest)
	
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
	
	playtest_player = player_scene.instantiate()
	playtest_player.global_position = Vector2(0, -8)
	playtest_player.died.connect(_stop_playtest.bind(true))
	playtest_player.changed_gamemode.connect(_playtest_changed_gamemode)
	add_child(playtest_player)
	
	playtesting_started.emit(playtest_player)

func _stop_playtest(on_death : bool) -> void:
	playtesting_stopped.emit(on_death, playtest_player.global_position)
	ceiling_col.hide(); ground_col.hide()
	
	if(playtest_player):
		playtest_player.queue_free()

func _pause_playtest() -> void:
	if(playtest_player):
		playtest_player.pause_movement()
	playtesting_paused.emit()

func _resume_playtest() -> void:
	if(playtest_player):
		playtest_player.resume_movement()
	playtesting_resumed.emit()

func _playtest_changed_gamemode(portal : Area2D, gamemode : int) -> void:
	match gamemode:
		0: _update_ground()
		1: _update_ground(portal.global_position, 10)
		2: _update_ground(portal.global_position, 8)

func _update_ground(portal_pos : Vector2 = Vector2.ZERO, gap: int = 0) -> void:
	var snapped_pos : Vector2 = Vector2(portal_pos.x, snapped(portal_pos.y, 16))
	
	if(gap == 0):
		ground_col.global_position = Vector2(snapped_pos.x, 0)
		playtesting_gamemode_changed.emit()
		ceiling_col.hide(); ground_col.hide()
		if(ceiling_col.get_parent()):
			ceiling_col.collision_layer = 0
		return
	
	if(ceiling_col.get_parent() == null):
		add_child(ceiling_col)
	
	var ground_pos : Vector2 = Vector2(snapped_pos.x, int(snapped_pos.y + gap*16/2.0))
	if(ground_pos.y > 0):
		ground_pos.y = 0
	playtesting_gamemode_changed.emit(ground_pos, gap*16)
	
	var ceiling_pos : Vector2 = Vector2(snapped_pos.x, ground_pos.y - gap*16)
	ceiling_col.collision_layer = 2
	
	ground_col.global_position = ground_pos
	ceiling_col.global_position = ceiling_pos
	ceiling_col.show(); ground_col.show()
