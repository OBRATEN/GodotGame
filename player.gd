extends CharacterBody2D

@export var speed: float = 150.0  # Скорость движения

var target_position: Vector2
var is_moving: bool = false
var path: PackedVector2Array = []

func _ready():
	target_position = global_position

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		set_target_position(mouse_pos)

func set_target_position(world_pos: Vector2):
	# Привязываем к центру тайла 16x16
	var tile_center = snap_to_tile_center(world_pos)
	
	# Если кликнули на текущую позицию - ничего не делаем
	if tile_center.distance_to(global_position) < 1.0:
		return
	
	target_position = tile_center
	
	# Генерируем путь
	path = generate_grid_path(global_position, target_position)
	
	# Если путь найден, начинаем движение
	if path.size() > 0:
		is_moving = true

func snap_to_tile_center(world_pos: Vector2) -> Vector2:
	var tile_size = 16
	var tile_x = floor(world_pos.x / tile_size) * tile_size + tile_size / 2
	var tile_y = floor(world_pos.y / tile_size) * tile_size + tile_size / 2
	return Vector2(tile_x, tile_y)

func generate_grid_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	var path_points = PackedVector2Array()
	
	# Получаем координаты тайлов
	var start_tile = world_to_tile_coord(start)
	var end_tile = world_to_tile_coord(end)
	
	# Если начальная и конечная точки совпадают
	if start_tile == end_tile:
		return path_points
	
	# Вычисляем разницу в тайлах
	var diff_x = end_tile.x - start_tile.x
	var diff_y = end_tile.y - start_tile.y
	
	# Движение по диагонали (если нужно)
	if abs(diff_x) > 0 and abs(diff_y) > 0:
		var diagonal_tile = Vector2i(
			start_tile.x + sign(diff_x),
			start_tile.y + sign(diff_y)
		)
		path_points.append(tile_coord_to_world(diagonal_tile))
	
	# Движение по горизонтали/вертикали к цели
	path_points.append(tile_coord_to_world(end_tile))
	
	return path_points

func world_to_tile_coord(world_pos: Vector2) -> Vector2i:
	var tile_size = 16
	return Vector2i(
		floor(world_pos.x / tile_size),
		floor(world_pos.y / tile_size)
	)

func tile_coord_to_world(tile_coord: Vector2i) -> Vector2:
	var tile_size = 16
	return Vector2(
		tile_coord.x * tile_size + tile_size / 2,
		tile_coord.y * tile_size + tile_size / 2
	)

func _physics_process(delta):
	if is_moving and path.size() > 0:
		move_along_path(delta)

func move_along_path(delta: float):
	var next_point = path[0]
	var direction = (next_point - global_position).normalized()
	
	# Двигаемся к следующей точке пути
	var movement = direction * speed * delta
	global_position = global_position.move_toward(next_point, speed * delta)
	
	# Проверяем достижение точки
	if global_position.distance_to(next_point) < 1.0:
		path.remove_at(0)
		
		# Если достигли конечной точки
		if path.size() == 0:
			is_moving = false

# Функция для принудительной остановки движения
func stop_movement():
	is_moving = false
	path.clear()

# Функция для проверки, движется ли персонаж
func is_character_moving() -> bool:
	return is_moving
