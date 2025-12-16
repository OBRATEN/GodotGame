extends Node2D

@onready var tilemap = $TileMap

# Идентификаторы слоёв тайлов
const FLOOR_TILE_SOURCE_ID = 0
const FLOOR_TILE_ATLAS_COORDS = Vector2i(1, 6)
const FLOOR_TILE_ALT_ID = 0

const ROOM_MIN_SIZE = 4
const ROOM_MAX_SIZE = 8
const MAX_ROOMS = 5
const MIN_ROOM_GAP = 3
const BOSS_ROOM_SIZE = Vector2i(6, 6)

var rooms = []
var boss_room = null
var entrance_room = null

const WALL_LAYER_ID = 1

# Координаты тайлов стен в атласе
const TOP_WALL_BOTTOM = Vector2i(4, 2) # Нижний тайл верхней стены
const TOP_WALL_MID = Vector2i(4, 1)    # Средний тайл верхней стены
const TOP_WALL_TOP = Vector2i(4, 0)    # Верхний тайл верхней стены
const RIGHT_WALL = Vector2i(5, 2)      # Правая стена
const LEFT_WALL = Vector2i(3, 2)       # Левая стена
const BOTTOM_WALL = Vector2i(4, 3)     # Нижняя стена

const TOP_TO_RIGHT_TOP = Vector2i(5, 0) # Угол между правой стеной и верхом верхней стены
const TOP_TO_LEFT_TOP = Vector2i(3, 0)  # Угол между левой стеной и верхом верхней стены

const BOTTOM_TO_RIGHT = Vector2i(5, 3)  # Угол между нижней стеной и правой
const BOTTOM_TO_LEFT = Vector2i(3, 3)   # Угол между нижней стеной и левой

# Типы ячеек для виртуальной карты
enum CellType { EMPTY = 0, FLOOR = 1, WALL = 2 }

# Дополнительные метки для стен (роль стены)
enum WallRole {
	DEFAULT = 0,
	LEFT = 1,
	RIGHT = 2,
	BOTTOM = 3,
	TOP_BOTTOM = 4, # Нижняя часть верхней стены
	TOP_MID = 5,    # Средняя часть верхней стены
	TOP_TOP = 6,    # Верхняя часть верхней стены
	CORNER_TOP_LEFT = 7,
	CORNER_TOP_RIGHT = 8,
	CORNER_BOTTOM_LEFT = 9,
	CORNER_BOTTOM_RIGHT = 10
}

func _ready():
	generate_dungeon()

func generate_dungeon(seed = randi()):
	seed(seed)
	rooms.clear()
	boss_room = null
	entrance_room = null
	tilemap.clear()

	# --- Генерация списка комнат ---
	for i in range(MAX_ROOMS):
		var room = _make_room()
		if i == 0 or not _has_overlap_with_gap(room, MIN_ROOM_GAP):
			rooms.append(room)
			if i == 0:
				entrance_room = room
			if i == MAX_ROOMS - 1:
				boss_room = room

	if boss_room:
		boss_room.size = BOSS_ROOM_SIZE
		# Попробуем найти место для босс-комнаты с учётом зазора
		var new_pos = _find_free_space_with_gap(boss_room.size, MIN_ROOM_GAP)
		if new_pos != Vector2i(0, 0): # Если удалось найти место
			boss_room.position = new_pos
			# Заменяем последнюю комнату на обновлённую босс-комнату
			rooms[rooms.size() - 1] = boss_room
		else: # Если не удалось, просто оставляем как есть
			print("Warning: Could not reposition boss room, keeping original.")

	# --- Создание виртуальной карты ---
	var virtual_map = _create_virtual_map()

	# --- Вывод виртуальной карты в консоль ---
	_print_virtual_map(virtual_map)

	# --- Установка тайлов из виртуальной карты ---
	_apply_virtual_map_to_tilemap(virtual_map)

	# --- Центрируем камеру или тайлмап ---
	if rooms.size() > 0:
		tilemap.position = -Vector2(rooms[0].position.x * 16, rooms[0].position.y * 16)
	
	print("Dungeon generated with ", rooms.size(), " rooms.")
	if entrance_room:
		print("Entrance at: ", entrance_room.position)
	if boss_room:
		print("Boss room at: ", boss_room.position)

func global_to_local(gx, gy, offset_x, offset_y):
	return Vector2i(gx - offset_x, gy - offset_y)

