# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name GDObject extends StaticBody2D

@export_category("Object Data")
@export var obj_res : GDObjectResource

@export_category("Runtime Properties")
@export var uid : int
@export var other : Dictionary
@export var in_level : bool = false
@export var group_ids : Array = []
@export var editor_layer : int = -1
@export var color_channel : int = 1
@export var is_selected : bool = false

var material_cache : MaterialCache

var scene : Node2D = null
var obj_sprite : Sprite2D = null
var collision : CollisionPolygon2D = null
var scene_parent : Node2D = null
var visibility_notifier : VisibleOnScreenNotifier2D = null

var trigger : Trigger = null

static func create_object(obj_id : int, n_uid : int, pos : Vector2, rot : float, n_other : Dictionary, n_material_cache, _in_level : bool = false) -> GDObject:
	var res : GDObjectResource = ResourceLibrary.library[obj_id]
	var object : GDObject = GDObject.new()
	object.add_to_group("Object")
	
	object.obj_res = res
	object.uid = n_uid
	object.global_position = pos
	object.global_rotation = rot
	object.group_ids = n_other.get("group_ids", [])
	object.editor_layer = n_other.get("editor_layer", 0)
	object.color_channel = n_other.get("channel_id", res.default_channel)
	if object.editor_layer < 0:
		object.editor_layer = 0
	var updated_other : Dictionary = n_other.duplicate(true)
	updated_other.set("group_ids", object.group_ids)
	updated_other.set("editor_layer", object.editor_layer)
	updated_other.set("channel_id", object.color_channel)
	object.other = updated_other
	object.in_level = _in_level
	
	object.material_cache = n_material_cache
	
	return object

static func duplicate_object(original_obj : GDObject, n_uid : int, new_pos : Vector2, new_rot : float) -> GDObject:
	var object : GDObject = GDObject.new()
	object.add_to_group("Object")
	
	object.obj_res = original_obj.obj_res
	object.uid = n_uid
	object.global_position = new_pos
	object.global_rotation = new_rot
	object.group_ids = original_obj.group_ids
	object.editor_layer = original_obj.editor_layer
	object.color_channel = original_obj.color_channel
	if object.editor_layer < 0:
		object.editor_layer = 0
	var updated_other : Dictionary = original_obj.other.duplicate(true)
	updated_other.set("group_ids", object.group_ids)
	updated_other.set("editor_layer", object.editor_layer)
	updated_other.set("channel_id", object.color_channel)
	object.other = updated_other
	object.in_level = original_obj.in_level
	
	object.material_cache = original_obj.material_cache
	
	return object

func _ready() -> void:
	if obj_res:
		update()
	
		ResourceLibrary.free_objects.connect(delete)
		
		if(!visibility_notifier):
			visibility_notifier = VisibleOnScreenNotifier2D.new()
			visibility_notifier.rect = Rect2i(8, 8, 10, 10)
			
			visibility_notifier.screen_entered.connect(_show)
			visibility_notifier.screen_exited.connect(_hide)
			add_child(visibility_notifier)
			
			if(!visibility_notifier.is_on_screen()):
				_hide()
			else:
				_show()

func update() -> void:
	if not in_level or (not obj_res.is_decoration and in_level and not obj_res.is_scene):
		collision = CollisionPolygon2D.new()
		add_child(collision)
		collision.position = Vector2(8, 8)
		collision.polygon = obj_res.collision_shape
	
	if not obj_res.is_scene:
		if not (in_level and obj_res.trigger_id != 0):
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
		
		var sprite : Sprite2D = scene.find_child("Sprite")
		if sprite:
			obj_sprite = sprite
	else:
		if obj_sprite:
			obj_sprite.texture = obj_res.texture
			obj_sprite.texture.filter_clip = true
		
		if not obj_res.is_decoration:
			collision.polygon = obj_res.collision_shape
		else:
			z_index = -1
	
	if not obj_res.is_solid:
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, false)
		set_collision_layer_value(3, true)
	else:
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, true)
		set_collision_layer_value(3, false)
	
	if obj_res.trigger_id != 0:
		trigger = Trigger.create_trigger(obj_res.trigger_id, other, !in_level)
		add_child(trigger)

func select() -> void:
	is_selected = true
	if(obj_sprite && obj_sprite.material):
		var selection_material : ShaderMaterial = obj_sprite.material.duplicate()
		selection_material.set_shader_parameter("is_selected", true)
		obj_sprite.material = selection_material

func deselect() -> void:
	is_selected = false
	if obj_sprite:
		obj_sprite.material = material_cache.get_material(color_channel, editor_layer)

func check_editor_layer(new_layer : int) -> void:
	if new_layer == other.get("e_l", 0):
		pass

func update_color_channel() -> void:
	if(obj_sprite):
		obj_sprite.material = material_cache.get_material(color_channel, editor_layer)

func get_selection_rect() -> Rect2:
	var points : PackedVector2Array = collision.polygon
	if points.is_empty():
		return Rect2().abs()
	
	var rect : Rect2 = Rect2(points[0], Vector2.ZERO)
	for i in range(1, points.size()):
		rect = rect.expand(points[i])
	
	return collision.get_global_transform() * rect.abs()
 
func _hide() -> void:
	
	if(obj_sprite):
			obj_sprite.hide()
			obj_sprite.material = null
	
	if obj_res.is_scene and scene != null:
		scene_parent.remove_child(scene)
	elif not obj_res.is_scene:
		if(obj_sprite):
			call_deferred("remove_child", obj_sprite)
		if(collision):
			collision.disabled = true

func _show() -> void:
	if obj_res.is_scene and scene != null and scene.get_parent() == null:
		scene_parent.add_child(scene)
	elif(obj_sprite):
		call_deferred("add_child", obj_sprite)
	
	if(obj_sprite):
		if not in_level:
			obj_sprite.material = material_cache.get_material(color_channel, 0)
		else:
			obj_sprite.material = material_cache.get_material(color_channel, editor_layer)
		
		if(is_selected):
			var selection_material : ShaderMaterial = obj_sprite.material.duplicate()
			selection_material.set_shader_parameter("is_selected", true)
			obj_sprite.material = selection_material
		
		obj_sprite.show()
		
		if(collision):
			collision.disabled = false

func delete() -> void:
	if(scene_parent):
		scene.queue_free()
	if(obj_sprite):
		obj_sprite.queue_free()
	queue_free()
