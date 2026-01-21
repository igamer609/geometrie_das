# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends ParallaxBackground

var rng = RandomNumberGenerator.new()

func _ready():
	change_hue()

func change_hue():
	for sprite in $ParallaxLayer.get_children():
		sprite.modulate = Color.from_hsv(rng.randf(), 1, 1, 1)
		rng.randomize()

func _process(delta):
	scroll_offset.x -= 60 * delta
