extends CharacterBody2D

signal changed_gamemode(last_portal, mode)

signal died()
signal respawned()

@onready var cubeSprite = $Sprites/cube
@onready var shipSprite = $Sprites/ship
@onready var ballSprite = $Sprites/ball

const SHIP_MAX_VEL : int = 10
const SHIP_THRUST : float = 800

const CUBE_GRAVITY : int = 1000
const SHIP_GRAVITY : int = 400
const BALL_GRAVITY : int = 800

const GROUNDED_LEDGE_RAY_OFFSET : float = 6.4
const GROUNDED_WALL_RAY_MARGIN : float = 0.5

enum jump_types {pink = 200, yellow = 275}

var speed : int = 130

const jump_speed : int = 300

@export var gravity_reverse : bool = true
var gravity_multiplier : int = 1
@export var gravity : int = 1000

@export var gamemode : String = "cube"


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
				sprite.region_rect = Rect2(PlayerData.cube_id * 16, 0, 16, 16)
			elif sprite.name == "ship":
				sprite.region_rect = Rect2(PlayerData.ship_id * 16, 0, 16, 16)
				for child in sprite.get_children():
					child.region_rect = Rect2(PlayerData.cube_id * 16, 0, 16, 16)
			elif sprite.name == "ball":
				sprite.region_rect = Rect2(PlayerData.ball_id * 16, 0, 16, 16)

func change_gamemode(new_gamemode : int, last_portal : Area2D) -> void:
	
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
		
		if is_really_on_surface():
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

func _physics_process(delta : float) -> void:
	
	if can_move:
		
		velocity.x = speed
		velocity.y += gravity * gravity_multiplier * delta
		
		if len(orb_queue) >= 1:
			if Input.is_action_just_pressed("Jump"):
				
				orb_type = orb_queue[0].jump_type
				velocity.y = velocity.y / 10
				
				if orb_type == 0:
					velocity.y = -jump_types.pink * gravity_multiplier
				elif orb_type == 1:
					velocity.y = -jump_types.yellow * gravity_multiplier
				elif orb_type == 2:
					velocity.y = -50 * gravity_multiplier
					change_gravity(0)

				orb_queue[0].jump_activate()
				orb_queue.pop_front()
		else:
			orb_type = null
		
		if gamemode == "cube":
			_process_cube_physics(delta)
		elif gamemode == "ship":
			_process_ship_physics(delta)
		elif gamemode == "ball":
			_process_ball_physics(delta)
		
		move_and_slide()
		
		if gamemode == "cube":
			if is_really_on_surface():
				snap_to_surface()
		elif gamemode == "ship" or gamemode == "ball":
			if not Input.is_action_pressed("Jump"):
				snap_to_surface()
	else:
		velocity = Vector2.ZERO

func _process_cube_physics(delta : float) -> void:
	if Input.is_action_pressed("Jump") or not is_really_on_surface():
		$Sprites.rotate(deg_to_rad(2 * gravity_multiplier))
	elif is_really_on_surface() and not Input.is_action_pressed("Jump"):
		$Sprites.rotation_degrees = lerp($Sprites.rotation_degrees, round($Sprites.rotation_degrees/90) * 90, _calculate_lerp_weight(delta, 2))
	
	if Input.is_action_pressed("Jump"):
			if is_really_on_surface():
				velocity.y = -jump_speed * gravity_multiplier 
	
	if velocity.y > 700:
		velocity.y = 700
	elif velocity.y < -500:
		velocity.y = -500
	
	if is_on_ledge():
		snap_to_ledge()
	
	if (velocity.y * gravity_multiplier) < -10 or is_headed_into_wall():
		$SurfaceHitbox.disabled = true
	elif not is_headed_into_wall():
		$SurfaceHitbox.disabled = false

