# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name GDasLoader extends ResourceFormatLoader

func _recognize(resource: Resource) -> bool:
	return resource is LevelData || resource is LevelRegistry

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["gdaslvl", "datreg"])

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return file.get_open_error()
	
	var buffer_size : int = file.get_32()
	var buffer = file.get_buffer(buffer_size)
	
	var raw_bytes = buffer.decompress(buffer_size, FileAccess.COMPRESSION_ZSTD)
	
	return bytes_to_var_with_objects(raw_bytes)
