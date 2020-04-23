extends Node2D

onready var options = get_node("/root/Options")

func ping():
	if options.music:
		$AudioStreamPlayer.play()
	else:
		$AudioStreamPlayer.stop()

func _ready():
	ping()

func _on_AudioStreamPlayer_finished():
	ping()
