extends CharacterBody2D

# Путь к сцене диалогового окна
@export var dialog_scene_path: String = "res://scenes/Dialog_window.tscn"
var dialog_scene: PackedScene
var player_node: Node2D
var tile_size: Vector2 = Vector2(64, 64) # Размер тайла (измените под ваш проект)

func _ready():
	dialog_scene = load(dialog_scene_path) as PackedScene
	player_node = get_tree().get_first_node_in_group("player")

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Преобразуем экранные координаты клика в мировые
		var click_position = get_global_mouse_position()
		var self_position = global_position
		
		# Проверяем, кликнули ли мы по этому NPC (используя collision shape)
		if is_position_in_npc(click_position):
			if player_node:
				# Вычисляем расстояние в тайлах
				var distance_in_tiles = calculate_tile_distance(player_node.global_position, self_position)
				
				if distance_in_tiles <= 5:
					show_dialog()

func is_position_in_npc(click_position: Vector2) -> bool:
	var local_click_pos = to_local(click_position)
	var collision_shape = $CollisionShape2D.shape
	var shape_pos = $CollisionShape2D.position
	var world_center = shape_pos
	var distance_squared = world_center.distance_squared_to(local_click_pos)
	var radius_squared = collision_shape.radius * collision_shape.radius

	return distance_squared <= radius_squared

func calculate_tile_distance(pos1: Vector2, pos2: Vector2) -> float:
	# Вычисляем манхэттенское расстояние в тайлах
	var delta = (pos1 - pos2).abs()
	var tiles_x = delta.x / tile_size.x
	var tiles_y = delta.y / tile_size.y
	return ceil(tiles_x + tiles_y)

func show_dialog():
	if get_parent().get_node_or_null("DialogWindow"):
		return

	var dialog_instance = dialog_scene.instantiate()
	dialog_instance.name = "DialogWindow"
	get_parent().add_child(dialog_instance)
