# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Button
class_name AnimatedButton

func _ready() -> void:
	pivot_offset = size / 2
	button_down.connect(_on_down)
	button_up.connect(_on_up)

func _on_down() -> void:
	var tween : Tween = create_tween()
	tween.set_meta("scope", 100)
	tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)

func _on_up() -> void:
	var tween : Tween = create_tween()
	tween.set_meta("scope", 100)
	tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
