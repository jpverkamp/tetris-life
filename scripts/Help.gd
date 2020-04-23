extends Control

func _ready():
	$Wall/Engine.fill('stone')
	$Plant/Engine.fill('plant')
	$Water/Engine.fill('water')
	$Lava/Engine.fill('lava')

