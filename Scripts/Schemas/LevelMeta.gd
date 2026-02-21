class_name LevelMeta extends Resource

@export var title: String = ""
@export var author: String = ""
@export var description: String = ""
@export var song_id: int = 1
@export var length: float = 0.0

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
@export var bg_color: Color = Color("0045e1")
@export var last_uid: int = 0
@export var song_offset: float = 0.0
@export var verified: int = 0

func to_dict() -> Dictionary:
	return {
		"title": title,
		"author": author,
		"description": description,
		"song_id": song_id,
		"length": length,

		"local_id": local_id,
		"published_id": published_id,
		"original_id": original_id,
		"version": version,

		"downloads": downloads,
		"likes": likes,
		"avg_rating": avg_rating,
		"rating": rating,
		"feature_level": feature_level,

		"bg_color": bg_color.to_html(), 
		"last_uid": last_uid,
		"song_offset": song_offset,
		"verified": verified
	}

static func from_dict(data: Dictionary) -> LevelMeta:
	var meta = LevelMeta.new()
	for key in data:
		if key in meta:
			meta.set(key, data[key])
	return meta
