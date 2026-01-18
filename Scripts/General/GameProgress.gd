extends CanvasLayer

@onready var music_ids : Dictionary = {
	1 : [preload("res://Assets/music/Levels/Glorious Morning.mp3"), "Glorious Morning"],
	2 : [preload("res://Assets/music/Levels/yStep.mp3"), "yStep"]
}

@export var current_level_song = 0
@export var current_level_id = 0
var current_session_attempts = 0

var _current_level_normal = 0
var _current_level_practice = 0
var _current_level_attempts = 0

@export var music_to_load : int

@export var in_game = false
@export var level_mode = "normal"

@export var run_music = true
@export var music_offset = 0

var progress_to_update = false

func _ready():
	update_bar(0)

func _process(delta: float) -> void:
	if music_to_load == 0 and $AudioStreamPlayer.playing:
		stop_lvl_music()
		run_music = false

func add_attempt() -> void:
	_current_level_attempts += 1
	current_session_attempts += 1

func get_current_level_progress() -> Array:
	return [_current_level_normal, _current_level_practice]

func check_progress(new_progress : int) -> void:
	if level_mode == "normal":
		if new_progress > _current_level_normal:
			_current_level_normal = new_progress
			
			var progress : Dictionary = {
				"id" : current_level_id,
				"normal" : new_progress,
				"practice" : _current_level_practice,
				"attempts" : _current_level_attempts,
				"main" : true
			}
			
			PlayerData.change_progress(progress)
			
	if level_mode == "practice":
		if new_progress > _current_level_practice:
			_current_level_practice = new_progress
			
			var progress : Dictionary = {
				"id" : current_level_id,
				"normal" : _current_level_normal,
				"practice" : new_progress,
				"attempts" : _current_level_attempts,
				"main" : true
			}
			
			PlayerData.change_main_level_progress(progress)

func quit_menu():
	current_level_id = 0
	current_level_song = 0
	current_session_attempts = 0

func enter_level(level):
	current_level_id = level["id"]
	current_level_song = level["song_id"]
	current_session_attempts = 0
	
	var level_progress : Dictionary = PlayerData.get_level_progress(level["id"])
	_current_level_normal = level_progress["n"]
	_current_level_practice = level_progress["p"]
	_current_level_attempts = level_progress["a"]

func update_bar(procent):
	if in_game:
		visible = true
		$Bar.value = procent
	else:
		visible = false
		$Bar.value = 0

func play_lvl_music_from_id(delay):
	if music_to_load:
		var audio_to_play = music_ids[music_to_load][0]
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
