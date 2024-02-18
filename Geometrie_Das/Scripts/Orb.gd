extends Area2D

@export_enum("pink", "yellow", "blue", "green") var jump_type

func jump_activate():
	$AnimationPlayer.play("activate")
