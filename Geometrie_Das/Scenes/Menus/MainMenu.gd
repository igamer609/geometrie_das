extends Control



func _icon_button():
	TransitionScene.change_scene("res://Scenes/Menus/IconMenu.tscn")


func _levels_pressed():
	TransitionScene.change_scene("res://Scenes/Menus/LevelMenu.tscn")
