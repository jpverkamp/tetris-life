extends Node2D

const IMPULSE = Vector2(10, 0)
const DECAY = 0.25
const FALLING = 1
const LOCK_TIME = 1

signal on_lock

onready var velocity = Vector2(0, 0)
onready var body = $KinematicBody2D

var stuck_time = 0

func _physics_process(delta):
	# Keyboard controls
	if Input.is_action_pressed("ui_right"):
		velocity += IMPULSE

	if Input.is_action_pressed("ui_left"):
		velocity -= IMPULSE

	# Apply friction and gravity
	velocity *= DECAY
	velocity.y = FALLING
	
	# Move the block
	var collision = body.move_and_collide(velocity)
	
	# If we hit something, start a counter, if that goes long enough, lock the block
	if collision:
		velocity = Vector2.ZERO
		stuck_time += delta
		if stuck_time > LOCK_TIME:
			set_physics_process(false)
			emit_signal("on_lock")
			
	else:
		stuck_time = 0
		
