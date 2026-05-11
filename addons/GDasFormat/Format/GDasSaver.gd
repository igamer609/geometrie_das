# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name GDasSaver extends ResourceFormatSaver

func _recognize(resource: Resource) -> bool:
	return resource is LevelData || resource is LevelRegistry || resource is PlayerSaveData

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return PackedStringArray(["gdaslvl", "datreg", "save"])

func _save(resource: Resource, path: String, flags: int) -> Error:
	var raw_bytes : PackedByteArray = var_to_bytes_with_objects(resource)
	var compressed_data = raw_bytes.compress(FileAccess.COMPRESSION_ZSTD)
	
	var directory : DirAccess = DirAccess.open("user://")
	if(!directory):
		return directory.get_open_error()
	
	var has_old_file : Error = directory.copy(path, path + ".old")
	
	var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if((!file && has_old_file == OK)):
		return file.get_open_error()
	
	var check1 : bool = file.store_32(raw_bytes.size())
	var check2 : bool = file.store_buffer(compressed_data)
	file.close()
	
	assert(check1 && check2)
	
	if(check1 && check2):
		directory.remove(path + ".old")
	else:
		directory.rename(path + ".old", path)
		return Error.ERR_FILE_CANT_WRITE
	
	return OK
