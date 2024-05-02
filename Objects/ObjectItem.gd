extends StaticBody2D

signal selected(obj)

@export var obj_res : GD_Object

var vis_notif = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if obj_res:
		update()

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			print("selected")
			emit_signal("selected", self)

func update():
	if obj_res.is_scene:
		var obj_scene = obj_res.scene.instantiate()
		obj_scene.position = Vector2(8, 8)
		obj_scene.name = "Scene"
		
		obj_scene.input_event.connect(_input_event)
		
		add_child(obj_scene)
	else:
		$Sprite.texture = obj_res.texture
		$Collision.polygon = obj_res.collision_shape

