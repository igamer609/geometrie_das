# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends GPUParticles2D

#to be added to scene only on level end!

func _process(delta):
	global_position = get_parent().get_child(0).global_position
