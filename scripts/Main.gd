extends Node2D

onready var Tetromino = preload("res://scenes/Tetromino.tscn")
onready var tetrominos = $Tetrominos

func spawn():
	var child = Tetromino.instance()
	child.init_random()
	child.name = "Tetromino" + str(tetrominos.get_child_count() + 1)
	child.position = Vector2(80, 20)
	child.connect("on_lock", self, "_on_lock")
	tetrominos.add_child(child)
	
func _ready():
	OS.window_size = Vector2(320, 640)
	
	var engine = $PixelEngine
	for x in range(engine.WIDTH):
		var wall_start = engine.HEIGHT - 1 - (randi() % 10)
		
		for y in range(wall_start, engine.HEIGHT - 1):
			engine.data[x][y] = engine.CELL.wall
			
		engine.data[x][wall_start - 1] = engine.CELL.plant
			
	engine.force_update = true
	
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
		
