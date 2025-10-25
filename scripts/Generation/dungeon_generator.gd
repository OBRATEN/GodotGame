extends Node2D

@export var map_width: int = 100
@export var map_height: int = 100
@export var min_room_size: int = 5
@export var max_room_size: int = 12
@export var room_count: int = 20
@export var tile_size: Vector2 = Vector2(16, 16)

var dungeon_map: Array  # 0 = пустота, 1 = пол

func _ready():
	generate_dungeon()
	draw_to_tilemap()

func generate_dungeon():
	# Инициализация карты пустотой
	dungeon_map = []
	for y in range(map_height):
		var row = []
		for x in range(map_width):
			row.append(0)
		dungeon_map.append(row)

	var rooms = []

	for i in range(room_count):
		var room_width = randi_range(min_room_size, max_room_size)
		var room_height = randi_range(min_room_size, max_room_size)
		var x = randi_range(1, map_width - room_width - 1)
		var y = randi_range(1, map_height - room_height - 1)

		var new_room = Rect2i(x, y, room_width, room_height)

		var intersects = false
		for other_room in rooms:
			if new_room.intersects(other_room):
				intersects = true
				break

		if intersects:
			continue

		_carve_room(new_room)
		rooms.append(new_room)

		if rooms.size() > 1:
			var prev_room = rooms[rooms.size() - 2]
			_connect_rooms(prev_room.get_center(), new_room.get_center())

func _carve_room(room: Rect2i):
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			if x >= 0 and x < map_width and y >= 0 and y < map_height:
				dungeon_map[y][x] = 1

func _connect_rooms(center1: Vector2i, center2: Vector2i):
	var x = center1.x
	var y = center1.y

	while x != center2.x:
		if x < center2.x:
			x += 1
		else:
			x -= 1
		if x >= 0 and x < map_width and y >= 0 and y < map_height:
			dungeon_map[y][x] = 1

	while y != center2.y:
		if y < center2.y:
			y += 1
		else:
			y -= 1
		if x >= 0 and x < map_width and y >= 0 and y < map_height:
			dungeon_map[y][x] = 1

func draw_to_tilemap():
	var tilemap = $TileMap
	tilemap.clear()

	# Сначала рисуем пол на слое 0
	for y in range(map_height):
		for x in range(map_width):
			if dungeon_map[y][x] == 1:
				tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(1, 6))

	# Затем определяем и рисуем стены на слое 1
	for y in range(map_height):
		for x in range(map_width):
			if dungeon_map[y][x] == 1:
				continue  # Пол уже нарисован, стены только вокруг

			# Проверяем, является ли текущая ячейка стеной (окружает пол)
			var has_floor_north = (y > 0 and dungeon_map[y - 1][x] == 1)
			var has_floor_south = (y < map_height - 1 and dungeon_map[y + 1][x] == 1)
			var has_floor_west  = (x > 0 and dungeon_map[y][x - 1] == 1)
			var has_floor_east  = (x < map_width - 1 and dungeon_map[y][x + 1] == 1)

			# Если нет соседей-пола — это пустота, не рисуем
			if !has_floor_north and !has_floor_south and !has_floor_west and !has_floor_east:
				continue

			# Определяем тип стены по соседям
			var atlas_coords = Vector2i(1, 1)  # по умолчанию — пустота (на всякий)

			if has_floor_north and !has_floor_south and !has_floor_west and !has_floor_east:
				# Только север → нижняя часть верхней стены
				atlas_coords = Vector2i(4, 2)
			elif has_floor_north and has_floor_south and !has_floor_west and !has_floor_east:
				# Вертикальный коридор → средняя часть верхней стены (используем как универсальную вертикальную?)
				# Но по описанию: середина верхней стены — (4,1). Однако у нас нет отдельной "стены-столбика".
				# Поскольку у вас только верхняя стена трёхслойная, предположим, что:
				# - (4,0): верх
				# - (4,1): середина (для любых вертикальных участков)
				# - (4,2): низ
				# Но для простоты и согласно данным, будем использовать (4,1) как основную стену сверху.
				# Однако для корректного отображения углов и рёбер делаем полный анализ.
				pass  # обрабатываем ниже через углы и рёбра

			# Лучше использовать шаблон по 4 направлениям
			var is_north_wall = has_floor_north
			var is_south_wall = has_floor_south
			var is_west_wall  = has_floor_west
			var is_east_wall  = has_floor_east

			# Теперь определяем тайл по комбинации
			if is_north_wall and is_west_wall and !is_east_wall and !is_south_wall:
				atlas_coords = Vector2i(3, 0)  # левый верхний угол
			elif is_north_wall and is_east_wall and !is_west_wall and !is_south_wall:
				atlas_coords = Vector2i(5, 0)  # правый верхний угол
			elif is_south_wall and is_west_wall and !is_north_wall and !is_east_wall:
				atlas_coords = Vector2i(3, 3)  # левый нижний угол
			elif is_south_wall and is_east_wall and !is_north_wall and !is_west_wall:
				atlas_coords = Vector2i(5, 3)  # правый нижний угол
			elif is_north_wall and !is_south_wall and !is_west_wall and !is_east_wall:
				atlas_coords = Vector2i(4, 0)  # верх верхней стены
			elif is_north_wall and !is_south_wall and (is_west_wall or is_east_wall):
				# Уже обработано углами выше, но на случай ошибки — середина
				atlas_coords = Vector2i(4, 1)
			elif !is_north_wall and is_south_wall and !is_west_wall and !is_east_wall:
				atlas_coords = Vector2i(4, 3)  # нижняя стена
			elif !is_north_wall and !is_south_wall and is_west_wall and !is_east_wall:
				atlas_coords = Vector2i(3, 1)  # левая стена
			elif !is_north_wall and !is_south_wall and !is_west_wall and is_east_wall:
				atlas_coords = Vector2i(5, 1)  # правая стена
			elif is_north_wall and !is_south_wall:
				# Горизонтальная стена сверху (между углами)
				atlas_coords = Vector2i(4, 1)  # середина верхней стены
			elif is_west_wall and is_east_wall and !is_north_wall and !is_south_wall:
				# Горизонтальный коридор → стена сверху и снизу не нужна, но боковые есть
				# В данном случае текущая ячейка — стена над/под коридором? Нет.
				# На самом деле, если только запад и восток — это стена сверху или снизу от горизонтального коридора.
				# Но мы находимся в ячейке, которая окружает пол → если пол слева и справа, то это вертикальная стена?
				# Нет: если пол слева и справа, а мы — стена, то мы либо сверху, либо снизу от горизонтального коридора.
				# Но у нас нет отдельных тайлов для "стены над коридором", только верхняя стена трёхслойная.
				# Поэтому в таких случаях используем (4,1) как универсальную "стену сверху".
				# Однако по логике, если пол только по бокам, текущая ячейка — это либо потолок, либо пол подземелья.
				# Поскольку у нас 2D вид сверху, и стены только по периметру, то такая ситуация маловероятна.
				# Оставим как горизонтальную стену сверху.
				atlas_coords = Vector2i(4, 1)
			else:
				# По умолчанию — середина верхней стены для любых сложных случаев
				atlas_coords = Vector2i(4, 1)

			# Устанавливаем стену на слой 1
			tilemap.set_cell(1, Vector2i(x, y), 0, atlas_coords)
