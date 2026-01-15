extends CharacterBody2D

signal changed_gamemode(last_portal, mode)

signal died()
signal respawned()

@onready var cubeSprite = $Sprites/cube
@onready var shipSprite = $Sprites/ship
@onready var ballSprite = $Sprites/ball

const SHIP_MAX_VEL : int = 10

const CUBE_GRAVITY : int = 1000
const SHIP_GRAVITY : int = 400
const BALL_GRAVITY : int = 800

const GROUNDED_LEDGE_RAY_OFFSET : float = 6.4
const GROUNDED_WALL_RAY_MARGIN : int = 1

enum jump_types {pink = 225, yellow = 300}

var speed : int = 130

const jump_speed : int = 300

@export var gravity_reverse : bool = true
var gravity_multiplier : int = 1
@export var gravity : int = 1000

@export var gamemode : String = "cube"

var velocity_mult : int = 1
var can_move : bool = true

var in_orb : bool = false
var orb_type = null
var orb_queue : Array[Area2D] = []
var orb_buffer : bool = false

func _ready():
	check_icons()
	
	#Engine.time_scale = 0.2

func check_icons():
	for sprite in $Sprites.get_children():
			if sprite.name == "cube":
				sprite.region_rect = Rect2(IconManager.cube_id * 16, 0, 16, 16)
			elif sprite.name == "ship":
				sprite.region_rect = Rect2(IconManager.ship_id * 16, 0, 16, 16)
				for child in sprite.get_children():
					child.region_rect = Rect2(IconManager.cube_id * 16, 0, 16, 16)
			elif sprite.name == "ball":
				sprite.region_rect = Rect2(IconManager.ball_id * 16, 0, 16, 16)

func change_gamemode(new_gamemode, last_portal):
	
	if new_gamemode == 0:
		change_gravity(1)
	elif new_gamemode == 1:
		change_gravity(-1)
	elif new_gamemode == 2:
		gravity = CUBE_GRAVITY
		$HeadHitbox.set_deferred("disabled", true)
		
		gamemode = "cube"
		emit_signal("changed_gamemode", last_portal, gamemode)
	elif new_gamemode == 3:
		gravity = SHIP_GRAVITY
		position.y -= gravity_multiplier
		$HeadHitbox.set_deferred("disabled", false)
		
		gamemode = "ship"
		emit_signal("changed_gamemode", last_portal, gamemode)
	elif new_gamemode == 4:
		gravity = BALL_GRAVITY
		$HeadHitbox.set_deferred("disabled", false)
		
		gamemode = "ball"
		emit_signal("changed_gamemode", last_portal, gamemode)
	
	for sprite in $Sprites.get_children():
			if sprite.name != gamemode:
				sprite.visible = false
			else:
				sprite.visible = true

func _physics_process(delta):
	
	if can_move:
		velocity.x = speed
		velocity.y += gravity * gravity_multiplier * delta
		
		if len(orb_queue) >= 1:
			if Input.is_action_just_pressed("Jump"):
				
				orb_type = orb_queue[0].jump_type
				
				if orb_type == 0:
					velocity.y = -jump_types.pink * gravity_multiplier
				elif orb_type == 1:
					velocity.y = -jump_types.yellow * gravity_multiplier
				elif orb_type == 2:
					change_gravity(0)
					velocity.y = -50 * gravity_multiplier

				orb_queue[0].jump_activate()
				orb_queue.pop_front()
		else:
			orb_type = null
		
		if gamemode == "cube":
			
			if Input.is_action_pressed("Jump") or not is_on_floor():
				$Sprites.rotate(deg_to_rad(2 * gravity_multiplier))
			elif is_on_floor() and not Input.is_action_pressed("Jump"):
				$Sprites.rotation_degrees = round(rotation_degrees/90)
			
			if Input.is_action_pressed("Jump"):
					if is_on_floor():
						velocity.y = -jump_speed * gravity_multiplier
			
			if velocity.y > 700:
				velocity.y = 700
			elif velocity.y < -500:
				velocity.y = -500
			
			if is_on_ledge():
				
				var space : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
				var params : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
				params.from = Vector2(global_position.x + 8.1 , global_position.y + (GROUNDED_LEDGE_RAY_OFFSET * gravity_multiplier))
				params.to = Vector2(global_position.x + 8.5 , global_position.y + (8 * gravity_multiplier))
				params.collision_mask = 2
				var result : Dictionary = space.intersect_ray(params)
				
				if(result):
					var platform_offset = global_position.y +( 8 * gravity_multiplier) - result.position.y
					global_position.y -= platform_offset * gravity_multiplier
			
			if (velocity.y * gravity_multiplier) < -10 or is_headed_into_wall():
				$SurfaceHitbox.set_deferred("disabled", true)
			elif not is_headed_into_wall():
				$SurfaceHitbox.set_deferred("disabled", false)
			
		elif gamemode == "ship":
			
			$Sprites.rotation_degrees = deg_to_rad(velocity.y * 12)
			
			if Input.is_action_pressed("Jump"):
				velocity_mult += 3
				
				if velocity_mult >= SHIP_MAX_VEL:
					velocity_mult = SHIP_MAX_VEL
				
				velocity.y -= velocity_mult * gravity_multiplier
			else:
				velocity_mult -= 1
				
				if velocity_mult <= 0:
					velocity_mult = 0
			
			if velocity.y > 300 and not gravity_reverse:
				print("capped vel")
				velocity.y = 300
			elif velocity.y < -300 and gravity_reverse:
				velocity.y = -300
				print("capper vel")
			
			if is_really_on_surface():
				velocity.y = 0
			
		elif gamemode == "ball":
			$Sprites.rotate(deg_to_rad(5 * gravity_multiplier))
			
			if (Input.is_action_just_pressed("Jump") or $BallBuffering.time_left > 0) and is_on_floor():
				change_gravity(0)
			elif Input.is_action_just_pressed("Jump") and not is_on_floor() and $BallBuffering.time_left == 0 and not in_orb:
				$BallBuffering.start()
		
		move_and_slide()
		
		if is_really_on_surface():
			snap_to_surface()
			
		
	else:
		velocity = Vector2.ZERO

