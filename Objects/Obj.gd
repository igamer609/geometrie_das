# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Resource
class_name GD_Object

@export var id : int

@export var is_scene : bool
@export var scene : PackedScene

@export var texture : AtlasTexture
@export var collision_shape : PackedVector2Array

@export var is_solid : bool
@export var is_trigger : bool
