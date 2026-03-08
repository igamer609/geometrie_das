# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

@tool

##Custom spinbox implementation for use in settings menus and in the editor.
##
##Uses two buttons as increment and decrement buttons, that when 
##pressed add or subtract [code]step[/code] from [code]value[/code].
##When the value is updated trough the intended methods (using the buttons/intenal [LineEdit] 
##or [code]setValue[/code]) the contents of the [LineEdit] automatically change.
##If the value is below [code]minimum_value[/code], displays [code]generic_term_text[/code].
##
class_name GDNumberSpin extends Control

signal value_changed(new_value : int)

@export var minimum_value : int = 0
@export var maximum_value : int = 999
@export var step : int = 1


@export_category("Cosmetic")
@export var generic_term_text : String
@export var placeholder_text : String = "..."
@export var arrow_color : Color = Color.WHITE

var value : int

var _decrement_button : AnimatedTextureButton
var _increment_button : AnimatedTextureButton
var _line_edit : LineEdit

func _ready() -> void:
	self.custom_minimum_size = Vector2(128, 50)
	
	_decrement_button = AnimatedTextureButton.new(); _decrement_button.texture_normal = load("res://Scenes/ui_elements/resources/arrow.atlastex")
	_decrement_button.flip_h = true; _decrement_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_decrement_button.set_anchors_preset(PRESET_LEFT_WIDE); 

	_increment_button = AnimatedTextureButton.new(); _increment_button.texture_normal = load("res://Scenes/ui_elements/resources/arrow.atlastex")
	_increment_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_increment_button.set_anchors_preset(PRESET_RIGHT_WIDE); 

	_line_edit = LineEdit.new(); _line_edit.flat = true
	_line_edit.set_anchors_preset(Control.PRESET_VCENTER_WIDE); _line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line_edit.theme = load("res://Assets/themes/label_theme.tres");  _line_edit.max_length = 3; _line_edit.add_theme_font_size_override("font_size", 30)
	_line_edit.context_menu_enabled = false; _line_edit.emoji_menu_enabled = false; _line_edit.shortcut_keys_enabled = false; _line_edit.select_all_on_focus = true;
	_line_edit.middle_mouse_paste_enabled = false; _line_edit.selecting_enabled = true; _line_edit.drag_and_drop_selection_enabled = false
	
	call_deferred("add_child", _decrement_button, false, Node.INTERNAL_MODE_FRONT)
	call_deferred("add_child", _increment_button, false, Node.INTERNAL_MODE_FRONT)
	call_deferred("add_child", _line_edit, false, Node.INTERNAL_MODE_FRONT)
	call_deferred("_setup_internal")

func _setup_internal() -> void:
	_decrement_button.size.x = 40; _increment_button.size.x = 40; _decrement_button.self_modulate = arrow_color; _increment_button.self_modulate = arrow_color
	_decrement_button.pressed.connect(decrement); _increment_button.pressed.connect(increment)
	_line_edit.set_size(Vector2(70.8, 32), true); _line_edit.text_submitted.connect(set_value)
	_line_edit.anchor_left = 0.2; _line_edit.anchor_right = 0.2; _line_edit.anchor_top = 0.2; _line_edit.anchor_bottom = 0.3
	
	_update_text()

func _update_text() -> void:
	if value < minimum_value:
		_line_edit.text = generic_term_text
		value = minimum_value - 1
	else:
		_line_edit.text = str(value)
	
	value_changed.emit(value)

func increment() -> void:
	value += step
	_update_text()

func decrement() -> void:
	value -= step
	_update_text()

func set_value(new_value : Variant) -> void:
	if new_value is String:
		if new_value.is_valid_int():
			value = int(new_value)
			_update_text()
	else:
		value = new_value
		if value > maximum_value:
			value = maximum_value
		_update_text()
