# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
#	"Love you, RubRub" - igamer
# ----------------------------------------------------------

extends CharacterBody2D
signal changed_gamemode(last_portal, mode)
signal died()
signal respawned()

@onready var cubeSprite = $Sprites/cube
@onready var shipSprite = $Sprites/ship
@onready var ballSprite = $Sprites/ball

@onready var surface_raycast : RayCast2D = $SurfaceRaycast
@onready var bottom_raycast : RayCast2D = $BottomRaycast
@onready var ledge_raycast : RayCast2D = $LedgeRaycast

@onready var ceiling_raycast : RayCast2D = $CeilingRaycast
@onready var head_raycast : RayCast2D = $HeadRaycast
@onready var head_ledge_raycast : RayCast2D = $HeadLedgeRaycast

@onready var surface_hitbox : CollisionShape2D = $SurfaceHitbox
@onready var head_hitbox : CollisionShape2D = $HeadHitbox

const SCALE_MULTIPLIER : float = 10

const CUBE_JUMP_VELOCITY : float = 25 * SCALE_MULTIPLIER

const SHIP_MAX_VEL : int = 180
const SHIP_THRUST : float = 4

const CUBE_GRAVITY : float = 93 * SCALE_MULTIPLIER
const SHIP_GRAVITY : float = 1.7
const BALL_GRAVITY : float = 4

const GROUNDED_LEDGE_RAY_OFFSET : float = 6
const WALL_RAY_MARGIN : float = 0.5

enum jump_types {pink = 200, yellow = 275}

var speed : int = 130

@export var gravity_reverse : bool = true
var gravity_multiplier : int = 1
@export var gravity : int = 50

enum GamemodeTypes {CUBE, SHIP, BALL}
@export var gamemode : String = "cube"

var can_move : bool = true
var consecutive_jumps : int = 0

var in_orb : bool = false
var orb_type = null
var orb_queue : Array[Area2D] = []
var orb_buffer : bool = false

func _ready():
	_check_icons()
	change_gravity(1)
	#Engine.time_scale = 0.2

func _check_icons():
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
		if gravity_multiplier != 1:
			velocity.y = velocity.y * 0.75
		change_gravity(1)
	elif new_gamemode == 1:
		if gravity_multiplier != -1:
			velocity.y = velocity.y * 0.75
		change_gravity(-1)
	elif new_gamemode == 2:
		head_hitbox.set_deferred("disabled", true)
		gamemode = "cube"
		emit_signal("changed_gamemode", last_portal, gamemode)
	elif new_gamemode == 3:
		head_hitbox.set_deferred("disabled", false)
		gamemode = "ship"
		$Sprites.rotation_degrees = velocity.y / PI
		emit_signal("changed_gamemode", last_portal, gamemode)
	elif new_gamemode == 4:
		head_hitbox.set_deferred("disabled", false)
		
		if gamemode == "cube" and (velocity.y * gravity_multiplier < -10 or Input.is_action_just_pressed("Jump")):
			velocity.y -= SCALE_MULTIPLIER * 5 * gravity_multiplier
		
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
		
		if not is_on_floor() and Input.is_action_just_pressed("Jump"):
			orb_buffer = true

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
	
	velocity.y += CUBE_GRAVITY * gravity_multiplier * delta
	var hit_orb : bool = _check_orbs()
	
	if not hit_orb:
		if Input.is_action_pressed("Jump"):
				if is_really_on_surface():
					velocity.y = -CUBE_JUMP_VELOCITY * gravity_multiplier
					if consecutive_jumps > 1:
						velocity.y -= (SCALE_MULTIPLIER - 2) * gravity_multiplier
					consecutive_jumps += 1
		else:
			consecutive_jumps = 0
	
	if Input.is_action_pressed("Jump") or not is_really_on_surface():
		$Sprites.rotate(deg_to_rad(1.33 * gravity_multiplier))
	elif is_really_on_surface() and not Input.is_action_pressed("Jump"):
		$Sprites.rotation_degrees = lerp($Sprites.rotation_degrees, round($Sprites.rotation_degrees/90) * 90, 0.2)
	
	if velocity.y > 700:
		velocity.y = 700
	elif velocity.y < -500:
		velocity.y = -500
	
	if is_on_ledge():
		snap_to_ledge()
	
	if (velocity.y * gravity_multiplier) < -10 or is_headed_into_wall() or is_on_ledge():
		surface_hitbox.disabled = true
	elif not is_headed_into_wall():
		surface_hitbox.disabled = false

func _process_ship_physics(delta : float) -> void:
	
	velocity.y += SHIP_GRAVITY * gravity_multiplier
	orb_buffer = false
	_check_orbs()
	
	if Input.is_action_pressed("Jump"):
		if is_really_on_ceiling():
			velocity.y = 0
		else:
			velocity.y -= SHIP_THRUST * gravity_multiplier
	
	if velocity.y < -SHIP_MAX_VEL:
		velocity.y = -SHIP_MAX_VEL
	if velocity.y > SHIP_MAX_VEL:
		velocity.y = SHIP_MAX_VEL
	
	$Sprites.rotation_degrees = lerp($Sprites.rotation_degrees, velocity.y / PI, 0.1)
	
	if is_on_ledge():
		snap_to_ledge()
	
	if is_head_headed_into_wall():
		head_hitbox.disabled = true
	else:
		head_hitbox.disabled = false
	
	if is_bottom_headed_into_wall() or is_on_ledge():
		surface_hitbox.disabled =true
	else:
		surface_hitbox.disabled = false

