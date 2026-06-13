class_name MaterialCache extends RefCounted

var base_material : ShaderMaterial = preload("res://Assets/materials/ObjectMaterial.tres")

var materials : Dictionary = {}

func get_material(channel_id : int, editor_layer : int) -> ShaderMaterial:
	
	var material_key : String = str(channel_id) + ":" + str(editor_layer)
	
	if(materials.has(material_key)):
		return materials.get(material_key, base_material)
	
	var new_material = base_material.duplicate()
	new_material.set_shader_parameter("channel_id", channel_id)
	new_material.set_shader_parameter("editor_layer", editor_layer)
	
	materials[material_key] = new_material
	
	return new_material

func clear_cache() -> void:
	materials.clear()
