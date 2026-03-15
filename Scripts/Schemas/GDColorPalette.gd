# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name GDColorPalette extends Resource

static var DEFAULT_PALETTE : Dictionary[int, Color]= {
	0 : Color(0.119, 0.319, 1.0, 1.0),
	2 : Color(0.119, 0.319, 1.0, 1.0),
}

@export var length : int = 1
@export var color_palette : Array

static func from_incomplete_dict(dict : Dictionary) -> GDColorPalette:
	var new_palette : GDColorPalette = GDColorPalette.new()
	new_palette.color_palette = []

	for i in range(0, new_palette.length - 1):
		if(dict.has(i)):
			new_palette.color_palette[i] = dict[i]
		else:
			new_palette.color_palette[i] = Color.WHITE
	
	return new_palette

static func default_palette(_length : int) -> GDColorPalette:
	var _palette : GDColorPalette = GDColorPalette.new()
	_palette.color_palette = []
	
	_palette.length = _length
	for i in range(0, _length - 1):
		if(DEFAULT_PALETTE.has(i)):
			_palette.color_palette.append(DEFAULT_PALETTE[i])
		else:
			_palette.color_palette.append(Color.WHITE)
	
	return _palette

func set_channel(channel_id : int, color : Color) -> void:
	color_palette[channel_id] = color

func to_dict() -> Dictionary:
	var dict : Dictionary = {}
	
	for i in range(0, length - 1):
		if(color_palette[i] != Color.WHITE):
			dict[i] = color_palette[i].to_html(false)
	
	return dict
