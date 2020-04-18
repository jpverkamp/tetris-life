extends Node2D

onready var Block = preload("res://scenes/Block.tscn")
onready var blocks = $Blocks

func _on_Block_on_lock():
	var new_block = Block.instance()
	new_block.name = "Block" + str(blocks.get_child_count() + 1)
	new_block.position = Vector2(80, 20)
	new_block.connect("on_lock", self, "_on_Block_on_lock")
	blocks.add_child(new_block)

	print('Spawned ' + new_block.name)
	
