extends Control

@export var exit_button : TextureButton

@export_category("Authentication")
@export var username_input : LineEdit
@export var password_input : LineEdit
@export var register_button : Button
@export var login_button : Button
@export var input_validation_message : Label

@export_category("Account Management")
@export var title_label : Label

@export_category("Panel Tabs")
@export var auth_tab : VBoxContainer
@export var account_tab : VBoxContainer

@export_category("Popup")
@export var auth_popup : Control
@export var popup_spinner : TextureRect
@export var popup_final_status : TextureRect
@export var popup_message : Label
@export var popup_close_button : TextureButton
@onready var popup_icon_anim : AnimationPlayer = $AuthPopup/IconAnimation

const auth_loading_messages : Array[String] = [
	"Sending request...",
	"Awaiting response...",
	"Authenticating...",
]

func _ready() -> void:
	register_button.pressed.connect(_on_register_pressed)
	popup_close_button.pressed.connect(_hide_popup)
	exit_button.pressed.connect(queue_free)
	
	_update_tab()

func _update_tab() -> void:
	if(PlayerData.data.account.get("user_id", 0) != 0):
		auth_tab.hide()
		title_label.text = "Welcome, " + PlayerData.data.account.get("username")
		account_tab.show()

func _show_popup() -> void:
	popup_close_button.hide()
	popup_message.text = auth_loading_messages[randi_range(0, auth_loading_messages.size() - 1)]
	popup_icon_anim.play("SpinLoadingIcon")
	auth_popup.show()

func _hide_popup() -> void:
	_update_tab()
	auth_popup.hide()

func _on_register_pressed() -> void:
	var account_details : Dictionary = _validate_account_information()
	
	if(!account_details):
		return
	
	_show_popup()
	
	var result : Dictionary = await API.sign_up(account_details["username"], account_details["password"])
	
	popup_close_button.show()
	
	if(result.get("success", false)):
		popup_icon_anim.play("SuccessIcon")
		popup_message.text = "Account created. Logged in!"
	else:
		popup_icon_anim.play("FailedIcon")
		popup_message.text = result.error.get("message", "Account creation failed.")

func _on_sign_in_pressed() -> void:
	var account_details : Dictionary = _validate_account_information()
	
	if(!account_details):
		return
	
	_show_popup()
	
	var result : Dictionary = await API.sign_in(account_details["username"], account_details["password"])
	
	popup_close_button.show()
	
	if(result.get("success", false)):
		popup_icon_anim.play("SuccessIcon")
		popup_message.text = "Logged in successfully!"
	else:
		popup_icon_anim.play("FailedIcon")
		popup_message.text = result.error.get("message", "Authentication failed.")

func _validate_account_information() -> Variant:
	
	var username : String = username_input.text
	var password : String = password_input.text
	
	var alphanumericRegEx : RegEx = RegEx.create_from_string("^[a-zA-Z0-9]+$")
	var whitespaceRegEx : RegEx = RegEx.create_from_string(" ")
	
	if(!alphanumericRegEx.search(username)):
		input_validation_message.text = "Username must only include alphanumeric characters."
		return null
	if(username.length() > 25):
		input_validation_message.text = "Username too long. Maximum length is 25 characters."
		return null
	if(username.length() < 3):
		input_validation_message.text = "Username too short. Minimum length is 3 characters."
		return null
	if(whitespaceRegEx.search(password)):
		input_validation_message.text = "Password must not include spaces."
	if(password.length() < 8):
		input_validation_message.text = "Password is too short. Minimum length is 8 characters."
		return null
	if(password.length() > 32):
		input_validation_message.text = "Password is too long. Maximum length is 32 characters."
		return null
	
	return {
		"username": username,
		"password": password
	}

#func _update_tab