func die():
	emit_signal("died")
	can_move = false
	change_gravity(1)
	visible = false
	$DeathSFX.play()
	$Respawn.start()

func is_really_on_surface() -> bool:
	
	if velocity.y * gravity_multiplier < -10: 
		return false
	
	return is_on_floor() or $SurfaceRaycast.is_colliding()

func snap_to_surface()->void:
	
	if velocity.y * gravity_multiplier < -10: 
		return
	
	if not is_on_floor() and $SurfaceRaycast.is_colliding():
		
		var top_surface : Vector2 = $SurfaceRaycast.get_collision_point()
		global_position.y += top_surface.y - (global_position.y + ( 8 * gravity_multiplier))

func is_on_ledge() -> bool:
	return $BottomRaycast.is_colliding() and not $LedgeRaycast.is_colliding()

func is_headed_into_wall() -> bool:
	return ($BottomRaycast.is_colliding() and $LedgeRaycast.is_colliding()) or is_on_wall()

func change_gravity(g : int):
	
	match g:
		-1:
			gravity_reverse = true
			gravity_multiplier = -1
			up_direction = Vector2(0, 1)
			
			$SurfaceHitbox.global_rotation_degrees = 180
			$HeadHitbox.global_rotation_degrees = 0
			
			$SurfaceRaycast.global_rotation_degrees = 180
			$LedgeRaycast.set_deferred("position.y", -GROUNDED_LEDGE_RAY_OFFSET)
			$BottomRaycast.position.y = 8 - GROUNDED_WALL_RAY_MARGIN
			$TopRaycast.position.y = -8 + GROUNDED_WALL_RAY_MARGIN
			
			if gamemode == "cube":
				cubeSprite.flip_v = true
			elif gamemode == "ship":
				shipSprite.flip_v = true
				
				for child in shipSprite.get_children():
					child.flip_v = true
					child.position.y = 2
			
		1:
			gravity_reverse = false
			gravity_multiplier = 1
			up_direction = Vector2(0, -1)
			
			$SurfaceHitbox.global_rotation_degrees = 0
			$HeadHitbox.global_rotation_degrees = 180
			
			$SurfaceRaycast.global_rotation_degrees = 0
			$LedgeRaycast.set_deferred("position.y", GROUNDED_LEDGE_RAY_OFFSET)
			$BottomRaycast.position.y = -8 + GROUNDED_WALL_RAY_MARGIN
			$TopRaycast.position.y = 8 - GROUNDED_WALL_RAY_MARGIN
			
			if gamemode == "cube":
				cubeSprite.flip_v = false
			elif gamemode == "ship":
				shipSprite.flip_v = false
				
				for child in shipSprite.get_children():
					child.flip_v = false
					child.position.y = -2
			
			
			
		0:
			change_gravity(-gravity_multiplier)

func _on_damage_area_entered(area):
	
	if area.is_in_group("Hazard"):
		print("what?")
		die()
	
	if area.has_method("jump_activate"):
		orb_queue.append(area)
	
	if area.is_in_group("gamemode_portal"):
		change_gamemode(area.portal_type, area)
	
	if area.is_in_group("JumpPad"):
		if area.jump_type == 0:
			velocity.y = -jump_types.pink * gravity_multiplier
		elif area.jump_type == 1:
			velocity.y = -jump_types.yellow * gravity_multiplier
		elif area.jump_type == 2:
			velocity.y = -150 * gravity_multiplier
			change_gravity(0)


func _on_detect_area_exited(area):
	if area.has_method("jump_activate"):
		var orb_index : int = orb_queue.find(area)
		if orb_index > -1:
			orb_queue.remove_at(orb_index)

func _on_respawn_timeout():
	change_gamemode(2, null)
	visible = true
	can_move = true
	emit_signal("respawned")

func _on_platform_collision(body: Node2D) -> void:
	print("hit platform")
	die()
