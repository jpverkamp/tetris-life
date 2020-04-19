extends Node2D

onready var Tetromino = preload("res://scenes/Tetromino.tscn")
onready var tetrominos = $Tetrominos

func spawn():
	print('Spawning a new block')
	
	var child = Tetromino.instance()
	child.init_random()
	child.name = "Tetromino" + str(tetrominos.get_child_count() + 1)
	child.position = Vector2(80, 20)
	child.connect("on_lock", self, "_on_lock")
	tetrominos.add_child(child)
	
func _ready():
	OS.window_size = Vector2(320, 640)
	spawn()

func _on_lock():
	spawn()

func _physics_process(delta):
	OS.set_window_title("TETRIS SAND | FPS: " + str(Engine.get_frames_per_second()))
	
	if Input.is_action_just_pressed("ui_cancel"):
		for tetromino in tetrominos.get_children():
			tetromino.queue_free()
			tetrominos.remove_child(tetromino)
		spawn()
		
