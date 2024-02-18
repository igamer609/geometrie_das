extends ParallaxBackground

var rng = RandomNumberGenerator.new()

func _ready():
	change_hue()

func change_hue():
	for sprite in $ParallaxLayer.get_children():
		sprite.material.set_shader_parameter("Shift_Hue", rng.randf_range(0, 1))

func _process(delta):
	scroll_offset.x -= 0.5
