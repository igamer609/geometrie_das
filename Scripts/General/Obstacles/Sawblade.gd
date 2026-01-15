extends Area2D

@export var rot_speed = 0

func _ready():
	rot_speed = randi_range(-10, 10)
	if(rot_speed == 0):
		rot_speed += 1

func _process(delta):
	rotate(deg_to_rad(rot_speed * 1000 * delta))
