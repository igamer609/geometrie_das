# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name LevelData extends Resource

@export var meta: LevelMeta
@export var objects: Array[LevelObject] = []

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

func pack_to_json() -> String:
	
	var level_dict : Dictionary = self.to_dict()
	
	var level_obj_data : Dictionary = {
		"objects" : level_dict["objects"],
		"color_palette" : meta.color_palette.to_dict(),
		"song_offset" : meta.song_offset,
		"last_uid" : meta.last_uid,
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
