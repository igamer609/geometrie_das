class_name LevelProgress extends Resource

enum Modes { NORMAL, PRACTICE }

@export var normal_progress : int = 0
@export var practice_progress : int = 0
@export var normal_attempts : int = 0
@export var practice_attempts : int = 0
@export var clicks : int = 0

@export var main : bool = 0
@export var completed : bool = false

func update_progress(new_progress : int, mode : int) -> bool:
	
	new_progress = clampi(new_progress, 0, 100)
	
	match(mode):
		Modes.NORMAL: if(new_progress > normal_progress): 
			normal_progress = new_progress
			return true
		Modes.PRACTICE: if(new_progress > practice_progress): 
			practice_progress = new_progress
			return true
	
	return false

func add_attempt(mode : int) -> void:
	match(mode):
		Modes.NORMAL:
			normal_attempts += 1
		Modes.PRACTICE:
			practice_attempts += 1
