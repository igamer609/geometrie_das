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
	
	entry.meta = LevelMeta.from_dict(entry_dict["meta"])
	entry.ref = entry_dict["ref"]
	
	return entry

static func generate_entry(entry_meta : LevelMeta, entry_ref : String) -> LevelRegistryEntry:
	var entry : LevelRegistryEntry = LevelRegistryEntry.new()
	
	entry.meta = entry_meta
	entry.ref = entry_ref
	
	return entry
