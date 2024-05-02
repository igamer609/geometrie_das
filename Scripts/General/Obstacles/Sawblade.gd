extends Area2D

var rot_speed = 0

func _ready():
	body_entered.connect(on_body_enter)
	
	rot_speed = 10

func on_body_enter(body):
	if body.is_in_group("Player"):
		body.die()

func _process(delta):
	rotate(deg_to_rad(rot_speed))
