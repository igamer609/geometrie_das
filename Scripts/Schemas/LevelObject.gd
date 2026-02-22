# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name LevelObject extends Resource

@export var obj_id: int = 0
@export var uid: int = 0
@export var transform: Array = []
@export var other: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"obj_id": obj_id,
		"uid": uid,
		"transform": transform,
		"other": other
	}

static func from_dict(data: Dictionary) -> LevelObject:
	var obj = LevelObject.new()
	
	obj.obj_id = data.get("obj_id", 1)
	obj.uid = data.get("uid", 0)
	obj.transform = data.get("transform", [])
	obj.other = data.get("other", {})
	
	return obj
