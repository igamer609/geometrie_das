# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends CanvasLayer

func change_scene(scene_path) -> void:
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(scene_path)
	
	if get_tree().paused:
		get_tree().paused = false
	
	$AnimationPlayer.play_backwards("fade")

## Displays a message of varying importance. Message is formated based on it's severity.
## `severity` - 0 is a critical error, 1 is a warning and anything greater is feedback.
func show_message(msg : String, severity : int = 0) -> void:
	var message_label : Label = Label.new()
	message_label.text = msg
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.pivot_offset = message_label.size / 2
	message_label.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
	
	$MessageContainer.add_child(message_label)
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.anchor_left = 0; message_label.anchor_right = 1
	message_label.position = Vector2(message_label.position.x, 640)
	
	var tween = get_tree().create_tween().set_parallel()
	tween.set_meta("scope", 101)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(message_label, "position", Vector2(message_label.position.x, 520), 0.5)
	tween.tween_property(message_label, "self_modulate", Color(1, 1, 1, 1), 0.5)
	tween.finished.connect(_hide_message.bind(message_label))

func _hide_message(msg_label : Label) -> void:
	var tween = get_tree().create_tween()
	tween.set_meta("scope", 101)
	tween.tween_property(msg_label, "self_modulate", Color(1, 1, 1, 0), 0.5)
	tween.finished.connect(msg_label.queue_free)
