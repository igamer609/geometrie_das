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
	return(http_request)

# Methods for sending requests

func sign_up(username : String, password : String) -> Error:
	var http_request : HTTPRequest = _create_request()
	var req_data : String = JSON.stringify({
		"username": username,
		"password": password
	})
	
	http_request.request(api_host + "/users/auth/signup", auth_header, HTTPClient.METHOD_POST, req_data)
	var res = await http_request.request_completed
	http_request.queue_free()
	
	if(res[0] != HTTPRequest.RESULT_SUCCESS):
		push_error("HTTP request to API failed with error code  " + str(res[0]))
		return ERR_CONNECTION_ERROR
	
	var parsed  : bool = _handle_sign_in(res[3])
	if(!parsed):
		return ERR_QUERY_FAILED
	return OK

func sign_in(username : String, password : String) -> Error:
	var http_request : HTTPRequest = _create_request()
	var req_data : String = JSON.stringify({
		"username": username,
		"password": password
	})
	
	http_request.request(api_host + "/users/auth/signin", auth_header, HTTPClient.METHOD_POST, req_data)
	var res = await http_request.request_completed
	http_request.queue_free()
	
	if(res[0] != HTTPRequest.RESULT_SUCCESS):
		push_error("HTTP request to API failed with error code  " + str(res[0]))
		return ERR_CONNECTION_ERROR
	
	var parsed  : bool = _handle_sign_in(res[3])
	if(!parsed):
		return ERR_QUERY_FAILED
	return OK

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
