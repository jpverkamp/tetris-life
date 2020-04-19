extends Node2D

export var WIDTH = 16
export var HEIGHT = 16

const IMAGE_FORMAT = Image.FORMAT_RGBA8

var my_image
var my_texture
var mouse_down = false
var neighbors = {
	'top': null,
	'left': null,
	'right': null,
	'bottom': null
}

enum CELL {
	empty,
	wall,
	sand,
	cloud,
	water,
	plant,
	torch,
	fire
}

const COLORS = {
	CELL.empty: Color(0,    0,    0),
	CELL.wall:  Color(0.5,  0.5,  0.5),
	CELL.sand:  Color(0.76, 0.70, 0.50),
	CELL.cloud: Color(0.8,  0.8,  0.8),
	CELL.water: Color(0,    0,    1.0),
	CELL.plant: Color(0,    0.75, 0),
	CELL.torch: Color(0.75, 0.33, 0.33),
	CELL.fire:  Color(1.0,  0,    0),
}

# Particles a frame can start with and percent to fill with that
const INITABLE = [CELL.sand, CELL.water, CELL.fire, CELL.cloud, CELL.plant]
const INIT_CHANCE = 0.25

# Number of particles to randomly try to update each frame
var UPDATES_PER_FRAME = WIDTH * HEIGHT / 8

# Types that move up/down/left and right respective
const RISING = [CELL.cloud, CELL.fire] 					# Types that try to move up
const FALLING = [CELL.sand, CELL.water] 				# Types that try to move down
const SPREADING = [CELL.cloud, CELL.fire, CELL.water] 	# Types that try to move side to side

# Types that randomly disappear
const DESPAWN_CHANCE = 0.1
const DESPAWNING = [CELL.cloud, CELL.fire]

# Types that may spawn new particles
const SPAWN_CHANCE_PER_EMPTY = 0.05
const SPAWNING = {
	CELL.cloud: CELL.water,
	CELL.torch: CELL.fire
}

# Other constants
const BURN_CHANCE_PER_FIRE = 0.1
const GROW_CHANCE_PER_PLANT = 0.1

onready var sprite = $PixelEngine
onready var shape = $"../CollisionShape"
var data = []
var updated = []

func _ready():
	# Choose a random type to spawn
	var random_type = INITABLE[randi() % INITABLE.size()]
	
	# Create an empty matrix of data cells and update flags
	for x in range(WIDTH):
		data.append([])
		updated.append([])
		for _y in range(HEIGHT):
			# TODO: various spawns
			if randf() < INIT_CHANCE:
				data[x].append(random_type)
			else:
				data[x].append(CELL.empty)

			updated[x].append(false)
			
	# Create the image we will actually draw to
	my_image = Image.new()
	my_image.create(WIDTH, HEIGHT, false, IMAGE_FORMAT)
	
	# Create a texture that the image will render to and that we can use on this sprite
	my_texture = ImageTexture.new()
	my_texture.create_from_image(my_image)
	
	# Render initial data
	my_image.lock()
	for x in range(WIDTH):
		for y in range(HEIGHT):
			my_image.set_pixel(x, y, COLORS[data[x][y]])
	my_image.unlock()
	
	sprite.set_texture(my_texture)
	sprite.region_rect = Rect2(0, 0, WIDTH, HEIGHT)
	
	sprite.set_process_input(true)
	
func in_range(x, y):
	return (
		x >= 0 
		and x < WIDTH
		and y >= 0
		and y < HEIGHT
	)
	
func count_neighbors_of(x, y, type):
	var count = 0
	
	for xi in range(x - 1, x + 2):
		for yi in range(-1, 2):
			if not in_range(xi, yi) or (xi == x and yi == y):
				continue
				
			if data[x][y] == type:
				count += 1
	
	return count
	
func _process(_delta):
	# Reset the update map
	for x in range(WIDTH):
		for y in range(HEIGHT):
			updated[x][y] = false
			
	# Update a number of pixels at random
	for _i in range(UPDATES_PER_FRAME):
		var x = randi() % WIDTH
		var y = randi() % HEIGHT
		
		if updated[x][y]:
			continue
			
		var current = data[x][y]
		
		# Try to react with neighboring particles
		if current == CELL.plant:
			if randf() < count_neighbors_of(x, y, CELL.fire) * BURN_CHANCE_PER_FIRE:
				data[x][y] = CELL.fire
				updated[x][y] = true
		elif current == CELL.fire:
			if count_neighbors_of(x, y, CELL.water) > 0:
				data[x][y] = CELL.cloud
				updated[x][y] = true
		elif current == CELL.water:
			if randf() < count_neighbors_of(x, y, CELL.plant) * GROW_CHANCE_PER_PLANT:
				data[x][y] = CELL.plant
				updated[x][y] = true
		
		# Potentially spawn
		current = data[x][y]
		if current in SPAWNING:
			for xi in range(x - 1, x + 2):
				for yi in range(x - 1, y + 2):
					if not in_range(xi, yi) or (xi == x and yi == y):
						continue
						
					if data[xi][yi] != CELL.empty:
						continue
						
					if randf() > SPAWN_CHANCE_PER_EMPTY:
						continue
					
					data[xi][yi] = SPAWNING[current]
					updated[xi][yi] = true
			
		# Potentially despawn
		current = data[x][y]
		if current in DESPAWNING:
			if randf() < DESPAWN_CHANCE:
				data[x][y] = CELL.empty
				updated[x][y] = true
		
		# Try to move
		current = data[x][y]
		var options = []
		if current in RISING:
			options += [Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)]
		if current in FALLING:
			options += [Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]
		if current in SPREADING:
			options += [Vector2(-1, 0), Vector2(1, 0)]
		options.shuffle()
		
		var src_rotation = (360 + int(sprite.get_parent().get_parent().rotation_degrees)) % 360
		var sand_rotations = 0
		
		if src_rotation >= 315 or src_rotation <= 45:
			sand_rotations = 0
		elif src_rotation >= 45 and src_rotation <= 135:
			sand_rotations = 1
		elif src_rotation >= 135 and src_rotation <= 225:
			sand_rotations = 2
		else: 
			sand_rotations = 3
			
		var ox = 0
		var oy = 0
		var xi = x
		var yi = y
		var t = 0
		
		for option in options:
			ox = option.x
			oy = option.y
			for _j in range(sand_rotations):
				t = -ox
				ox = oy
				oy = t
			xi = x + ox
			yi = y + oy
				
			if in_range(xi, yi) and data[xi][yi] == CELL.empty:
				data[x][y] = CELL.empty
				updated[x][y] = true
				
				data[xi][yi] = current
				updated[xi][yi] = true
				
				break
	
	# Render my data
	my_image.lock()
	for x in range(WIDTH):
		for y in range(HEIGHT):
			if updated[x][y]:
				my_image.set_pixel(x, y, COLORS[data[x][y]])
	my_image.unlock()
	
	my_texture.set_data(my_image)
	