func _process_ship_physics(delta : float) -> void:
	
	if Input.is_action_pressed("Jump"):
		if is_really_on_ceiling():
			velocity.y = 0
		else:
			velocity.y -= SHIP_THRUST * gravity_multiplier * delta
	
	if velocity.y < -300:
		velocity.y = -300
	if velocity.y > 300:
		velocity.y = 300
	
	$Sprites.rotation_degrees = lerp($Sprites.rotation_degrees, clampf(velocity.y / 2, -90, 90), 0.1)
	
	if is_head_headed_into_wall():
		$HeadHitbox.disabled = true
	else:
		$HeadHitbox.disabled = false
	
	if is_bottom_headed_into_wall():
		$SurfaceHitbox.disabled =true
	else:
		$SurfaceHitbox.disabled = false

func _process_ball_physics(delta : float) -> void:
	$Sprites.rotate(deg_to_rad(2 * gravity_multiplier))
	
	if Input.is_action_just_pressed("Jump") and is_really_on_surface():
		change_gravity(0)
	
	if is_head_headed_into_wall():
		$HeadHitbox.disabled = true
	else:
		$HeadHitbox.disabled = false
	
	if is_bottom_headed_into_wall():
		$SurfaceHitbox.disabled =true
	else:
		$SurfaceHitbox.disabled = false

func _calculate_lerp_weight(delta : float, rate : float) -> float:
	var t : float = exp(-rate * delta)
	return t

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

func is_really_on_ceiling() -> bool:
	if velocity.y * gravity_multiplier > 10:
		return false
	return is_on_ceiling() or $CeilingRaycast.is_colliding()

func snap_to_surface()->void:
	if velocity.y * gravity_multiplier < -10 : 
		return
	if not is_on_floor() and $SurfaceRaycast.is_colliding():
		print("Snapped to surface below")
		var top_surface : Vector2 = $SurfaceRaycast.get_collision_point()
		global_position.y += top_surface.y - (global_position.y + ( 8 * gravity_multiplier))

func snap_to_ledge() -> void:
	var space : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var params : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	params.from = Vector2(global_position.x + 8.1 , global_position.y + (GROUNDED_LEDGE_RAY_OFFSET * gravity_multiplier))
	params.to = Vector2(global_position.x + 8.5 , global_position.y + (8 * gravity_multiplier))
	params.collision_mask = 2
	var result : Dictionary = space.intersect_ray(params)
	
	if(result):
		var platform_offset = global_position.y +( 8 * gravity_multiplier) - result.position.y
		global_position.y -= platform_offset * gravity_multiplier

func is_on_ledge() -> bool:
	return $BottomRaycast.is_colliding() and not $LedgeRaycast.is_colliding()

func is_headed_into_wall() -> bool:
	return ($BottomRaycast.is_colliding() and $LedgeRaycast.is_colliding()) or is_on_wall()

func is_bottom_headed_into_wall() -> bool:
	return ($BottomRaycast.is_colliding() or $LedgeRaycast.is_colliding())

func is_head_headed_into_wall() -> bool:
	return ($TopRaycast.is_colliding() or $HeadLedgeRaycast.is_colliding())

func change_gravity(g : int):
	match g:
		-1:
			gravity_reverse = true
			gravity_multiplier = -1
			up_direction = Vector2(0, 1)
			$SurfaceHitbox.global_rotation_degrees = 180
			$HeadHitbox.global_rotation_degrees = 0
			$SurfaceRaycast.global_rotation_degrees = 180
			$CeilingRaycast.global_rotation_degrees = 0
			$LedgeRaycast.set_deferred("position.y", -GROUNDED_LEDGE_RAY_OFFSET)
			$HeadLedgeRaycast.set_deferred("position.y", GROUNDED_LEDGE_RAY_OFFSET)
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
			$CeilingRaycast.global_rotation_degrees = 180
			$LedgeRaycast.set_deferred("position.y", GROUNDED_LEDGE_RAY_OFFSET)
			$HeadLedgeRaycast.set_deferred("position.y", -GROUNDED_LEDGE_RAY_OFFSET)
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

func _on_platform_collision(_body: Node2D) -> void:
	die()
