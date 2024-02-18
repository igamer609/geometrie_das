extends Control

func _cube_tab():
	change_tab("Cube")

func change_tab(gamemode):
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

func _ship_tab():
	change_tab("Ship")

func _process(delta):
	for icon in $DisplayIcons.get_children():
		if icon.name == "CubeDisplay":
			icon.texture.region = Rect2(IconManager.cube_id * 16, 0, 16, 16)
		elif icon.name == "ShipDisplay":
			icon.texture.region = Rect2(IconManager.ship_id * 16, 0, 16, 16)


func _on_exit():
	TransitionScene.change_scene("res://Scenes/MainMenu.tscn")
