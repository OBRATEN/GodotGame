extends CharacterBody2D

# Параметры
const TILE_SIZE: Vector2i = Vector2i(16, 16)
const SPEED: float = 100.0  # пикселей в секунду

# Внутренние переменные
var path: Array[Vector2i] = []
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false

# Ссылки
@onready var tilemap: TileMap = get_tree().current_scene.get_node("TileMap")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # чтобы видеть курсор

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var click_pos = get_global_mouse_position()
		var tile_coord = world_to_tile(click_pos)
		if is_tile_walkable(tile_coord):
			var start_tile = world_to_tile(global_position)
			path = find_path(start_tile, tile_coord)
			if not path.is_empty():
				path.pop_front()  # убираем стартовую клетку
				is_moving = true

func _process(delta):
	if is_moving and not path.is_empty():
		var next_tile = path[0]
		target_position = tile_to_world(next_tile)
		
		# Двигаемся к центру следующего тайла
		var direction = (target_position - global_position).normalized()
		velocity = direction * SPEED
		move_and_slide()
		
		# Проверяем, достигли ли центра тайла
		if global_position.distance_to(target_position) < 2.0:
			global_position = target_position  # выравниваем точно
			path.pop_front()
			if path.is_empty():
				is_moving = false
				velocity = Vector2.ZERO

# Преобразует мировые координаты в координаты тайла (Vector2i)
func world_to_tile(world_pos: Vector2) -> Vector2i:
	return tilemap.local_to_map(tilemap.to_local(world_pos))

# Преобразует координаты тайла в мировые (центр тайла)
func tile_to_world(tile: Vector2i) -> Vector2:
	return tilemap.map_to_local(tile) + Vector2(TILE_SIZE) / 2.0

# Проверяет, можно ли ступить на тайл (в данном примере — всегда можно)
# Замените логику, если у вас есть проходимость/непроходимость
func is_tile_walkable(tile: Vector2i) -> bool:
	# Пример: если тайл не пустой (или наоборот — зависит от вашей логики)
	# Здесь просто разрешаем всё
	return true

# Поиск пути с помощью A*
func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if start == goal:
		return [start]

	var open_set = []
	var came_from = {}
	var g_score = {}
	var f_score = {}

	g_score[start] = 0
	f_score[start] = start.distance_to(goal)
	open_set.append(start)

	while not open_set.is_empty():
		# Находим узел с наименьшим f_score
		var current = open_set[0]
		for node in open_set:
			if f_score.get(node, INF) < f_score.get(current, INF):
				current = node

		if current == goal:
			return reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in get_neighbors(current):
			if not is_tile_walkable(neighbor):
				continue

			var tentative_g = g_score.get(current, INF) + current.distance_to(neighbor)

			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + neighbor.distance_to(goal)
				if not open_set.has(neighbor):
					open_set.append(neighbor)

	return []  # путь не найден

# Восстанавливает путь из came_from
func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.insert(0, current)
	return path

# Возвращает 8 соседей (горизонталь, вертикаль, диагональ)
func get_neighbors(tile: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			neighbors.append(Vector2i(tile.x + dx, tile.y + dy))
	return neighbors