func _create_virtual_map():
	# Локальная функция для преобразования глобальных координат в индексы виртуальной карты

	# Определяем границы виртуальной карты
	var min_x = 9999; var max_x = -9999
	var min_y = 9999; var max_y = -9999

	# Учитываем все комнаты и коридоры между ними
	for room in rooms:
		var r_min_x = room.position.x - 1 # Стена сразу на краю комнаты
		var r_max_x = room.position.x + room.size.x # Стена сразу на краю комнаты
		var r_min_y = room.position.y - 3 # Верхняя стена высотой 3 тайла
		var r_max_y = room.position.y + room.size.y # Нижняя стена

		min_x = min(min_x, r_min_x)
		max_x = max(max_x, r_max_x)
		min_y = min(min_y, r_min_y)
		max_y = max(max_y, r_max_y)

	# Коридоры
	for i in range(rooms.size() - 1):
		var center_a = rooms[i].position + rooms[i].size / 2
		var center_b = rooms[i+1].position + rooms[i+1].size / 2
		var x = center_a.x
		var y = center_a.y
		var target_x = center_b.x
		var target_y = center_b.y

		# Обновляем границы по горизонтали
		while x != target_x:
			min_x = min(min_x, x); max_x = max(max_x, x)
			x += 1 if x < target_x else -1
		# Обновляем границы по вертикали
		while y != target_y:
			min_y = min(min_y, y); max_y = max(max_y, y)
			y += 1 if y < target_y else -1

	# Создаём пустую виртуальную карту
	var width = max_x - min_x + 1
	var height = max_y - min_y + 1
	var virtual_map = []
	for y in range(height):
		virtual_map.append([])
		for x in range(width):
			# Каждый элемент теперь будет объектом с типом и ролью
			virtual_map[y].append({
				"type": CellType.EMPTY,
				"wall_role": WallRole.DEFAULT
			})

	# Рисуем комнаты на виртуальной карте
	for room in rooms:
		var r_min = global_to_local(room.position.x, room.position.y, min_x, min_y)
		var r_max = global_to_local(
			room.position.x + room.size.x - 1,
			room.position.y + room.size.y - 1,
			min_x, min_y
		)

		# Пол
		for y in range(r_min.y, r_max.y + 1):
			for x in range(r_min.x, r_max.x + 1):
				if x >= 0 and x < width and y >= 0 and y < height:
					virtual_map[y][x]["type"] = CellType.FLOOR

		# Стены - сразу поверх пола
		# Верхняя стена (три строки: -3, -2, -1 относительно верха комнаты)
		for y_off in [-3, -2, -1]:
			var local_y = global_to_local(0, room.position.y + y_off, min_x, min_y).y
			if local_y >= 0 and local_y < height:
				for x in range(r_min.x, r_max.x + 1):
					if x >= 0 and x < width:
						virtual_map[local_y][x]["type"] = CellType.WALL
						# Назначаем роль в зависимости от y_off
						if y_off == -3:
							virtual_map[local_y][x]["wall_role"] = WallRole.TOP_TOP
						elif y_off == -2:
							virtual_map[local_y][x]["wall_role"] = WallRole.TOP_MID
						else: # y_off == -1
							virtual_map[local_y][x]["wall_role"] = WallRole.TOP_BOTTOM

		# Левая стена (на два тайла выше верха комнаты)
		# Начинаем с y = room.position.y - 2 (на два тайла выше верха комнаты) до y = room.position.y + room.size.y - 1 (нижний край комнаты)
		for y_off in [-2, -1]: # Два тайла выше
			var local_y = global_to_local(0, room.position.y + y_off, min_x, min_y).y
			if local_y >= 0 and local_y < height:
				var local_x = global_to_local(room.position.x - 1, 0, min_x, min_y).x
				if local_x >= 0 and local_x < width:
					virtual_map[local_y][local_x]["type"] = CellType.WALL
					virtual_map[local_y][local_x]["wall_role"] = WallRole.LEFT
		# Теперь рисуем левую стену по высоте комнаты
		for y in range(r_min.y, r_max.y + 1):
			var local_x = global_to_local(room.position.x - 1, 0, min_x, min_y).x
			if local_x >= 0 and local_x < width:
				virtual_map[y][local_x]["type"] = CellType.WALL
				virtual_map[y][local_x]["wall_role"] = WallRole.LEFT

		# Правая стена (на два тайла выше верха комнаты)
		# Аналогично левой
		for y_off in [-2, -1]: # Два тайла выше
			var local_y = global_to_local(0, room.position.y + y_off, min_x, min_y).y
			if local_y >= 0 and local_y < height:
				var local_x = global_to_local(room.position.x + room.size.x, 0, min_x, min_y).x
				if local_x >= 0 and local_x < width:
					virtual_map[local_y][local_x]["type"] = CellType.WALL
					virtual_map[local_y][local_x]["wall_role"] = WallRole.RIGHT
		# Теперь рисуем правую стену по высоте комнаты
		for y in range(r_min.y, r_max.y + 1):
			var local_x = global_to_local(room.position.x + room.size.x, 0, min_x, min_y).x
			if local_x >= 0 and local_x < width:
				virtual_map[y][local_x]["type"] = CellType.WALL
				virtual_map[y][local_x]["wall_role"] = WallRole.RIGHT

		# Нижняя стена
		for x in range(r_min.x, r_max.x + 1):
			var local_y = global_to_local(0, room.position.y + room.size.y, min_x, min_y).y
			if local_y >= 0 and local_y < height:
				virtual_map[local_y][x]["type"] = CellType.WALL
				virtual_map[local_y][x]["wall_role"] = WallRole.BOTTOM

		# Углы стен
		# Левый верхний угол (крепится к верхней стене, на уровне верхнего тайла)
		var lt_top_pos = global_to_local(room.position.x - 1, room.position.y - 3, min_x, min_y)
		if lt_top_pos.x >= 0 and lt_top_pos.x < width and lt_top_pos.y >= 0 and lt_top_pos.y < height:
			virtual_map[lt_top_pos.y][lt_top_pos.x]["type"] = CellType.WALL
			virtual_map[lt_top_pos.y][lt_top_pos.x]["wall_role"] = WallRole.CORNER_TOP_LEFT
		# Правый верхний угол (крепится к верхней стене, на уровне верхнего тайла)
		var rt_top_pos = global_to_local(room.position.x + room.size.x, room.position.y - 3, min_x, min_y)
		if rt_top_pos.x >= 0 and rt_top_pos.x < width and rt_top_pos.y >= 0 and rt_top_pos.y < height:
			virtual_map[rt_top_pos.y][rt_top_pos.x]["type"] = CellType.WALL
			virtual_map[rt_top_pos.y][rt_top_pos.x]["wall_role"] = WallRole.CORNER_TOP_RIGHT

		# Левый нижний угол
		var lb_pos = global_to_local(room.position.x - 1, room.position.y + room.size.y, min_x, min_y)
		if lb_pos.x >= 0 and lb_pos.x < width and lb_pos.y >= 0 and lb_pos.y < height:
			virtual_map[lb_pos.y][lb_pos.x]["type"] = CellType.WALL
			virtual_map[lb_pos.y][lb_pos.x]["wall_role"] = WallRole.CORNER_BOTTOM_LEFT
		# Правый нижний угол
		var rb_pos = global_to_local(room.position.x + room.size.x, room.position.y + room.size.y, min_x, min_y)
		if rb_pos.x >= 0 and rb_pos.x < width and rb_pos.y >= 0 and rb_pos.y < height:
			virtual_map[rb_pos.y][rb_pos.x]["type"] = CellType.WALL
			virtual_map[rb_pos.y][rb_pos.x]["wall_role"] = WallRole.CORNER_BOTTOM_RIGHT


	# Рисуем коридоры на виртуальной карте
	for i in range(rooms.size() - 1):
		var center_a = rooms[i].position + rooms[i].size / 2
		var center_b = rooms[i+1].position + rooms[i+1].size / 2
		var x = center_a.x
		var y = center_a.y
		var target_x = center_b.x
		var target_y = center_b.y

		# Горизонтальный участок
		while x != target_x:
			var local_coord = global_to_local(x, y, min_x, min_y)
			if local_coord.x >= 0 and local_coord.x < width and local_coord.y >= 0 and local_coord.y < height:
				virtual_map[local_coord.y][local_coord.x]["type"] = CellType.FLOOR # Коридор - пол
			x += 1 if x < target_x else -1

		# Вертикальный участок
		while y != target_y:
			var local_coord = global_to_local(x, y, min_x, min_y)
			if local_coord.x >= 0 and local_coord.x < width and local_coord.y >= 0 and local_coord.y < height:
				virtual_map[local_coord.y][local_coord.x]["type"] = CellType.FLOOR # Коридор - пол
			y += 1 if y < target_y else -1

		# Конечная точка (центр следующей комнаты)
		var final_coord = global_to_local(target_x, target_y, min_x, min_y)
		if final_coord.x >= 0 and final_coord.x < width and final_coord.y >= 0 and final_coord.y < height:
			virtual_map[final_coord.y][final_coord.x]["type"] = CellType.FLOOR # Конечная точка коридора - пол

	return virtual_map


