extends Control

#============Defining create nodes===============#
@onready var name_box = $LevelDisplay/Create/Title
@onready var author_box = $LevelDisplay/Create/Author
#==Difficulty==#
@onready var difficulty_radio = $LevelDisplay/Create/DifficultyRadio
@onready var difficulty_rect = $LevelDisplay/Create/Difficulty
#===Create level button===#
@onready var edit_button = $LevelDisplay/Create/Edit

#=========Default level data=========#
var level_data = {
	"name" : "",
	"author" : "",
	"difficulty" : 0,
	"version" : 1.1,
	"song_id" : 0,
	"bg_color" : Color("0045e1"),
	"objects" : []
}

var text_box_limit = ["$", "#", "@", "!", "%", "^", "&", "*", "(", ")", "'", '"']

func _ready():
	setup_difficulty_buttons()
	setup_text_boxes()
	setup_tab_buttons()
	
	edit_button.pressed.connect(create_level)

func setup_difficulty_buttons():
	var group = ButtonGroup.new()
	for button in difficulty_radio.get_children():
		button.button_group = group
		if button.name == "0":
			button.button_pressed = true
	
	group.pressed.connect(change_level_difficulty)

func change_level_difficulty(button):
	var difficulty_id = int(str(button.name))
	
	level_data["difficulty"] = difficulty_id
	difficulty_rect.texture.region = Rect2(Vector2(difficulty_id * 31, 0), Vector2(31, 32))
	print(difficulty_id)

func check_text(text):
	var text_array = []
		
	for letter in text:
		text_array.append(letter)
	
	for letter in text_array:
		if letter in text_box_limit:
			text_array.erase(letter)
	
	var checked_text = ""
	
	for letter in text_array:
		checked_text += letter
	
	return checked_text

func setup_text_boxes():
	name_box.text_changed.connect(change_level_name)
	author_box.text_changed.connect(change_level_author)

func change_level_name(lvl_name):
	if lvl_name:
		var checked_name = check_text(lvl_name)
		
		level_data["name"] = checked_name
		print("new name: " + checked_name)
		
		if name_box.text != checked_name:
			name_box.text = checked_name
			name_box.caret_column = len(checked_name)

func change_level_author(author):
	if author:
		var checked_author = check_text(author)
		
		level_data["author"] = checked_author
		print("new author: " + checked_author)
		
		if author_box.text != checked_author:
			author_box.text = checked_author
			author_box.caret_column = len(checked_author)

func create_level():
	if level_data["name"] == "":
		level_data["name"] = "Untitled " + str(get_instance_id())
	if level_data["author"] == "":
		level_data["author"] = "-"
	
	EditorTransition.load_editor(level_data)

func reset_create_tab():
	name_box.text = ""
	author_box.text = ""
	setup_difficulty_buttons()
	change_level_difficulty(difficulty_radio.get_child(0))
	
	$LevelDisplay/Unloaded.visible = false
	$LevelDisplay/Create.visible = true

func setup_tab_buttons():
	for button in $TabContainer.get_children():
		if button.name == "Create":
			button.pressed.connect(reset_create_tab)
