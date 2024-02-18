extends CanvasLayer

@export var current_level = 0
@export var current_level_progress = 0
@export var current_level_practice = 0

@export var in_game = false
@export var level_mode = "normal"

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
