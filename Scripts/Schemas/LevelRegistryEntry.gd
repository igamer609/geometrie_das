# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name LevelRegistryEntry extends Resource

@export var meta : LevelMeta
@export var ref : String

func _init() -> void:
	meta = LevelMeta.new()
	ref = ""

func to_dict() -> Dictionary:
	return {
		"meta" : meta.to_dict(),
		"ref" : ref
	}

static func from_raw_dict(entry_dict : Dictionary) -> LevelRegistryEntry:
	var entry : LevelRegistryEntry = LevelRegistryEntry.new()
	
	if entry_dict.has("info"):
		entry_dict["meta"] = entry_dict["info"]
		entry_dict.erase("info")
	
	entry.meta = LevelMeta.from_dict(entry_dict["meta"])
	entry.ref = entry_dict["ref"]
	
	return entry

static func generate_entry(entry_meta : LevelMeta, entry_ref : String) -> LevelRegistryEntry:
	var entry : LevelRegistryEntry = LevelRegistryEntry.new()
	
	entry.meta = entry_meta
	entry.ref = entry_ref
	
	return entry
