extends Control

func _ready():
	var CELL = $Wall/Engine.CELL
	
	$Wall/Engine.fill(CELL.wall)
	$Plant/Engine.fill(CELL.plant)
	$Water/Engine.fill(CELL.water)
	$Lava/Engine.fill(CELL.lava)

