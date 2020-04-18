extends Node2D

# The image size can be changed for various blocks in the editor
export var IMAGE_SIZE = Vector2(800, 600)

const IMAGE_FORMAT = Image.FORMAT_RGBA8
var rng = RandomNumberGenerator.new()

var my_image
var my_texture
var mouse_down = false

onready var sprite = get_node("./PixelEngine")

func _ready():
	# Create the image we will actually draw to
	my_image = Image.new()
	my_image.create(IMAGE_SIZE.x, IMAGE_SIZE.y, false, IMAGE_FORMAT)
	
	# Create a texture that the image will render to and that we can use on this sprite
	my_texture = ImageTexture.new()
	my_texture.create_from_image(my_image)
	
	# Lock the image, this has to be done to draw to it
	my_image.lock()
	
	for _i in range(1000):
		my_image.set_pixel(
			rng.randi_range(0, IMAGE_SIZE.x - 1),
			rng.randi_range(0, IMAGE_SIZE.y - 1),
			Color(
				rng.randf(),
				rng.randf(),
				rng.randf()
			)
		)
		
	my_image.unlock()
	
	sprite.set_texture(my_texture)
	sprite.region_rect = Rect2(0, 0, IMAGE_SIZE.x, IMAGE_SIZE.y)
	
	sprite.set_process_input(true)
	
func _process(_delta):
	OS.set_window_title("fps: " + str(Engine.get_frames_per_second()))
	
	my_image.lock()
	for _i in range(10):
		my_image.set_pixel(
			rng.randi_range(0, IMAGE_SIZE.x - 1),
			rng.randi_range(0, IMAGE_SIZE.y - 1),
			Color(
				rng.randf(),
				rng.randf(),
				rng.randf()
			)
		)
	my_image.unlock()
	
	my_texture.set_data(my_image)
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			mouse_down = event.is_pressed()
				
	if event is InputEventMouseMotion and mouse_down:
		position = event.position
		
