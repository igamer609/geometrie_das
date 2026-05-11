# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends CanvasLayer

@export var current_level_song = 0
@export var current_level_id = 0
var current_session_attempts = 0

var _current_level_progress : LevelProgress

@export var music_to_load : int

@export var in_game : bool = false
@export var level_mode : LevelProgress.Modes = LevelProgress.Modes.NORMAL

@export var run_music : bool = true
@export var music_offset : int = 0

var progress_to_update = false

func _ready() -> void:
	update_bar(0)

#func _process(_delta: float) -> void:
	#if music_to_load == 0 and $AudioStreamPlayer.playing:
		#stop_lvl_music()
		#run_music = false

func get_current_level_progress() -> LevelProgress:
	return _current_level_progress

func check_progress(new_progress : int) -> void:
	_current_level_progress.update_progress(new_progress, level_mode)

func add_attempt() -> void:
	_current_level_progress.add_attempt(level_mode)
	PlayerData.increment_total_attempts()
	current_session_attempts += 1

func quit_menu() -> void:
	current_level_id = 0
	current_level_song = 0
	_current_level_progress = null
	current_session_attempts = 0

func enter_level(level) -> void:
	current_level_id = level["id"]
	current_level_song = level["song_id"]
	current_session_attempts = 0
	_current_level_progress = PlayerData.get_level_progress(level["id"])

func update_bar(procent):
	if in_game:
		visible = true
		$Container/Bar.value = procent
	else:
		visible = false
		$Container/Bar.value = 0

func play_lvl_music_from_id(delay):
	if music_to_load:
		var audio_to_play = ResourceLibrary.song_ids[music_to_load][0]
		$AudioStreamPlayer.stream = audio_to_play
		
		if delay:
			var timer = Timer.new()
			add_child(timer)
			
			timer.start()
			
			await timer.timeout
			get_tree().queue_delete(timer)
		
		$AudioStreamPlayer.play()

func stop_lvl_music():
	$AudioStreamPlayer.stop()
