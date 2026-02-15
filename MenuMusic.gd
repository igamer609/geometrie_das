# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends AudioStreamPlayer

@export var music_play = true

func _ready():
	$GameStart.visible = PlayerData.new
	start_music()

func stop_music():
	stop()

func start_music():
	play()

func _quit_announcement():
	$GameStart.visible = false
