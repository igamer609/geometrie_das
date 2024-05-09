extends CanvasLayer

var track_progress = true

@onready var music_ids = {
	1 : [preload("res://Assets/music/Levels/Glorious Morning.mp3"), "Glorious Morning"],
	2 : [preload("res://Assets/music/Levels/yStep.mp3"), "yStep"]
}

@export var current_level = 0
@export var current_level_progress = 0
@export var current_level_practice = 0

@export var music_to_load : int

@export var in_game = false
@export var level_mode = "normal"

@export var run_music = true
@export var music_offset = 0

var progress_to_update = false

func _ready():
	update_bar(0)

func check_progress(new_progress):
	if level_mode == "normal":
		if new_progress > current_level_progress:
			current_level_progress = new_progress
			progress_to_update = true
	if level_mode == "practice":
		if new_progress > current_level_practice:
			current_level_practice = new_progress
			progress_to_update = true

func enter_level(level):
	current_level = level

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
