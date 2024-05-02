extends AudioStreamPlayer

@export var music_play = true

func _ready():
	$GameStart.visible = true

func stop_music():
	music_play = false

func start_music():
	music_play = true

func _process(_delta):
	if music_play and not playing:
		play()
	elif not music_play and playing:
		stop()

func _quit_announcement():
	$GameStart.visible = false
