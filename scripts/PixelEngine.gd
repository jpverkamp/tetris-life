extends Node2D

export var WIDTH = 16
export var HEIGHT = 16
export var SCALE = 1

export var START_EMPTY = false
export var ALLOW_ROTATION = true

const IMAGE_FORMAT = Image.FORMAT_RGBA8

onready var global_options = get_node("/root/Options")

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
	smoke,
	water,
	plant,
	lava,
	fire,
	acid
}

const COLORS = {
	CELL.empty: Color(0, 0, 0, 0),
	CELL.wall:  Color(0.5,  0.5,  0.5),
	CELL.sand:  Color(0.76, 0.70, 0.50),
	CELL.smoke: Color(0.95, 0.95, 0.95),
	CELL.water: Color(0,    0,    1.0),
	CELL.plant: Color(0,    0.75, 0),
	CELL.lava:  Color(0.75, 0.33, 0.33),
	CELL.fire:  Color(1.0,  0,    0),
	CELL.acid:  Color(1.0,  0,    1.0)
}

# Particles a frame can start with and percent to fill with that
const INITABLE = {
	'Easy': [
		CELL.wall, CELL.wall,
		CELL.sand, CELL.sand, CELL.sand, CELL.sand,
		CELL.water, CELL.water, CELL.water, CELL.water,
		CELL.empty, CELL.empty,
	],
	'Medium': [
		CELL.wall, CELL.wall,
		CELL.sand, CELL.sand,
		CELL.water, CELL.water,
		CELL.empty,
		CELL.smoke,
		CELL.lava
	],
	'Hard': [
		CELL.wall, CELL.wall,
		CELL.sand, CELL.sand,
		CELL.water, 
		CELL.empty, CELL.empty,
		CELL.smoke, CELL.smoke,
		CELL.lava, CELL.lava, CELL.lava
	]
}
const EXPERIMENTAL = [CELL.acid]
const SPAWN_FULL_BLOCKS = [CELL.wall]
const INIT_CHANCE = 0.50

# Number of particles to randomly try to update each frame
onready var UPDATES_PER_FRAME = min(WIDTH * HEIGHT, 16 * 16 * 100)

# Types that move up/down/left and right respective
const RISING = [CELL.smoke, CELL.fire]
const FALLING = [CELL.sand, CELL.water, CELL.lava, CELL.fire, CELL.acid]
const SPREADING = [CELL.smoke, CELL.fire, CELL.water, CELL.lava, CELL.acid]

# Types that randomly disappear
const DESPAWN_CHANCE = 0.1
const DESPAWNING = [CELL.smoke, CELL.fire]

# Types that may spawn new particles
const SPAWN_CHANCE_PER_EMPTY = 0.05
const SPAWNING = {
	CELL.lava: CELL.fire
}

# Types that have slight color variations
const COLOR_VARIATION = 0.1
const VARIABLE_COLORS = [
	CELL.wall,
	CELL.sand,
	CELL.plant
]

# Other constants
const BURN_CHANCE_PER_FIRE = 0.1
const PLANT_GROWTH_LIMITER = 2
const PLANT_GROWTH_PER_EMPTY = {
	'Easy': 0.01,
	'Medium': 0.005,
	'Hard': 0.001
}
const ACID_STRENGTH = 0.25

onready var sprite = $PixelEngine

var data = []
var updated = []
var force_update = false

# Fill the engine with the given particle type
# If with is null, fill with a random type
func fill(type = null):
	# Choose a random type to spawn
	if type == null:
		var init = INITABLE[global_options.difficulty]
		if global_options.experimental:
			init += EXPERIMENTAL
			
		type = init[randi() % init.size()]
	
	for x in range(WIDTH):
		data.append([])
		updated.append([])
		for y in range(HEIGHT):
			if type in SPAWN_FULL_BLOCKS or randf() < INIT_CHANCE:
				data[x][y] = type
			

