extends Node2D

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
	
	_on_options_done()
	
# PLAY

func _on_play():
	var main = load("res://scenes/Main.tscn").instance()
	get_tree().get_root().add_child(main)
	queue_free()
	
# OPTIONS
	
func _on_options():
	$Foreground/Buttons.visible = false
	$Foreground/Options.visible = true
	$Foreground/StatusBox.visible = false
	

func _on_Music_toggled(button_pressed):
	global_options.music = button_pressed
	
func _on_Difficulty_item_selected(id):
	global_options.difficulty = global_options.DIFFICULTY_OPTIONS[id]
	
func _on_options_done():
	$Foreground/Buttons.visible = true
	$Foreground/Options.visible = false
	$Foreground/StatusBox.visible = true

# QUIT

func _on_quit():
	get_tree().quit()



	
