class_name PlayerSaveData extends Resource

@export_category("Progress")
@export var completions : Dictionary[int, LevelProgress] = {}

@export_category("Account")
@export var account : Dictionary[String, String] = {}

@export var total_attempts : int = 0
@export var total_clicks : int = 0
@export var stars : int = 0
@export var builder_points : int = 0

@export var cube_id : int = 0
@export var ship_id : int = 0
@export var ball_id : int = 0

@export var new : bool = true
@export var save_version : String
