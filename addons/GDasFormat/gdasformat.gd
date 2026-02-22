# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

@tool
extends EditorPlugin

var saver = preload("res://addons/GDasFormat/Format/GDasSaver.gd")
var loader = preload("res://addons/GDasFormat/Format/GDasLoader.gd")

func _enter_tree():
	ResourceSaver.add_resource_format_saver(saver)
	ResourceLoader.add_resource_format_loader(loader)

func _exit_tree():
	ResourceSaver.remove_resource_format_saver(saver)
	ResourceLoader.remove_resource_format_loader(loader)
