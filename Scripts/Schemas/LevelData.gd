# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name LevelData extends Resource

@export var meta: LevelMeta
@export var objects: Array[LevelObject] = []

const INVALID_ID : int = -1

func _init() -> void:
	meta = LevelMeta.new()

func to_dict() -> Dictionary:
	var obj_dicts = []
	for obj in objects:
		obj_dicts.append(obj.to_dict())
	
	return {
		"meta": meta.to_dict(),
		"objects": obj_dicts
	}

func pack_to_str_json() -> String:
	
	var level_dict : Dictionary = self.to_dict()
	
	var level_obj_data : Dictionary = {
		"objects" : level_dict["objects"],
		"color_palette" : meta.color_palette.to_dict(),
		"song_offset" : meta.song_offset,
		"last_uid" : meta.last_uid,
		"starting_gamemode" : meta.starting_gamemode,
		"starting_gravity" : meta.starting_gravity
	}
	
	var level_data_buffer : PackedByteArray = JSON.stringify(level_obj_data).to_utf8_buffer()
	var b64_objects : String = Marshalls.raw_to_base64(level_data_buffer.compress(FileAccess.COMPRESSION_ZSTD))
	var final_dict = level_dict["meta"].merge({"level": b64_objects})
	
	return JSON.stringify(final_dict)

static func from_dict(data: Dictionary) -> LevelData:
	var level = LevelData.new()
   
	if data.has("info"):
		level.meta = LevelMeta.from_dict(data["info"].to_dict())
	elif data.has("meta"):
		level.meta = LevelMeta.from_dict(data["meta"].to_dict())
	if data.has("objects"):
		for obj_data in data["objects"]:
			level.objects.append(LevelObject.from_dict(obj_data))
	  
	return level

static func parse_from_api_body(res_body : Dictionary) -> LevelData:
	var level : LevelData = LevelData.new()
	
	level.meta.published_id = int(res_body.get("id", -1))
	level.meta.original_id = int(res_body.get("original_id", -1))
	level.meta.title = str(res_body.get("title", "Unnamed 0"))
	level.meta.description = str(res_body.get("description", ""))
	level.meta.author = str(res_body.get("author_name", "Player"))
	level.meta.song_id = int(res_body.get("song_id", 1))
	level.meta.length = float(res_body.get("length", 0.0))
	level.meta.version = str(res_body.get("version", "1.0"))

	level.meta.downloads = int(res_body.get("downloads", 0))
	level.meta.likes = int(res_body.get("likes", 0))
	level.meta.avg_rating = float(res_body.get("avg_rating", 0.0))
	level.meta.feature_level = int(res_body.get("feature_level", 0))

	level.meta.rating = int(level.meta.avg_rating)

	var raw_level_data = str(res_body.get("level_data", ""))

	if(!raw_level_data.is_empty()):
		var compressed_bytes : PackedByteArray = Marshalls.base64_to_raw(raw_level_data)
		var decompressed_bytes = compressed_bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_ZSTD)

		if(decompressed_bytes != null and not decompressed_bytes.is_empty()):
			var json_string : String = decompressed_bytes.get_string_from_utf8()
			var inner_data : Dictionary = JSON.parse_string(json_string)

			if inner_data is Dictionary:
				var raw_objects : Array = inner_data.get("objects", [])
				for obj_dict : Dictionary  in raw_objects:
					var new_obj : LevelObject = LevelObject.from_dict(obj_dict)
					level.objects.append(new_obj)

			level.meta.last_uid = int(inner_data.get("last_uid", 0))
			level.meta.song_offset = float(inner_data.get("song_offset", 0.0))
			level.meta.starting_gamemode = int(inner_data.get("starting_gamemode", 0))
			level.meta.starting_gravity = int(inner_data.get("starting_gravity", 1))

			var palette_dict : Dictionary = inner_data.get("color_palette", {})
			if(!palette_dict.is_empty()):
				level.meta.color_palette = GDColorPalette.from_incomplete_dict(palette_dict)

	return level
	
	
