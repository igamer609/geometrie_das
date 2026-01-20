class_name GDObject extends StaticBody2D

@export var obj_res : GD_Object
@export var in_level : bool = false

var scene : Node2D = null

@onready var vis_notif : VisibleOnScreenNotifier2D = $VisibilityNotifier
@onready var anim_player : AnimationPlayer = $AnimationPlayer
@onready var shader_material : ShaderMaterial = preload("res://Objects/SelectedMaterial.tres")

@export var uid : int
@export var other : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	if obj_res:
		update()

func update():
	if obj_res.is_scene:
		scene = obj_res.scene.instantiate()
		scene.position = Vector2(8, 8)
		scene.name = "Scene"
		
		$Collision.polygon = obj_res.collision_shape
		
		$SceneParent.add_child(scene)
		
		if in_level:
			var particles : GPUParticles2D = scene.find_child("Particles")
			if(particles):
				particles.emitting = true
		
		var sprite : Sprite2D = scene.find_child("Sprite")
		if sprite:
			sprite.material = shader_material
		
		$Sprite.queue_free()
		
	else:
		$Sprite.texture = obj_res.texture
		$Collision.polygon = obj_res.collision_shape
		$Sprite.material = shader_material
	
	if not obj_res.is_solid:
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, false)
		set_collision_layer_value(3, true)
	else:
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, true)
		set_collision_layer_value(3, false)

func select():
	if scene:
		var sprite : Sprite2D = scene.find_child("Sprite")
		if sprite:
			sprite.set_instance_shader_parameter("is_selected", true)
	else:
		$Sprite.set_instance_shader_parameter("is_selected", true)

func deselect():
	if scene:
		var sprite : Sprite2D = scene.find_child("Sprite")
		if sprite:
			sprite.set_instance_shader_parameter("is_selected", false)
	else:
		$Sprite.set_instance_shader_parameter("is_selected", false)

func enable_transition():
	vis_notif.screen_entered.connect(load_object)
	vis_notif.screen_exited.connect(unload_object)

func load_object():
	print("load!!")
	if not anim_player.is_playing():
		anim_player.play("load1")

func unload_object():
	print("unload")
	if not anim_player.is_playing():
		anim_player.play_backwards("load1")
