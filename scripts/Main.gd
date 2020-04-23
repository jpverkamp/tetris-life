extends Node2D

export var demo = false

const MAX_BASE = 4
const TARGET = {
	'Easy': 50,
	'Medium': 25,
	'Hard': 0
}

const MESSAGES = {
	'default': "Welcome to\nTETRIS LIFE!",
	'win': {
		'Easy': "IT'S ALIVE!\nYou WIN!\nMaybe try Medium?",
		'Medium': "IT'S ALIVE!\nTry Hard next time.",
		'Hard': "YOU WON ON HARD!\nYOU ARE AWSOME!"
	},
	'lose': {
		'Easy': "All the plants died!\nYou lost.\n:(",
		'Medium': "All the plants died!\nYou lost.\n:(",
		'Hard': "All the plants died!\nAre you sure you're\nready for Hard?"
	}
}

onready var options = get_node("/root/Options")
onready var Tetromino = preload("res://scenes/Tetromino.tscn")
onready var tetrominos = $Tetrominos
onready var engine = $PixelEngine
onready var score_count = $Scores/Count
onready var score_height = $Scores/Height

func spawn():
	var child = Tetromino.instance()
	child.init_random()
	child.name = "Tetromino" + str(tetrominos.get_child_count() + 1)
	child.position = Vector2(32 + randi() % (160 - 64), 20)
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
	var target_line = $TargetLine	
	target_line.points[0].y = TARGET[options.difficulty] * engine.SCALE
	target_line.points[1].y = TARGET[options.difficulty] * engine.SCALE
	
	for tetromino in tetrominos.get_children():
		tetromino.queue_free()
		tetrominos.remove_child(tetromino)
		
	spawn()
	
	# On hard mode, spawn two at once
	if options.difficulty == 'Hard':
		$HardSpawnTimer.start()
		
func _ready():
	reset_sand()
	reset_blocks()
	
func return_to_menu(message):
	var menu = load("res://scenes/Menu.tscn").instance()
	menu.set_text(message)
	get_tree().get_root().add_child(menu)
	queue_free()
	
func _physics_process(_delta):
	OS.set_window_title("TETRIS LIFE | FPS: " + str(Engine.get_frames_per_second()))
	
	if not demo and Input.is_action_just_pressed("ui_cancel"):
		return_to_menu(MESSAGES['default'])
		
func _on_Scores_timeout():
	var count = 0
	var highest = engine.HEIGHT
	
	for x in range(engine.WIDTH):
		for y in range(engine.HEIGHT):
			if engine.data[x][y] == engine.CELL.plant:
				count += 1
				highest = min(highest, y)
				
	if count == 0:
		if demo:
			reset_sand()
		else:
			return_to_menu(MESSAGES['lose'][options.difficulty])

	elif highest <= TARGET[options.difficulty]:
		if demo:
			reset_sand()
		else:
			return_to_menu(MESSAGES['win'][options.difficulty])
		
	else:
		score_count.text = "Plants: " + str(count)
		score_height.text = "Tallest: " + str(engine.HEIGHT - highest)
