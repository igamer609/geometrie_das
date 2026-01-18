extends Control

func _ready() -> void:
	_cube_tab()

func change_tab(gamemode):
	_update_icons()
	
	for container in $IconToolbox.get_children():
		if container.name == gamemode + "s":
			container.visible = true
		else:
			container.visible = false
	
	for icon in $DisplayIcons.get_children():
		if icon.name == gamemode + "Display":
			icon.visible = true
		else:
			icon.visible = false

func _update_icons():
	for icon in $DisplayIcons.get_children():
		if icon.name == "CubeDisplay":
			icon.texture.region = Rect2(PlayerData.cube_id * 16, 0, 16, 16)
		if icon.name == "ShipDisplay":
			icon.texture.region = Rect2(PlayerData.ship_id * 16, 0, 16, 16)
		if icon.name == "BallDisplay":
			icon.texture.region = Rect2(PlayerData.ball_id * 16, 0, 16, 16)

func _process(_delta: float) -> void:
	_update_icons()

func _cube_tab():
	change_tab("Cube")

func _ship_tab():
	change_tab("Ship")

func _ball_tab():
	change_tab("Ball")

func _on_exit():
	TransitionScene.change_scene("res://Scenes/MainMenu.tscn")
