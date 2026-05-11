# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Node

signal account_updated(username : String, user_id : int)

var data : PlayerSaveData

var current_version : String 

func increment_total_attempts() -> void:
	data.total_attempts += 1

func _ready():
	
	current_version = ProjectSettings.get_setting("application/config/version")
	
	load_save()

func _update_account(username : String, user_id : int, token : String) -> void:
	data.account.set("username", username)
	data.account.set("user_id", user_id)
	data.account.set("token", token)
	
	account_updated.emit(username, user_id)

func _log_out() -> void:
	var last_username : String = String(data.account.get("username", ""))
	if(last_username):
		data.account.set("username", last_username)
		data.account.set("user_id", 0)
		data.account.set("token", "")
		
		account_updated.emit(last_username, 0)

func save():
	var error : Error = ResourceSaver.save(data, "user://playerdata.save")
	
	if(error != OK):
		print(error_string(error))
		push_error("Failed to save player data!")

func load_save() -> void:
	data = ResourceLoader.load("user://playerdata.save")
	if(!data):
		data = PlayerSaveData.new()
	else:
		data.new = false

func set_icon(gamemode : int, id : int) -> void:
	match gamemode:
		0 : data.cube_id = id;
		1 : data.ship_id = id;
		2: data.ball_id = id;

func get_main_levels_progress() -> Dictionary[int, LevelProgress]:
	var main_levels : Dictionary[int, LevelProgress] = {}
	
	for level : int in data.completions.keys():
		var level_progress : LevelProgress = data.completions.get(level)
		if(level_progress.main):
			main_levels.set(level, level_progress)
	
	return main_levels

func get_level_progress(level_id : int) -> LevelProgress:
	var level_progress : LevelProgress = data.completions.get(level_id, null)
	
	if(!level_progress):
		level_progress = LevelProgress.new()
		data.completions.set(level_id, level_progress)
	
	return level_progress

func get_player_name() -> String:
	return data.account.get("username", "Player")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save()
