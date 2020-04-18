extends Node2D

const IMAGE_SIZE = Vector2(16, 16)
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

onready var sprite = $PixelEngine
onready var shape = $"../CollisionShape"

func _ready():
	# Create the image we will actually draw to
	my_image = Image.new()
	my_image.create(IMAGE_SIZE.x, IMAGE_SIZE.y, false, IMAGE_FORMAT)
	
	# Create a texture that the image will render to and that we can use on this sprite
	my_texture = ImageTexture.new()
	my_texture.create_from_image(my_image)
	
	sprite.set_texture(my_texture)
	sprite.region_rect = Rect2(0, 0, IMAGE_SIZE.x, IMAGE_SIZE.y)
	
	sprite.set_process_input(true)
	
func _process(_delta):
	my_image.lock()
	for _i in range(10):
		my_image.set_pixel(
			rand_range(0, IMAGE_SIZE.x - 1),
			rand_range(0, IMAGE_SIZE.y - 1),
			Color(
				randf(),
				randf(),
				randf()
			)
		)
	my_image.unlock()
	my_texture.set_data(my_image)
	
