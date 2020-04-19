extends Control

func _ready():
	var CELL = $Acid/Engine.CELL
	
	$Acid/Engine.fill(CELL.acid)
	$Wax/Engine.fill(CELL.wax)
	$Ice/Engine.fill(CELL.ice)
	
