# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Control

func _ready():
	$Button.pressed.connect(open_link.bind($Button.get_meta("MusicLink")))

func open_link(link):
	OS.shell_open(link)
