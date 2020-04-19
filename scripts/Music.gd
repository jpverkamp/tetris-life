extends Node2D

onready var global_options = get_node("/root/Options")

func ping():
	if global_options.music:
		$AudioStreamPlayer.play()
	else:
		$AudioStreamPlayer.stop()

func _ready():
	ping()

func _on_AudioStreamPlayer_finished():
	ping()
