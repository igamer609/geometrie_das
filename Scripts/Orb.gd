extends Area2D

@export_enum("pink", "yellow", "blue", "green") var jump_type

func player_enter():
	$AnimationPlayer.play("player_enter")

func jump_activate():
	$AnimationPlayer.play("activate")
