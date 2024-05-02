extends GPUParticles2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = get_parent().get_child(0).global_position
