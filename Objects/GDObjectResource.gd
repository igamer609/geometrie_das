# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Resource
class_name GDObjectResource

@export var id : int

@export var scene : PackedScene

@export var texture : AtlasTexture
@export var collision_shape : PackedVector2Array

@export var type : Type

@export var default_channel : int = 1

func get_type() -> StringName:
	if(type):
		return type.type
	
	assert(type != null, "No type attached to object resource")
	return &"None"

func get_edit_menu() -> PackedScene:
	if(type):
		return ResourceLibrary.load_scene(type.edit_menu_path)
	
	return null