func _print_virtual_map(virtual_map):
	print("--- Virtual Map ---")
	for row in virtual_map:
		var line = ""
		for cell in row:
			match cell["type"]:
				CellType.EMPTY: line += "."
				CellType.FLOOR: line += "#"
				CellType.WALL: 
					# Для стен можно вывести букву роли, например, L, R, T, B, C
					match cell["wall_role"]:
						WallRole.LEFT: line += "L"
						WallRole.RIGHT: line += "R"
						WallRole.BOTTOM: line += "B"
						WallRole.TOP_BOTTOM: line += "t"
						WallRole.TOP_MID: line += "m"
						WallRole.TOP_TOP: line += "T"
						WallRole.CORNER_TOP_LEFT: line += "C"
						WallRole.CORNER_TOP_RIGHT: line += "c"
						WallRole.CORNER_BOTTOM_LEFT: line += "b"
						WallRole.CORNER_BOTTOM_RIGHT: line += "r"
						_: line += "W"
		print(line)
	print("-------------------")


func _apply_virtual_map_to_tilemap(virtual_map):
	# Проходим по виртуальной карте и устанавливаем тайлы
	for y in range(virtual_map.size()):
		for x in range(virtual_map[y].size()):
			var pos = Vector2i(x, y)
			var cell = virtual_map[y][x]
			
			if cell["type"] == CellType.FLOOR:
				# Устанавливаем пол на основном слое (0)
				tilemap.set_cell(0, pos, FLOOR_TILE_SOURCE_ID, FLOOR_TILE_ATLAS_COORDS, FLOOR_TILE_ALT_ID)
			elif cell["type"] == CellType.WALL:
				# Устанавливаем стену на слое стен (1), выбирая тайл по роли
				var tile_coords = Vector2i(0, 0)
				match cell["wall_role"]:
					WallRole.LEFT:
						tile_coords = LEFT_WALL
					WallRole.RIGHT:
						tile_coords = RIGHT_WALL
					WallRole.BOTTOM:
						tile_coords = BOTTOM_WALL
					WallRole.TOP_BOTTOM:
						tile_coords = TOP_WALL_BOTTOM
					WallRole.TOP_MID:
						tile_coords = TOP_WALL_MID
					WallRole.TOP_TOP:
						tile_coords = TOP_WALL_TOP
					WallRole.CORNER_TOP_LEFT:
						tile_coords = TOP_TO_LEFT_TOP
					WallRole.CORNER_TOP_RIGHT:
						tile_coords = TOP_TO_RIGHT_TOP
					WallRole.CORNER_BOTTOM_LEFT:
						tile_coords = BOTTOM_TO_LEFT
					WallRole.CORNER_BOTTOM_RIGHT:
						tile_coords = BOTTOM_TO_RIGHT
					_:
						# По умолчанию используем левую стену
						tile_coords = LEFT_WALL

				# Устанавливаем тайл на слое стен (1)
				tilemap.set_cell(WALL_LAYER_ID, pos, 0, tile_coords, 0)

func _make_room():
	var size = Vector2i(
		randi_range(ROOM_MIN_SIZE, ROOM_MAX_SIZE),
		randi_range(ROOM_MIN_SIZE, ROOM_MAX_SIZE)
	)
	var pos = Vector2i(
		randi_range(0, 40),
		randi_range(0, 40)
	)
	return {"position": pos, "size": size}

func _has_overlap_with_gap(room, gap):
	for other in rooms:
		var expanded_other = Rect2(
			other.position.x - gap,
			other.position.y - gap,
			other.size.x + 2 * gap,
			other.size.y + 2 * gap
		)
		var room_rect = Rect2(room.position.x, room.position.y, room.size.x, room.size.y)

		if expanded_other.intersects(room_rect):
			return true
	return false

func _find_free_space_with_gap(size, gap):
	var attempts = 0
	while attempts < 200:
		var pos = Vector2i(
			randi_range(0, 40),
			randi_range(0, 40)
		)
		var room = {"position": pos, "size": size}
		if not _has_overlap_with_gap(room, gap):
			return pos
		attempts += 1
	print("Warning: Could not find free space for room after many attempts.")
	return Vector2i(0, 0)
