extends CharacterBody2D

signal changed_gamemode(last_portal, mode)

signal died()
signal respawned()

@onready var cubeSprite = $Sprites/cube
@onready var shipSprite = $Sprites/ship

const SHIP_MAX_VEL = 15

const CUBE_GRAVITY = 1000
const SHIP_GRAVITY = 500

enum jump_types {pink = 200, yellow = 300}

var speed = 125

const jump_speed = 300

@export var gravity_reverse = true
var gravity_multiplier = 1
var gravity = 800

@export var gamemode = "cube"

var velocity_mult = 1
var can_move = true

var in_orb = false
var orb_type = null
var orb_area = null

func _ready():
	check_icons()

func check_icons():
	for sprite in $Sprites.get_children():
			if sprite.name == "cube":
				sprite.region_rect = Rect2(IconManager.cube_id * 16, 0, 16, 16)
			elif sprite.name == "ship":
				sprite.region_rect = Rect2(IconManager.ship_id * 16, 0, 16, 16)
				for child in sprite.get_children():
					child.region_rect = Rect2(IconManager.cube_id * 16, 0, 16, 16)

func change_gamemode(new_gamemode, last_portal):
	
	if new_gamemode == 0:
		gravity_reverse = false
	elif new_gamemode == 1:
		gravity_reverse = true
	elif new_gamemode == 2:
		gravity = CUBE_GRAVITY
		
		gamemode = "cube"
		emit_signal("changed_gamemode", last_portal, gamemode)
	elif new_gamemode == 3:
		gravity = SHIP_GRAVITY
		position.y -= 2 * gravity_multiplier
		
		shipSprite.visible = true
		gamemode = "ship"
		emit_signal("changed_gamemode", last_portal, gamemode)
	
	for sprite in $Sprites.get_children():
			if sprite.name != gamemode:
				sprite.visible = false
			else:
				sprite.visible = true

func _physics_process(delta):
	
	if gravity_reverse == true:
		gravity_multiplier = -1
		up_direction = Vector2(0, 1)
		
		if gamemode == "cube":
			cubeSprite.flip_v = true
		elif gamemode == "ship":
			shipSprite.flip_v = true
			
			for child in shipSprite.get_children():
				child.flip_v = true
				child.position.y = 2
	elif gravity_reverse == false:
		gravity_multiplier = 1
		up_direction = Vector2(0, -1)
		if gamemode == "cube":
			cubeSprite.flip_v = false
			
			
		elif gamemode == "ship":
			shipSprite.flip_v = false
			
			for child in shipSprite.get_children():
				child.flip_v = false
				child.position.y = -2
	
	if can_move:
		velocity.x = speed
		
		if gamemode == "cube":
			
			if not is_on_floor():
				cubeSprite.rotate(deg_to_rad(5 * gravity_multiplier))
			else:
				cubeSprite.rotation_degrees = round(cubeSprite.rotation_degrees/90)*90
			
			if Input.is_action_pressed("Jump"):
					if is_on_floor():
						velocity.y = -jump_speed * gravity_multiplier
						print("jump")
		elif gamemode == "ship":
			
			shipSprite.rotation_degrees = deg_to_rad(velocity.y * 12)
			
			if Input.is_action_pressed("Jump"):
				velocity_mult += 2
				
				if velocity_mult >= SHIP_MAX_VEL:
					velocity_mult = SHIP_MAX_VEL
				
				velocity.y -= velocity_mult * gravity_multiplier
			else:
				velocity_mult -= 1
				
				if velocity_mult <= 0:
					velocity_mult = 0
		
		if in_orb:
			if Input.is_action_just_pressed("Jump"):
				
				velocity.y = 0
				
				if orb_type == 0:
					velocity.y -= jump_types.pink * gravity_multiplier
				elif orb_type == 1:
					velocity.y -= jump_types.yellow * gravity_multiplier
				in_orb = false
				orb_area.jump_activate()
		else:
			orb_type = null
			orb_area = null
		
		if velocity.y > 600 and not gravity_reverse:
			velocity.y = 600
		elif velocity.y < -600 and gravity_reverse:
			velocity.y = -600
		
		velocity.y += gravity * gravity_multiplier * delta
		
		set_velocity(velocity)
		move_and_slide()
		velocity = velocity
		
		if is_on_wall():
			print("entered wall")
			die()
	else:
		velocity = Vector2.ZERO

func die():
	emit_signal("died")
	can_move = false
	gravity_reverse = false
	change_gamemode(2, null)
	visible = false
	$Respawn.start()



func _on_detect_area_area_entered(area):
	if area.has_method("jump_activate"):
		in_orb = true
		orb_type = area.jump_type
		orb_area = area
	
	if area.is_in_group("gamemode_portal"):
		change_gamemode(area.portal_type, area)





func _on_detect_area_area_exited(area):
	if area.has_method("jump_activate"):
		in_orb = false


func _on_respawn_timeout():
	visible = true
	can_move = true
	emit_signal("respawned")
