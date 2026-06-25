class_name EditorCameraController
extends Node

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
var playtest_player : Player = null
var playtest_trail : Line2D = null
var death_marker : Sprite2D = null
var playtest_death_location : Vector2

var swiping : bool = false
var swipe_start : Vector2
var swipe_rect : Rect2

var zoom_multiplier : float = 1.0

func _ready() -> void:
	editor.load_level_data.connect(_initiate_camera)
	editor.playtesting_started.connect(_init_playtest)
	
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
	camera.global_position -= relative
	update_grid_position()

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
	song_start_time = screen_left_pos / editor.BASE_SPEED + editor.level_meta.song_offset
	
	GameProgress.music_to_load = editor.level_meta.song_id
	GameProgress.play_lvl_music_from_id(0, song_start_time)

func _stop_song_preview() -> void:
	song_preview_playing = false
	GameProgress.stop_lvl_music()

func _remove_song_preview():
	if(song_preview_bar):
		song_preview_bar.queue_free()

func _init_playtest(player : Player) -> void:
	playtest_player = player
	
	if(song_preview_playing):
		_remove_song_preview()
	
	playtest_trail = Line2D.new()
	playtest_trail.default_color = Color(0, 1, 0)
	add_child(playtest_trail)
	
	draw_line = true

func _process(delta : float) -> void:
	if(song_preview_playing):
		update_song_preview_bar(delta)
	
	if(draw_line):
		var new_point : Vector2 = playtest_player.global_position
