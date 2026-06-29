# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name EditorInputController
extends Node

@export var editor : Editor

var catch_inputs : bool = true
var emit_place_signals : bool = true

var swiping : bool = false
var swipe_start : Vector2
var move_amount : float = 1.0

signal place_pressed
signal place_swiped
signal select_single(pos : Vector2)
signal swipe_started(pos : Vector2)
signal swipe_updated(new_pos : Vector2)
signal swipe_finished(start_pos : Vector2)
signal pan_camera(relative : Vector2)
signal zoom(amount : int)
signal swipe_key_pressed
signal swipe_key_released
signal move(direction : String, amount : float)
signal rotate(direction : int)

func _ready() -> void:
	editor.playtesting_started.connect(_playtesting_started)
	editor.playtesting_paused.connect(_playtesting_paused)
	editor.playtesting_resumed.connect(_playtesting_resumed)
	editor.playtesting_stopped.connect(_playtesting_stopped)

func _unhandled_input(event : InputEvent) -> void:
	if(!catch_inputs): return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if(event.pressed && emit_place_signals):
			if editor.edit_mode == editor.EditorMode.BUILD:
				if  editor.select_mode == editor.SelectionMode.SINGLE:
					place_pressed.emit()
				elif editor.select_mode == editor.SelectionMode.SWIPE:
					swiping = true
					place_swiped.emit()
			elif editor.edit_mode == editor.EditorMode.EDIT:
				if editor.select_mode == editor.SelectionMode.SINGLE:
					select_single.emit(editor.get_global_mouse_position())
				if editor.select_mode == editor.SelectionMode.SWIPE:
					swiping = true
					swipe_start = editor.get_global_mouse_position()
					swipe_started.emit(editor.get_global_mouse_position())
		if( not event.pressed && swiping && editor.edit_mode == editor.EditorMode.EDIT && emit_place_signals):
			swiping = false
			swipe_finished.emit(swipe_start)
	
	if event is InputEventMouseMotion:
		if event.button_mask in [MOUSE_BUTTON_MASK_MIDDLE, MOUSE_BUTTON_MASK_RIGHT]:
			pan_camera.emit(event.relative * 0.50)
		elif event.button_mask in [MOUSE_BUTTON_LEFT] and swiping and editor.edit_mode == editor.EditorMode.EDIT:
			swipe_updated.emit(editor.get_global_mouse_position())
		elif event.button_mask in [MOUSE_BUTTON_LEFT] and swiping and editor.edit_mode == editor.EditorMode.BUILD:
			place_swiped.emit()

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("ZoomIn"):
		zoom.emit(0.3)
	elif event.is_action_pressed("ZoomOut"):
		zoom.emit(-0.3)
	
	if(!catch_inputs || !emit_place_signals): return
	
	if event.is_action_pressed("Swipe"):
		move_amount = 0.1
		swipe_key_pressed.emit()
	elif event.is_action_released("Swipe"):
		move_amount = 1.0
		swipe_key_released.emit()
	
	if event.is_action_pressed("MoveUp"):
		move.emit("Up", move_amount)
	elif event.is_action_pressed("MoveDown"):
		move.emit("Down", move_amount)
	elif event.is_action_pressed("MoveLeft"):
		move.emit("Left", move_amount)
	elif event.is_action_pressed("MoveRight"):
		move.emit("Right", move_amount)
	
	if event.is_action_pressed("RotateLeft"):
		rotate.emit(-1)
	elif event.is_action_pressed("RotateRight"):
		rotate.emit(1)

func _playtesting_started(_player : Player = null) -> void:
	catch_inputs = false
	emit_place_signals = false
 
func _playtesting_stopped(_on_death : bool = false, _last_location : Vector2 = Vector2.ZERO) -> void:
	catch_inputs = true
	emit_place_signals = true

func _playtesting_paused() -> void:
	catch_inputs = true

func _playtesting_resumed() -> void:
	catch_inputs = false
