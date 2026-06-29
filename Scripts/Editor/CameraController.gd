# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name EditorCameraController
extends Node

@export_category("Config Values")
@export var CAMERA_MOVE_OFFSET : float = 1.5

@export_category("Used Editor Systems")
@export var editor : Editor
@export var input_controller : EditorInputController
@export var ui_system : EditorUISystem

@export_category("Controlled Objects")
@export var camera : Camera2D
@export var grid : Sprite2D

var song_preview_bar : Line2D = null
var song_preview_playing : bool = false
var song_start_time : float = 0

var draw_line : bool = false
var follow_playtest_player : bool = false
var last_snapped_portal_pos : Vector2 = Vector2.ZERO


var playtest_player : Player = null
var playtest_trail : Line2D = null
var playtest_trail_size : int = 0
@export var death_marker : Sprite2D
var playtest_death_location : Vector2

var swiping : bool = false
var swipe_start : Vector2
var swipe_rect : Rect2

var zoom_multiplier : float = 1.0

func _ready() -> void:
	editor.load_level_data.connect(_initiate_camera)
	
	editor.playtesting_gamemode_changed.connect(_on_gamemode_changed)
	
	editor.playtesting_started.connect(_init_playtest)
	editor.playtesting_paused.connect(_on_playtest_paused)
	editor.playtesting_resumed.connect(_on_playtest_resumed)
	editor.playtesting_stopped.connect(_stop_playtest)
	
	
	input_controller.swipe_started.connect(_start_swipe_rect)
	input_controller.swipe_updated.connect(_update_swipe_rect)
	input_controller.swipe_finished.connect(_end_swipe)
	input_controller.pan_camera.connect(_pan)
	input_controller.zoom.connect(_zoom)
	
	ui_system.start_song_preview.connect(_play_song_preview)
	ui_system.stop_song_preview.connect(_stop_song_preview)

func _initiate_camera(level_data : LevelData):
	camera.global_position = level_data.meta.last_cam_pos
	update_grid_position()

func _start_swipe_rect(init_pos : Vector2) -> void:
	swiping = true
	swipe_start = init_pos
	swipe_rect = Rect2(swipe_start.x, swipe_start.y, 0, 0)
	editor.queue_redraw()

func _update_swipe_rect(new_pos : Vector2) -> void:
	swipe_rect = Rect2(swipe_start, new_pos - swipe_start)
	editor.queue_redraw()

func _end_swipe(_start_pos : Vector2) -> void:
	swiping = false
	editor.queue_redraw()

func _zoom(amount : float) -> void:
	
	if(amount == 0):
		zoom_multiplier = 1
	
	zoom_multiplier += amount
	zoom_multiplier = clamp(zoom_multiplier, 0.3, 2.1)
	#TransitionScene.show_message("x" + str(zoom_multiplier))
	camera.zoom = Vector2(3 * zoom_multiplier, 3 * zoom_multiplier)
	call_deferred("update_grid_position")

func _pan(relative : Vector2) -> void:
	camera.global_position -= relative * 3 / camera.zoom
	update_grid_position()

func _start_level_song_from_pos(start_position : float) -> void:
	song_start_time = start_position / editor.BASE_SPEED + editor.level_meta.song_offset
	
	GameProgress.music_to_load = editor.level_meta.song_id
	GameProgress.play_lvl_music_from_id(0, song_start_time)

func update_grid_position() -> void:
	var camera_pos : Vector2 = camera.global_position
	var target_grid_position : Vector2 = Vector2(snapped(camera_pos.x  - (grid.region_rect.size.x / 4), 16), snapped(camera_pos.y + (grid.region_rect.size.y / 4), 16))
	editor.level_meta.last_cam_pos = camera_pos
	var camera_rect : Vector2 = editor.get_viewport_rect().size * 3  / camera.zoom
	grid.region_rect.size = camera_rect
	
	if target_grid_position.x < 0:
		target_grid_position.x = 0
	
	grid.global_position = target_grid_position

func update_song_preview_bar(delta : float) -> void:
	if(song_preview_bar):
		song_preview_bar.global_position.x += editor.BASE_SPEED * delta
		
		var camera_rect : Vector2 = editor.get_viewport_rect().size / camera.zoom
		var screen_right_pos : float = camera.global_position.x + (camera_rect.x / 2)
		
		if(song_preview_bar.global_position.x >=  screen_right_pos):
			camera.global_position.x += 1280.0 / (3 * zoom_multiplier)
			update_grid_position()

