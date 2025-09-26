extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var tile_map: TileMap = $TileMap  # Убедитесь, что у вас есть TileMap

func _ready():
	pass

func _input(event):
	# Можно добавить дополнительную логику обработки ввода на уровне мира
	pass
