# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Control

func _ready():
	setup_tab_buttons()

func setup_tab_buttons():
	for button in $TabContainer.get_children():
		if button.name == "Create":
			button.pressed.connect(SceneTransition.change_scene.bind("res://Scenes/Menus/CreateTab.tscn"))
		if button.name == "Saved":
			button.pressed.connect(SceneTransition.change_scene.bind("res://Scenes/Menus/SavedTab.tscn"))

func _on_exit_pressed():
	SceneTransition.change_scene("res://Scenes/MainMenu.tscn")
