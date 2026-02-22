# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name GDasSaver extends ResourceFormatSaver

func _recognize(resource: Resource) -> bool:
	return resource is LevelData || resource is LevelRegistry

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return PackedStringArray(["gdaslvl", "datreg"])

func _save(resource: Resource, path: String, flags: int) -> Error:
	var raw_bytes : PackedByteArray = var_to_bytes_with_objects(resource)
	var compressed_data = raw_bytes.compress(FileAccess.COMPRESSION_ZSTD)
	
	var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return file.get_open_error()
	
	file.store_32(raw_bytes.size())
	file.store_buffer(compressed_data)
	file.close()
	
	return OK
