extends Control

func _ready():
	$Button.pressed.connect(open_link.bind($Button.get_meta("MusicLink")))

func open_link(link):
	OS.shell_open(link)
