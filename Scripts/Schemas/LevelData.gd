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
