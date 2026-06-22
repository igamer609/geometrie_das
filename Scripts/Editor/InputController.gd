extends Node

@export var editor : Node2D

var swiping : bool = false
var swipe_start : Vector2

signal place_pressed
signal place_swiped
signal select_single(pos : Vector2)
signal swipe_started(pos : Vector2)
signal swipe_updated(new_pos : Vector2)
signal swipe_finished(start_pos : Vector2)
signal pan_camera(relative : Vector2)
signal swipe_key_pressed
signal swipe_key_released
signal zoom(sign : int)

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
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
		if not event.pressed && swiping && editor.edit_mode == editor.EditorMode.EDIT:
			swiping = false
			swipe_finished.emit(swipe_start)
	
	if event is InputEventMouseMotion:
		if event.button_mask in [MOUSE_BUTTON_MASK_MIDDLE, MOUSE_BUTTON_MASK_RIGHT]:
			pan_camera.emit(event.relative * 0.50)
		elif event.button_mask in [MOUSE_BUTTON_LEFT] and swiping and editor.edit_mode == editor.EditorMode.EDIT:
			swipe_updated.emit(editor.get_global_mouse_position())
		elif event.button_mask in [MOUSE_BUTTON_LEFT] and swiping and editor.edit_mode == editor.EditorMode.BUILD:
			place_swiped.emit()
	
	if event.is_action_pressed("Swipe"):
		swipe_key_pressed.emit()
	elif event.is_action_released("Swipe"):
		swipe_key_released.emit()
