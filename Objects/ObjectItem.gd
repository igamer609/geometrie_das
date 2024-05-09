extends StaticBody2D

signal selected(obj)

@export var obj_res : GD_Object

@onready var vis_notif = $VisibilityNotifier
@onready var anim_player = $AnimationPlayer

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
	
	if not obj_res.is_solid:
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, false)
		set_collision_layer_value(3, true)
	else:
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, true)
		set_collision_layer_value(3, false)

func enable_transition():
	visible = false
	
	vis_notif.screen_entered.connect(anim_player.play.bind("load1"))
	vis_notif.screen_exited.connect(anim_player.play_backwards.bind("load1"))
