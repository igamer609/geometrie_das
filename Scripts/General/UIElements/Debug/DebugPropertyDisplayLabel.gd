class_name DebugPropertyLabel extends RichTextLabel

@export_enum("Integer", "Float", "Boolean", "String") var display_type: int = 0
@export var prop_name: String
@export var target: Node
@export var enabled: bool = true

var _last_value: Variant = null

func _ready() -> void:
	bbcode_enabled = true

func _process(_delta: float) -> void:
	if(!enabled || !target || !prop_name):
		return
	
	var current_value = target.get_indexed(prop_name)
	
	if(current_value == _last_value):
		return
	
	_last_value = current_value
	_update_display(current_value)

func _update_display(value: Variant) -> void:
	var color = _get_color_for_type()
	text = "%s: [color=%s]%s[/color]" % [name, color.to_html(), str(value)]

func _get_color_for_type() -> Color:
	match display_type:
		0, 1: return Color.AQUA
		2: return Color.GREEN if target.get(prop_name) else Color.RED
		3: return Color.LIGHT_YELLOW
	return Color.WHITE
