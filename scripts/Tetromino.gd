extends Node2D

signal on_lock
signal on_reset

# Physics constants
const IMPULSE = Vector2(25, 0)
const GRAVITY = Vector2(0, 100)
const TORQUE = 100
const LOCK_TIME = 0.1
const SETTLE_SPEED = 5.0
const RESET_THRESHOLD = 50
const DIFFICULTY_SCALE = {
	'Easy': 0.5,
	'Medium': 0.75,
	'Hard': 1.0
}

var stuck_time = 0
var initialized = false

onready var bodies = [
	$"Block0/Body",
	$"Block1/Body",
	$"Block2/Body",
	$"Block3/Body"
]

onready var global_options = get_node("/root/Options")

# Define the shapes, values are the four coordinates and then a center point to rotate around
const SHAPES = {
	'I': [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3), Vector2(0.5, 2.0)],
	'O': [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1.0, 1.0)],
	'T': [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(1, 1), Vector2(1.5, 0.5)],
	'J': [Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(0, 2), Vector2(1.5, 2.5)],
	'L': [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 2), Vector2(0.5, 2.5)],
	'S': [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(2, 0), Vector2(1.5, 0.5)],
	'Z': [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 0), Vector2(1.5, 0.5)]
}

# Helper functions to get the correct child nodes by index
func block(i):
	return get_node("Block" + str(i))
	
# Initialize a random shape
func init_random():
	var names = SHAPES.keys()
	var name = names[randi() % names.size()]
	init(name)

# Initialize the shape with one of the names
func init(shape):
	assert(shape in SHAPES)
	
	# Set positions
	for i in range(4):
		block(i).position = 16 * SHAPES[shape][i]
		
	# Get neighbors and create joints
	for i in range(4):
		for j in range(4):
			var xi = SHAPES[shape][i].x
			var yi = SHAPES[shape][i].y
			var xj = SHAPES[shape][j].x
			var yj = SHAPES[shape][j].y
			
			var bi = block(i)
			var bj = block(j)
			
			# Each only has to do one way, since we'll catch the other when bi  and bj swap
			var joined = false
			if xi + 1 == xj and yi == yj:
				bi.get_node("Body/PixelEngine").neighbors['right'] = bj
				joined = true
			elif xi - 1 == xj and yi == yj:
				bi.get_node("Body/PixelEngine").neighbors['left'] = bj
				joined = true
			elif xi == xj and yi + 1 == yj:
				bi.get_node("Body/PixelEngine").neighbors['bottom'] = bj
				joined = true
			elif xi == xj and yi - 1 == yj:
				bi.get_node("Body/PixelEngine").neighbors['top'] = bj
				joined = true
				
			# Only add joints one direction
			if joined and i < j:
				var midpoint = (bi.position + bj.position) / 2
				var pins = []
				
				if xi == xj:
					pins.append(midpoint + Vector2(0, 8))
					pins.append(midpoint + Vector2(0, -8))
				else:
					pins.append(midpoint + Vector2(8, 0))
					pins.append(midpoint + Vector2(-8, 0))
					
				for pin in pins:
					var joint = PinJoint2D.new()
					joint.position = pin

					add_child(joint)
					joint.node_a = joint.get_path_to(bi.get_node("Body"))
					joint.node_b = joint.get_path_to(bj.get_node("Body"))
				
	initialized = true

func _ready():
	for body in bodies:
		body.add_central_force(GRAVITY)

func _physics_process(delta):
	if not initialized:
		return
	
	# Keyboard controls
	if get_parent().get_parent().demo:
		if randf() < 0.1:
			var impulse = IMPULSE * (randf() - 0.5)
			var torque = TORQUE * (randf() - 0.5)
			
			for body in bodies:
				body.apply_central_impulse(impulse)
				body.apply_torque_impulse(torque)
	else:
		for body in bodies:
			if Input.is_action_pressed("ui_right"):
				body.apply_central_impulse(DIFFICULTY_SCALE[global_options.difficulty] * IMPULSE)
			if Input.is_action_pressed("ui_left"):
				body.apply_central_impulse(DIFFICULTY_SCALE[global_options.difficulty] * -IMPULSE)
			if Input.is_action_pressed("ui_up"):
				body.apply_central_impulse(DIFFICULTY_SCALE[global_options.difficulty] * -0.1 * GRAVITY)
			if Input.is_action_pressed("ui_down"):
				body.apply_central_impulse(DIFFICULTY_SCALE[global_options.difficulty] * GRAVITY)
			if Input.is_action_pressed("ui_rotate_left"):
				body.apply_torque_impulse(DIFFICULTY_SCALE[global_options.difficulty] * -TORQUE)
			if Input.is_action_pressed("ui_rotate_right"):
				body.apply_torque_impulse(DIFFICULTY_SCALE[global_options.difficulty] * TORQUE)
		
	var settled = true
	for body in bodies:
		if not body.sleeping:
			settled = false
		
	var total_velocity = 0	
	for body in bodies:
		total_velocity += body.get_linear_velocity().length()
	
	if total_velocity <= SETTLE_SPEED:
		settled = true
		
	if Input.is_action_just_pressed("ui_accept"):
		settled = true
		stuck_time = LOCK_TIME + delta
		
	# If we hit something, start a counter, if that goes long enough, lock the block
	if settled:
		stuck_time += delta
		var highest_body = INF
		
		if stuck_time > LOCK_TIME:
			for body in bodies:
				# Stop the body from moving
				body.set_mode(RigidBody2D.MODE_STATIC)
				highest_body = min(highest_body, body.position.y)
				
				# Copy data from the block to the parent
				var engine = body.get_node("PixelEngine")
				var parent = get_parent().get_parent().get_node("PixelEngine")
				
				for x in range(engine.WIDTH):
					for y in range(engine.HEIGHT):
						var target = body.global_position - Vector2(8, 8) + Vector2(x * engine.SCALE, y * engine.SCALE).rotated(engine.rotation)
						var tx = int(target.x) / parent.SCALE
						var ty = int(target.y) / parent.SCALE
						
						if parent.in_range(tx, ty) and parent.data[tx][ty] == parent.CELL.empty:
							parent.data[tx][ty] = engine.data[x][y]
							parent.force_update = true
						
				# Remove the block data
				engine.queue_free()
				engine.get_parent().get_node("Border").set_default_color(Color(1.0, 1.0, 1.0, 0.25))

			# If we're too high up, send a reset signal
			# Otherwise, lock this block and spawn a new one
			if highest_body < RESET_THRESHOLD:
				emit_signal("on_reset")
			else:
				set_physics_process(false)
				emit_signal("on_lock")
			
	else:
		stuck_time = 0
