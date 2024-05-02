extends CanvasLayer

@export var current_level = 0
@export var current_level_progress = 0
@export var current_level_practice = 0

@export var music_to_load : String

@export var in_game = false
@export var level_mode = "normal"

@export var run_music = true
@export var music_offset = 0

var progress_to_update = false

const menu_music = preload("res://Assets/music/menu.mp3")

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

func _process(_delta):
	if run_music and not $AudioStreamPlayer.playing and in_game and $Timer.time_left == 0:
		if music_to_load:
			var loaded_music = load(music_to_load)
			$AudioStreamPlayer.stream = loaded_music
			print("loaded")
			if music_offset > 0 and $Timer.time_left == 0:
				$Timer.start(music_offset)
				await $Timer.timeout
				$AudioStreamPlayer.play()
			elif music_to_load and music_offset == 0:
				$Timer.start(0.1)
	elif not in_game:
		$AudioStreamPlayer.stop()
	
	if not run_music and $AudioStreamPlayer.playing and in_game:
		$AudioStreamPlayer.stop()

