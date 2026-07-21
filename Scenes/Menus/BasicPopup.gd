extends Control

@export var ok : Button

func _ready() -> void:
	ok.pressed.connect(_exit)

func _exit() -> void:
	queue_free()
