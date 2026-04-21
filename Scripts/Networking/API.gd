# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

#Note: responses given by the HTTPRequest node come in a strict structure, so res[3] will always be the body of the response.

extends Node

signal _account_changed(user_data : Dictionary)
signal _level_published(success : bool, level_id : int)

# Replace port with desired test port
var api_host : String = "http://localhost:3000"
var current_requests : Array[HTTPRequest] = []
var auth_header : PackedStringArray = []

func _ready() -> void:
	if(OS.has_feature("production")):
		pass #to be replaced with the url of the web server :3

func _create_request(threaded : bool = false) -> HTTPRequest:
	var http_request : HTTPRequest = HTTPRequest.new()
	http_request.use_threads = threaded
	current_requests.append(http_request)
	add_child(http_request)
	return http_request

func _send_request(path : String, method : HTTPClient.Method, body : String = "") -> Array:
	var http_request : HTTPRequest = _create_request()
	http_request.request(api_host + path, auth_header, method, body)
	var res = await http_request.request_completed
	http_request.queue_free()
	return res

# Methods for sending account related requests

func sign_up(username : String, password : String) -> Error:
	var req_body : String = JSON.stringify({
		"username": username,
		"password": password
	})
	
	var res = await _send_request( "/users/auth/signup", HTTPClient.METHOD_POST, req_body)
	
	if(res[0] != HTTPRequest.RESULT_SUCCESS):
		push_error("HTTP request to API failed with error code  " + str(res[0]))
		return ERR_CONNECTION_ERROR
	
	var parsed  : bool = _handle_sign_in(res[3])
	if(!parsed):
		return ERR_QUERY_FAILED
	return OK

func sign_in(username : String, password : String) -> Error:
	var req_body : String = JSON.stringify({
		"username": username,
		"password": password
	})
	
	var res = await _send_request( "/users/auth/signup", HTTPClient.METHOD_POST, req_body)
	
	if(res[0] != HTTPRequest.RESULT_SUCCESS):
		push_error("HTTP request to API failed with error code  " + str(res[0]))
		return ERR_CONNECTION_ERROR
	
	var parsed  : bool = _handle_sign_in(res[3])
	if(!parsed):
		return ERR_QUERY_FAILED
	return OK

# Methods for sending level related requests

func publish_level(level_data : LevelData) -> int:
	var http_req : HTTPRequest = _create_request()
	var req_body : String = level_data.pack_to_str_json()
	
	var res = await _send_request( "/levels/", HTTPClient.METHOD_POST, req_body)
	http_req.queue_free()
	
	if(res[0] != HTTPRequest.RESULT_SUCCESS):
		push_error("HTTP request to API failed with error code  " + str(res[0]))
		return ERR_CONNECTION_ERROR
	
	return _handle_published_level(res[3])

func get_full_level(level_id : int) -> LevelData:
	var res = await _send_request("/levels/" + str(level_id), HTTPClient.METHOD_GET)
	return _parse_full_level(res[3])

# Methods for handling responses

func _handle_sign_in(res : PackedByteArray) -> bool:
	
	var body_str : String = res.get_string_from_utf8()
	var body : Dictionary = JSON.parse_string(body_str)
	
	var success : bool = body.get("success", false)
	
	if(success):
		var username : String = body.username
		var user_id : int = body.user_id
		var token : String = body.token
		var token_header : String =  "authentication: Bearer " + token
		auth_header = [ token_header ]
		PlayerData._update_account(username, user_id, token)
	else:
		push_error(body.error.msg)
	
	return success

func _handle_published_level(res : PackedByteArray) -> int:
	
	var body_str : String = res.get_string_from_utf8()
	var body : Dictionary = JSON.parse_string(body_str)
	
	var success : bool = body.get("success", false)
	
	if(success):
		var level_id : int = body.id
		return level_id
	
	push_error(body.error.msg)
	return -1

func _parse_full_level(res : PackedByteArray) -> LevelData:
	
	var body_str : String = res.get_string_from_utf8()
	var body : Dictionary = JSON.parse_string(body_str)
	
	var success : bool = body.get("success", false)
	
	if(success):
		var level_data : LevelData = LevelData.parse_from_api_body(body)
		if(level_data.meta.published_id != LevelData.INVALID_ID):
			if(ResourceLibrary.current_registry.type != LevelRegistry.RegistryType.SAVED):
				ResourceLibrary.load_registry(LevelRegistry.RegistryType.SAVED)
			
			var level_ref : String = _save_parsed_level(level_data)
			if(level_ref.is_empty()):
				return null
			
			var reg_entry : LevelRegistryEntry = LevelRegistryEntry.generate_entry(level_data.meta, level_ref)
			if(!ResourceLibrary.current_registry.order.has(level_data.meta.published_id)):
				ResourceLibrary.current_registry.create_entry(str(level_data.meta.published_id), reg_entry)
			else:
				ResourceLibrary.current_registry.updade_entry(str(level_data.meta.published_id), reg_entry, true)
			
			return level_data
	
	return null

# Internal methods

func _save_parsed_level(level_data : LevelData) -> String:
	if not DirAccess.dir_exists_absolute("user://saved_levels/"):
		DirAccess.make_dir_absolute("user://saved_levels/")
	
	var path : String = "user://saved_levels/" + str( level_data.meta.published_id) + ".gdaslvl"
	var error : Error = ResourceSaver.save(level_data, path, ResourceSaver.FLAG_COMPRESS)
	
	if(error != OK):
		return ""
	
	return path

func _clear_auth_header() -> void:
	auth_header.clear()
