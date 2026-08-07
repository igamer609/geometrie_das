# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name Type
extends Resource

@export var type : StringName = &"None"
@export_file() var edit_menu_path : String = "res://Scenes/Menus/ObjectEditing/GenericObjectEdit.tscn"

@export_category("Properties")
@export var is_solid : bool
@export var is_scene : bool
@export var is_special : bool
@export var is_portal : bool
@export var is_decoration : bool 
@export var is_trigger : bool