func _process_ball_physics(delta : float) -> void:
	
	velocity.y += BALL_GRAVITY * gravity_multiplier
	var hit_orb : bool = _check_orbs()
	if not hit_orb:
		if (Input.is_action_just_pressed("Jump") or orb_buffer) and is_really_on_surface():
			orb_buffer = false
			change_gravity(0)
	
	$Sprites.rotate(deg_to_rad(2 * gravity_multiplier))
	
	if is_on_ledge():
		snap_to_ledge()
	
	if is_head_headed_into_wall():
		head_hitbox.disabled = true
	else:
		head_hitbox.disabled = false
	
	if is_bottom_headed_into_wall() or is_on_ledge():
		surface_hitbox.disabled =true
	else:
		surface_hitbox.disabled = false

func _check_orbs() -> bool:
	if len(orb_queue) >= 1:
		if Input.is_action_just_pressed("Jump") or (Input.is_action_pressed("Jump") and orb_buffer):
			orb_buffer = false
			orb_type = orb_queue[0].jump_type
			velocity.y = velocity.y / 10
			
			if orb_type == 0:
				velocity.y = -jump_types.pink * gravity_multiplier
			elif orb_type == 1:
				velocity.y = -jump_types.yellow * gravity_multiplier
			elif orb_type == 2:
				velocity.y = -100 * gravity_multiplier
				change_gravity(0)

			orb_queue[0].activate()
			orb_queue.pop_front()
			return true
	else:
		orb_type = null
	
	if orb_buffer and not Input.is_action_pressed("Jump"):
		orb_buffer = false
	
	return false

func die():
	emit_signal("died")
	orb_buffer = false
	orb_queue.clear()
	can_move = false
	visible = false
	$DeathSFX.play()
	$Respawn.start()

func is_really_on_surface() -> bool:
	if velocity.y * gravity_multiplier < -10: 
		return false
	return is_on_floor() or surface_raycast.is_colliding()

func is_really_on_ceiling() -> bool:
	if velocity.y * gravity_multiplier > 10:
		return false
	return is_on_ceiling() or ceiling_raycast.is_colliding()

func snap_to_surface()->void:
	if velocity.y * gravity_multiplier < -10: 
		return
	if not is_on_floor() and surface_raycast.is_colliding() and ceiling_raycast.is_colliding():
		var top_surface : Vector2 = surface_raycast.get_collision_point()
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
	return bottom_raycast.is_colliding() and not ledge_raycast.is_colliding()

func is_headed_into_wall() -> bool:
	return (bottom_raycast.is_colliding() and ledge_raycast.is_colliding()) or is_on_wall()

func is_bottom_headed_into_wall() -> bool:
	return (bottom_raycast.is_colliding() or ledge_raycast.is_colliding())

func is_head_headed_into_wall() -> bool:
	return (head_raycast.is_colliding() or head_ledge_raycast.is_colliding())

func change_gravity(g : int):
	match g:
		-1:
			gravity_reverse = true
			gravity_multiplier = -1
			up_direction = Vector2(0, 1)
			surface_hitbox.global_rotation_degrees = 180
			head_hitbox.global_rotation_degrees = 0
			surface_raycast.global_rotation_degrees = 180
			ceiling_raycast.global_rotation_degrees = 0
			ledge_raycast.set_deferred("position.y", -GROUNDED_LEDGE_RAY_OFFSET)
			head_ledge_raycast.set_deferred("position.y", GROUNDED_LEDGE_RAY_OFFSET)
			bottom_raycast.position.y = -8 + WALL_RAY_MARGIN
			head_raycast.position.y = 8 - WALL_RAY_MARGIN
			
			shipSprite.flip_v = true
			for child in shipSprite.get_children():
				child.flip_v = true
				child.position.y = 2
		1:
			gravity_reverse = false
			gravity_multiplier = 1
			up_direction = Vector2(0, -1)
			surface_hitbox.global_rotation_degrees = 0
			head_hitbox.global_rotation_degrees = 180
			surface_raycast.global_rotation_degrees = 0
			ceiling_raycast.global_rotation_degrees = 180
			ledge_raycast.set_deferred("position.y", GROUNDED_LEDGE_RAY_OFFSET)
			head_ledge_raycast.set_deferred("position.y", -GROUNDED_LEDGE_RAY_OFFSET)
			bottom_raycast.position.y = 8 - WALL_RAY_MARGIN
			head_raycast.position.y = -8 + WALL_RAY_MARGIN
			
			shipSprite.flip_v = false
			for child in shipSprite.get_children():
				child.flip_v = false
				child.position.y = -2
		0:
			change_gravity(-gravity_multiplier)

func _on_damage_area_entered(area : Area2D):
	if area.is_in_group("Hazard"):
		die()
	if area.is_in_group("Orb"):
		orb_queue.append(area)
		area.player_enter()
	if area.is_in_group("gamemode_portal"):
		change_gamemode(area.portal_type, area)
		area.activate()
	if area.is_in_group("JumpPad"):
		area.activate()
		if area.jump_type == 0:
			velocity.y = -jump_types.pink * 1.15 * gravity_multiplier
		elif area.jump_type == 1:
			velocity.y = -jump_types.yellow * 1.15 * gravity_multiplier
		elif area.jump_type == 2:
			velocity.y = -150 * gravity_multiplier
			change_gravity(0)

func _on_detect_area_exited(area : Area2D):
	if area.is_in_group("Orb"):
		var orb_index : int = orb_queue.find(area)
		if orb_index > -1:
			orb_queue.remove_at(orb_index)

func _on_respawn_timeout():
	change_gamemode(2, null)
	change_gravity(1)
	$Sprites.global_rotation_degrees = 0
	visible = true
	can_move = true
	emit_signal("respawned")

func _on_platform_collision(_body: Node2D) -> void:
	die()
