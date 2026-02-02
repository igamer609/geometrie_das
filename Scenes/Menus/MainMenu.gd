# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Control

func _icon_button():
	TransitionScene.change_scene("res://Scenes/Menus/IconMenu.tscn")

func _levels_pressed():
	TransitionScene.change_scene("res://Scenes/Menus/LevelMenu.tscn")

func _exit_music_credits():
	$MusicCredits.visible = false

func _enter_music_credits():
	$MusicCredits.visible = true


func _enter_settings():
	$OptionSettings.visible = true


func _exit_settings():
	$OptionSettings.visible = false

func open_reset():
	$ResetDialogue.visible = true

func cancel_reset():
	$ResetDialogue.visible = false

func _reset_progress():
	if FileAccess.file_exists("user://level_data.save"):
		DirAccess.remove_absolute("user://level_data.save")
	
	if FileAccess.file_exists("user://playerdata.save"):
		DirAccess.remove_absolute("user://playerdata.save")
	
	PlayerData.load_save()
	
	$ResetDialogue.visible = false


func _on_edit_pressed():
	TransitionScene.change_scene("res://Scenes/Menus/EditorTab.tscn")
