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
	spawn()

func _on_lock():
	spawn()
