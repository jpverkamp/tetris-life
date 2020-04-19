extends Node2D

const MAX_BASE = 4

onready var Tetromino = preload("res://scenes/Tetromino.tscn")
onready var tetrominos = $Tetrominos
onready var engine = $PixelEngine
onready var score_count = $Scores/Count
onready var score_height = $Scores/Height

func spawn():
	var child = Tetromino.instance()
	child.init_random()
	child.name = "Tetromino" + str(tetrominos.get_child_count() + 1)
	child.position = Vector2(80, 20)
	child.connect("on_lock", self, "spawn")
	child.connect("on_reset", self, "reset_blocks")
	tetrominos.add_child(child)
	
func reset_sand():
	for x in range(engine.WIDTH):
		var wall_start = engine.HEIGHT - 1 - (randi() % MAX_BASE)
		for y in range(engine.HEIGHT):
			if y > wall_start:
				engine.data[x][y] = engine.CELL.wall
			elif y == wall_start:
				engine.data[x][y] = engine.CELL.plant
			else:
				engine.data[x][y] = engine.CELL.empty
		
	engine.force_update = true
	
func reset_blocks():
	for tetromino in tetrominos.get_children():
		tetromino.queue_free()
		tetrominos.remove_child(tetromino)
	spawn()
	
func _ready():
	OS.window_size = Vector2(320, 640)

	reset_sand()
	reset_blocks()

func _physics_process(_delta):
	OS.set_window_title("TETRIS SAND | FPS: " + str(Engine.get_frames_per_second()))
					
	if Input.is_action_just_pressed("ui_cancel"):
		reset_blocks()
		
func _on_Scores_timeout():
	var count = 0
	var highest = engine.HEIGHT
	
	for x in range(engine.WIDTH):
		for y in range(engine.HEIGHT):
			if engine.data[x][y] == engine.CELL.plant:
				count += 1
				highest = min(highest, y)
	
	score_count.text = "Plants: " + str(count)
	score_height.text = "Tallest: " + str(engine.HEIGHT - highest)
