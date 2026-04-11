# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name LevelMeta extends Resource

@export var title: String = ""
@export var author: String = ""
@export var description: String = ""
@export var song_id: int = 1
@export var length: float = 0.0
@export var rate_req: int = 0

@export_category("Internal")
@export var local_id: String = ""
@export var published_id: int = -1
@export var original_id: int = -1
@export var version: String = str(ProjectSettings.get_setting("application/config/version.release"))

@export_category("Stats")
@export var downloads : int = 0
@export var likes : int = 0
@export var avg_rating : float = 0
@export var rating : int = 0
@export var feature_level : int = 0

@export_category("Editor")
@export var color_palette : GDColorPalette = GDColorPalette.default_palette(ColorManager.max_channels)
@export var last_uid: int = 0
@export var song_offset: float = 0.0
@export var verified: int = 0

func to_dict() -> Dictionary:
	return {
		"title": title,
		"description": description,
		"song_id": song_id,
		"length": length,
		"rate_req": rate_req,
		"original_id": original_id,
		"version": version,
	}

static func from_dict(data: Dictionary) -> LevelMeta:
	var meta = LevelMeta.new()
	for key in data:
		if key in meta:
			meta.set(key, data[key])
	return meta
