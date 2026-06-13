extends Control

@onready var channel_container : HBoxContainer = $Panel/MainChannels
@onready var gamemode_tabs : HBoxContainer = $Panel/Gamemode
@onready var song_label : Label = $Panel/SongPicker/Label
@onready var next_song : AnimatedTextureButton = $Panel/SongPicker/Next
@onready var prev_song : AnimatedTextureButton = $Panel/SongPicker/Prev
@onready var ok_button : AnimatedButton = $Panel/OK

@onready var flipped_gravity_check : CheckBox = $Panel/Other/ScrollContainer/VBoxContainer/flipped_gravity

@export var level : LevelMeta

func _ready() -> void:
	
	if(!level):
		push_error("Level metadata resource not loaded. Check if it's initialized before _ready")
		self.queue_free()
		return
	
	for channel : GDChannelButton in channel_container.get_children():
		channel.button.pressed.connect(_edit_channel.bind(channel.channel_id))
	
	var gamemode_tab_group : ButtonGroup = ButtonGroup.new()
	for tab : AnimatedTextureButton in gamemode_tabs.get_children():
		tab.button_group = gamemode_tab_group
		if(tab.name.trim_suffix("Tab") == ResourceLibrary.GAMEMODES[level.starting_gamemode]):
			tab.button_pressed = true
	gamemode_tab_group.pressed.connect(_set_gamemode)
	
	next_song.pressed.connect(_next_song)
	prev_song.pressed.connect(_prev_song)
	_update_song_label()
	
	if(level.starting_gravity == -1):
		flipped_gravity_check.button_pressed = true
	flipped_gravity_check.toggled.connect(_toggle_gravity)
	
	ok_button.pressed.connect(self.queue_free)

func _edit_channel(channel_id : int) -> void:
	var edit_menu : Control = ResourceLibrary.scenes["ChannelEditMenu"].instantiate()
	edit_menu.channel_id = channel_id
	add_child(edit_menu)

func _next_song() -> void:
	level.song_id += 1
	if(level.song_id > ResourceLibrary.song_ids.size()):
		level.song_id = 1
	_update_song_label()

func _prev_song() -> void:
	level.song_id -= 1
	if(level.song_id < 1):
		level.song_id = ResourceLibrary.song_ids.size()
	_update_song_label()

func _update_song_label() -> void:
	song_label.text = str(level.song_id) + ". " + ResourceLibrary.song_ids[level.song_id][1]

func _set_gamemode(gamemode_button : AnimatedTextureButton) -> void:
	var gamemode : String = gamemode_button.name.trim_suffix("Tab")
	match gamemode:
		"Cube": level.starting_gamemode = 0
		"Ship": level.starting_gamemode = 1
		"Ball": level.starting_gamemode = 2
		_: level.starting_gamemode = 0

func _toggle_gravity(val : bool) -> void:
	if(val): level.starting_gravity = -1
	else: level.starting_gravity = 1
