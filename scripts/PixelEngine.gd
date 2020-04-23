extends Node2D

export var WIDTH = 16
export var HEIGHT = 16
export var SCALE = 1

export var START_EMPTY = false
export var ALLOW_ROTATION = true

const IMAGE_FORMAT = Image.FORMAT_RGBA8
var UPDATES_PER_FRAME = min(WIDTH * HEIGHT, 16 * 16 * 200)

onready var options = get_node("/root/Options")
onready var config = get_node("/root/Config")
onready var sprite = $PixelEngine

var my_image
var my_texture
var mouse_down = false
var neighbors = {
	'top': null,
	'left': null,
	'right': null,
	'bottom': null
}

var data = []
var counts = []
var updated = []
var force_update = false

# Fill the engine with the given particle type
# If with is null, fill with a random type
func fill(type = null):
	# Choose a random type to spawn
	if type == null:
		var spawns = config.difficulties[options.difficulty]['spawns']
		var spawn_list = []
		for type in spawns:
			for _i in range(spawns[type]):
				spawn_list.append(type)
				
		type = spawn_list[randi() % spawn_list.size()]
	
	for x in range(WIDTH):
		for y in range(HEIGHT):
			if type in config.keywords['blocky'] or randf() < config.spawn_chance:
				data[x][y] = type
					
	force_update = true
	
func color_for(type):
	var colors = config.colors[type]
	var color = colors[randi() % colors.size()]
	
	if type in config.keywords['colorful']:
		return Color(
			color.r + config.color_variation * (randf() - 0.5),
			color.g + config.color_variation * (randf() - 0.5),
			color.b + config.color_variation * (randf() - 0.5)
		)
	else:
		return color
		
func recalculate_counts():
	for x in range(WIDTH):
		for y in range(HEIGHT):
			for type in config.types:
				counts[x][y][type] = 0
			
			for keyword in config.custom_keywords:
				counts[x][y][keyword] = 0
			
	for x in range(WIDTH):
		for y in range(HEIGHT):
			for xi in range(x - 1, x + 2):
				for yi in range(y - 1, y + 2):
					if in_range(xi, yi) and not (xi == x and yi == y):
						counts[xi][yi][data[x][y]] += 1
						
						for keyword in config.custom_keywords:
							if data[x][y] in config.keywords[keyword]:
								counts[xi][yi][data[x][y]] += 1

func set_data(x, y, type):
	var previous = data[x][y]
	data[x][y] = type
	updated[x][y] = true
	
	for xi in range(x - 1, x + 2):
		for yi in range(y - 1, y + 2):
			if in_range(xi, yi) and not (xi == x and yi == y):
				counts[xi][yi][previous] -= 1
				counts[xi][yi][type] += 1
				
				for keyword in config.custom_keywords:
					if previous in config.keywords[keyword]:
						counts[xi][yi][keyword] -= 1

					if type in config.keywords[keyword]:
						counts[xi][yi][keyword] += 1
	
func swap_data(x1, y1, x2, y2):
	var buffer = data[x1][y1]
	set_data(x1, y1, data[x2][y2])
	set_data(x2, y2, buffer)

func _ready():
	# Create an empty matrix of data cells and update flags
	for x in range(WIDTH):
		data.append([])
		updated.append([])
		counts.append([])
	
		for y in range(HEIGHT):
			data[x].append('empty')
			updated[x].append(false)
			counts[x].append({})
			
			for type in config.types:
				counts[x][y][type] = 0
				
	if not START_EMPTY:
		fill()
		recalculate_counts()
			
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
			my_image.set_pixel(x, y, color_for(data[x][y]))
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
	
func _process(_delta):
	# Reset the update map
	for x in range(WIDTH):
		for y in range(HEIGHT):
			updated[x][y] = false
			
	# If we're in a force cycle, refresh the counts
	if force_update:
		recalculate_counts()
			
	# Update a number of pixels at random
	for _i in range(UPDATES_PER_FRAME):
		var x = randi() % WIDTH
		var y = randi() % HEIGHT
		
		if updated[x][y]:
			continue

		var current = data[x][y]
		if current == 'empty':
			continue

		_process_reactions(x, y)
		_process_moves(x, y)
		
	_process_render()
	
	force_update = false
	
# Try to react
func _process_reactions(x, y):
	var current = data[x][y]
	for reaction_type in config.reactions:
		if not current in config.reactions[reaction_type]:
			continue
		
		for reaction in config.reactions[reaction_type][current]:
			var chance = reaction[0]
			var reagents = reaction[1]
			var products = reaction[2]
			
			# If there's a chance and we don't match that, no reaction
			if randf() > chance:
				continue
			
			# If there are reagents and they're not present, no reaction
			var reagents_match = true
			for reagent in reagents:
				var type = reagent[0]
				var operator = reagent[1]
				var quantity = reagent[2]
				var result = (
					   (operator == '<'  and counts[x][y][type] <  quantity)
					or (operator == '<=' and counts[x][y][type] <= quantity)
					or (operator == '='  and counts[x][y][type] == quantity)
					or (operator == '!=' and counts[x][y][type] != quantity)
					or (operator == '>=' and counts[x][y][type] >= quantity)
					or (operator == '>'  and counts[x][y][type] >  quantity)
				)
				if not result:
					reagents_match = false
					break
					
			if not reagents_match:
				continue
				
			# Generate a product
			var product_chance = randf()
			var product = 'empty'
			for potential_product in products:
				if product_chance < products[potential_product]:
					product = potential_product
				else:
					product_chance -= products[potential_product]
			
			# Do the reaction thing
			if reaction_type == 'decay':
				set_data(x, y, product)
				break

			elif reaction_type == 'spawn':
				var xi = x + 1 - randi() % 3
				var yi = y + 1 - randi() % 3
				if in_range(xi, yi) and data[xi][yi] == 'empty':
					set_data(xi, yi, product)

			elif reaction_type == 'neighbor':
				var xi = x + 1 - randi() % 3
				var yi = y + 1 - randi() % 3
				if in_range(xi, yi) and data[xi][yi] == 'empty':
					set_data(xi, yi, product)
				
			elif reaction_type == 'self':
				set_data(x, y, product)

# Try to move
func _process_moves(x, y):
	var current = data[x][y]
	var offsets = []
	if current in config.keywords['rising']:
		offsets += [Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)]
	if current in config.keywords['falling']:
		offsets += [Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]
	if current in config.keywords['spreading']:
		offsets += [Vector2(-1, 0), Vector2(1, 0)]
	offsets.shuffle()
	
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
	
	for offset in offsets:
		ox = offset.x
		oy = offset.y
		for _j in range(sand_rotations):
			t = -ox
			ox = oy
			oy = t
		xi = x + ox
		yi = y + oy
			
		if in_range(xi, yi) and data[xi][yi] == 'empty':
			swap_data(x, y, xi, yi)
			break

# Update the texture for anything that chanced
func _process_render():
	my_image.lock()
	for x in range(WIDTH):
		for y in range(HEIGHT):
			if updated[x][y] or force_update:
				my_image.set_pixel(x, y, color_for(data[x][y]))	
	my_image.unlock()
	my_texture.set_data(my_image)
	
