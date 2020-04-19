extends Node2D

onready var global_music = get_node("/root/Music")
onready var global_options = get_node("/root/Options")

func set_text(text):
	$Foreground/StatusBox/Status.text = text

func _ready():
	OS.window_size = Vector2(320, 640)
	$Background.demo = true
	
	var difficulty_menu = $Foreground/Options/Stacking/Difficulty
	for text in global_options.DIFFICULTY_OPTIONS:
		difficulty_menu.add_item(text)
	difficulty_menu.select(global_options.DIFFICULTY_OPTIONS.find(global_options.difficulty))
	
	_on_done()
	
func hide_all():
	$Foreground/StatusBox.visible = false
	$Foreground/Buttons.visible = false
	$Foreground/Options.visible = false
	$Foreground/Help.visible = false
	
	$Background/Scores/Count.visible = false
	$Background/Scores/Height.visible = false
	
# PLAY

func _on_play():
	var main = load("res://scenes/Main.tscn").instance()
	get_tree().get_root().add_child(main)
	queue_free()
	
# OPTIONS
	
func _on_options():
	hide_all()
	$Foreground/Options.visible = true
	
func _on_Music_toggled(button_pressed):
	global_options.music = button_pressed
	global_music.ping()
	
func _on_Experimental_toggled(button_pressed):
	global_options.experimental = button_pressed
	
func _on_Difficulty_item_selected(id):
	global_options.difficulty = global_options.DIFFICULTY_OPTIONS[id]
	
func _on_done():
	hide_all()
	
	$Foreground/StatusBox.visible = true
	$Foreground/Buttons.visible = true
	
	$Background/Scores/Count.visible = true
	$Background/Scores/Height.visible = true
	
# HELP

func _on_Help_pressed():
	hide_all()
	$Foreground/Help.visible = true
	
# QUIT

func _on_quit():
	get_tree().quit()



	


