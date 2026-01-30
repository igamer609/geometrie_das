# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends AudioStreamPlayer

@export var music_play = true

func _ready():
	$GameStart.visible = PlayerData.new

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