func _ready():
	# Create an empty matrix of data cells and update flags
	for x in range(WIDTH):
		data.append([])
		updated.append([])
		
		for _y in range(HEIGHT):
			data[x].append(CELL.empty)
			updated[x].append(false)
			
	if not START_EMPTY:
		fill()
			
	# Create the image we will actually draw to
	my_image = Image.new()
	my_image.create(WIDTH, HEIGHT, false, IMAGE_FORMAT)
	
	# Create a texture that the image will render to and that we can use on this sprite
	my_texture = ImageTexture.new()
	my_texture.create_from_image(my_image)
	my_texture.flags &= ~ImageTexture.FLAG_FILTER
	my_texture.flags &= ~ImageTexture.FLAG_MIPMAPS
	
	# Render initial data
	my_image.lock()
	for x in range(WIDTH):
		for y in range(HEIGHT):
			my_image.set_pixel(x, y, COLORS[data[x][y]])
	my_image.unlock()
	
	sprite.set_texture(my_texture)
	sprite.region_rect = Rect2(0, 0, WIDTH, HEIGHT)
	sprite.set_scale(SCALE * sprite.get_scale())
	
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
		for yi in range(y - 1, y + 2):
			if not in_range(xi, yi) or (xi == x and yi == y):
				continue
				
			if data[xi][yi] == type:
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
			var hot_neighbors = count_neighbors_of(x, y, CELL.fire) + count_neighbors_of(x, y, CELL.lava)
			var empty_neighbors = count_neighbors_of(x, y, CELL.empty)
			var plant_neighbors = count_neighbors_of(x, y, CELL.plant)
			
			# Fire/lava ignite plants
			if randf() < hot_neighbors * BURN_CHANCE_PER_FIRE:
				data[x][y] = CELL.fire
				updated[x][y] = true
				
			# Plants try to grow
			elif empty_neighbors > 0 and plant_neighbors <= PLANT_GROWTH_LIMITER:
				for xi in range(x - 1, x + 2):
					for yi in range(y - 1, y + 2):
						if not in_range(xi, yi) or (xi == x and yi == y):
							continue
							
						if data[xi][yi] != CELL.empty:
							continue
							
						if randf() < PLANT_GROWTH_PER_EMPTY[global_options.difficulty]:
							data[xi][yi] = CELL.plant
							updated[xi][yi] = true
							
							plant_neighbors += 1
							if plant_neighbors > PLANT_GROWTH_LIMITER:
								break
					
					if plant_neighbors > PLANT_GROWTH_LIMITER:
								break

			# Plants need air to live (also can't make a game unloseable by bury in sand)
			elif empty_neighbors == 0:
				data[x][y] = CELL.empty
				updated[x][y] = true

		elif current == CELL.fire:
			# Water puts out fire
			if count_neighbors_of(x, y, CELL.water) > 0:
				data[x][y] = CELL.empty
				updated[x][y] = true
				
		elif current == CELL.lava:
			# Fire and water react to form solid (floating) walls
			if count_neighbors_of(x, y, CELL.water) > 0:
				data[x][y] = CELL.wall
				updated[x][y] = true

		elif current == CELL.water:
			var plant_neighbors = count_neighbors_of(x, y, CELL.plant)
			
			# Water is put out by fire
			if count_neighbors_of(x, y, CELL.fire):
				data[x][y] = CELL.smoke
				updated[x][y] = true
			# Plants grow if given just enough water
			elif plant_neighbors > 0:
				if plant_neighbors >= PLANT_GROWTH_LIMITER:
					data[x][y] = CELL.empty
					updated[x][y] = true
				else:
					data[x][y] = CELL.plant
					updated[x][y] = true
			
		elif current == CELL.acid:
			if count_neighbors_of(x, y, CELL.water) > 0:
				data[x][y] = CELL.sand
				updated[x][y] = true
			else:
				for xi in range(x - 1, x + 2):
					for yi in range(y - 1, y + 2):
						if not in_range(xi, yi) or (xi == x and yi == y):
							continue
						else:
							if randf() < ACID_STRENGTH:
								data[xi][yi] = CELL.empty
								updated[xi][yi] = true
		
		# Potentially spawn
		current = data[x][y]
		if current in SPAWNING:
			for xi in range(x - 1, x + 2):
				for yi in range(y - 1, y + 2):
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
		
		var sand_rotations = 0
		if ALLOW_ROTATION:
			var src_rotation = (360 + int(sprite.get_parent().get_parent().rotation_degrees)) % 360
			
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
			if updated[x][y] or force_update:
				var color = COLORS[data[x][y]]
				if data[x][y] in VARIABLE_COLORS:
					my_image.set_pixel(x, y, Color(
						color.r + COLOR_VARIATION * (randf() - 0.5),
						color.g + COLOR_VARIATION * (randf() - 0.5),
						color.b + COLOR_VARIATION * (randf() - 0.5)
					))
				else:
					my_image.set_pixel(x, y, color)
					
	my_image.unlock()
	
	my_texture.set_data(my_image)
	force_update = false
	
