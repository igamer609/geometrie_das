# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name GDObject extends StaticBody2D

@export var obj_res : GDObjectResource
@export var in_level : bool = false
@export var editor_layer : int = -1

var scene : Node2D = null
var obj_sprite : Sprite2D = null
var collision : CollisionPolygon2D = null
var scene_parent : Node2D = null

@onready var _selection_material : ShaderMaterial = preload("res://Objects/SelectedMaterial.tres")

@export var uid : int
@export var other : Dictionary
var trigger : Trigger = null

static func create_object(obj_id : int, n_uid : int, pos : Vector2, rot : float, n_other : Dictionary, in_level : bool = false) -> GDObject:
	var res : GDObjectResource = ResourceLibrary.library[obj_id]
	var object : GDObject = GDObject.new()
	object.add_to_group("Object")
	
	object.obj_res = res
	object.uid = n_uid
	object.global_position = pos
	object.global_rotation = rot
	object.other = n_other
	object.in_level = in_level
	
	return object

func _init() -> void:
	ResourceLibrary.free_objects.connect(delete)
	ResourceLibrary.change_editor_layer.connect(check_editor_layer)

func _ready() -> void:
	if obj_res:
		update()

func update() -> void:
	if not in_level or (not obj_res.is_decoration and in_level and not obj_res.is_scene):
		collision = CollisionPolygon2D.new()
		add_child(collision)
		collision.position = Vector2(8, 8)
		collision.polygon = obj_res.collision_shape
	
	if not obj_res.is_scene:
		obj_sprite = Sprite2D.new()
		add_child(obj_sprite)
		obj_sprite.position = Vector2(8,8)
	else:
		scene_parent = Node2D.new()
		add_child(scene_parent)
	
	if scene_parent != null:
		scene = obj_res.scene.instantiate()
		scene.position = Vector2(8, 8)
		scene.name = "Scene"
		scene_parent.add_child(scene)
		
		z_index = 0
		
		if in_level:
			var particles : GPUParticles2D = scene.find_child("Particles")
			if(particles):
				particles.emitting = true
		else:
			var sprite : Sprite2D = scene.find_child("Sprite")
			if sprite:
				obj_sprite = sprite
				sprite.material = _selection_material
	else:
		obj_sprite.texture = obj_res.texture
		obj_sprite.texture.filter_clip = true
		
		if not obj_res.is_decoration:
			collision.polygon = obj_res.collision_shape
		else:
			z_index = -1
		
		if not in_level:
			obj_sprite.material = _selection_material
	
	if not obj_res.is_solid:
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, false)
		set_collision_layer_value(3, true)
	else:
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, true)
		set_collision_layer_value(3, false)
	
	if obj_res.trigger_id != 0:
		trigger = Trigger.create_trigger(obj_res.trigger_id, other["trigger"])
	

func select() -> void:
	if obj_sprite:
		obj_sprite.set_instance_shader_parameter("is_selected", true)

func deselect() -> void:
	if obj_sprite:
		obj_sprite.set_instance_shader_parameter("is_selected", false)

func check_editor_layer(new_layer : int) -> void:
	if new_layer == other.get("e_l", 0):
		pass

func get_selection_rect() -> Rect2:
	var points : PackedVector2Array = collision.polygon
	if points.is_empty():
		return Rect2().abs()
	
	var rect : Rect2 = Rect2(points[0], Vector2.ZERO)
	for i in range(1, points.size()):
		rect = rect.expand(points[i])
	
	return collision.get_global_transform() * rect.abs()
 
func _hide() -> void:
	if obj_res.is_scene and scene != null:
		scene_parent.remove_child(scene)
	elif not obj_res.is_scene:
		obj_sprite.hide()

func _show() -> void:
	if obj_res.is_scene and scene != null and scene.get_parent() == null:
		scene_parent.add_child(scene)
	elif not obj_res.is_scene:
		obj_sprite.show()

func delete() -> void:
	queue_free()