func update_player_trail() -> void:
	
	if(!playtest_player): return
	
	var new_point : Vector2 = playtest_player.global_position
	if(playtest_trail_size > 0):
		var prev_point : Vector2 = playtest_trail.get_point_position(playtest_trail_size - 1)
		var distance : Vector2 = Vector2(new_point.x - prev_point.x, abs(new_point.y - prev_point.y))
		if((distance.x >= 8) || (distance.y >= 56)):
			if((distance.y > 0.1 && distance.y < 0.75) && (playtest_trail_size > 2)):
				playtest_trail.remove_point(playtest_trail_size - 1)
				playtest_trail_size -= 1
			
			playtest_trail.add_point(new_point)
			playtest_trail_size += 1

func _play_song_preview() -> void:
	if(song_preview_bar && !song_preview_playing):
		song_preview_bar.queue_free()
	
	song_preview_playing = true

	song_preview_bar = Line2D.new()
	song_preview_bar.default_color = Color(0, 1, 0)
	song_preview_bar.width = 1
	song_preview_bar.add_point(Vector2(0, 10000))
	song_preview_bar.add_point(Vector2(0, -10000))
	add_child(song_preview_bar)
	
	var camera_rect : Vector2 = editor.get_viewport_rect().size / camera.zoom
	var screen_left_pos : float = camera.global_position.x - (camera_rect.x / 2)
	
	if(screen_left_pos < 0):
		screen_left_pos = 0
	
	song_preview_bar.global_position.x = screen_left_pos
	
	_start_level_song_from_pos(screen_left_pos)

func _stop_song_preview() -> void:
	song_preview_playing = false
	GameProgress.stop_lvl_music()

func _remove_song_preview():
	if(song_preview_bar):
		song_preview_bar.queue_free()

func update_playtest_camera() -> void:
	camera.global_position.x = playtest_player.global_position.x
	
	match playtest_player.gamemode:
		Player.GamemodeTypes.CUBE:
			var offset : float = playtest_player.global_position.y - camera.global_position.y
			if(abs(offset) > CAMERA_MOVE_OFFSET * 16):
				camera.global_position.y = lerp(camera.global_position.y, playtest_player.global_position.y, 0.1)
		_:
			camera.global_position.y = last_snapped_portal_pos.y
	
	update_grid_position()

func _on_gamemode_changed(ground_pos : Vector2 = Vector2.ZERO, gap : int = 0) -> void:
	var current_half_gap : int = int(gap/2.0)
	last_snapped_portal_pos = Vector2(ground_pos.x, snapped(ground_pos.y, 16) - current_half_gap)

func _init_playtest(player : Player) -> void:
	playtest_player = player
	death_marker.hide()
	
	_remove_song_preview()
	
	if(playtest_trail):
		playtest_trail.queue_free()
	
	playtest_trail = Line2D.new()
	playtest_trail.default_color = Color(0, 1, 0)
	playtest_trail.width = 1
	playtest_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	playtest_trail.add_point(Vector2(0, -8))
	playtest_trail_size = 1
	add_child(playtest_trail)
	
	_start_level_song_from_pos(0)
	draw_line = true
	follow_playtest_player = true

func _on_playtest_paused() -> void:
	draw_line = false
	camera.position_smoothing_enabled = false
	playtest_trail.add_point(playtest_player.global_position)
	playtest_trail_size += 1
	GameProgress.stop_lvl_music()

func _on_playtest_resumed() -> void:
	draw_line = true
	if(playtest_player):
		_start_level_song_from_pos(playtest_player.global_position.x)

func _stop_playtest(on_death : bool, last_position : Vector2) -> void:
	
	if(on_death):
		playtest_trail.add_point(last_position)
		playtest_trail_size += 1
		
		death_marker.global_position = last_position
		death_marker.show()
	
	draw_line = false
	follow_playtest_player = false
	camera.position_smoothing_enabled = false
	GameProgress.stop_lvl_music()

func _process(delta : float) -> void:
	if(song_preview_playing):
		update_song_preview_bar(delta)
	
	if(draw_line):
		update_player_trail()
	
	if(follow_playtest_player):
		update_playtest_camera()
