extends Node2D

@export var floor_terrain_name: String = "floor"
@export var wall_terrain_name: String = "wall"

var tilemap: TileMap
var width = 64
var height = 64
var dungeon_map = []
var rooms = []

func _ready():
	tilemap = $TileMap
	generate_dungeon()

func generate_dungeon():
	if tilemap == null:
		push_error("TileMap не найден! Убедитесь, что имя узла TileMap — 'TileMap'")
		return
	randomize()
	create_empty_map()
	generate_rooms()
	generate_corridors()
	apply_map_to_tilemap()

func create_empty_map():
	dungeon_map.resize(height)
	for y in range(height):
		dungeon_map[y] = []
		dungeon_map[y].resize(width)
		for x in range(width):
			dungeon_map[y][x] = 1  # Стена по умолчанию

func generate_rooms():
	var max_rooms = 10
	var min_room_size = 4
	var max_room_size = 10
	rooms.clear()

	for i in range(max_rooms):
		var w = randi_range(min_room_size, max_room_size)
		var h = randi_range(min_room_size, max_room_size)
		var x = randi_range(1, width - w - 1)
		var y = randi_range(1, height - h - 1)

		var new_room = Rect2(x, y, w, h)

		var ok = true
		for other_room in rooms:
			if new_room.intersects(other_room):
				ok = false
				break

		if ok:
			rooms.append(new_room)
			carve_room(new_room)

func carve_room(room):
	for y in range(int(room.position.y), int(room.position.y + room.size.y)):
		for x in range(int(room.position.x), int(room.position.x + room.size.x)):
			dungeon_map[y][x] = 0  # Пол

func generate_corridors():
	for i in range(1, rooms.size()):
		var prev_room = rooms[i - 1]
		var curr_room = rooms[i]

		var prev_center = Vector2(prev_room.position.x + prev_room.size.x / 2,
								  prev_room.position.y + prev_room.size.y / 2)
		var curr_center = Vector2(curr_room.position.x + curr_room.size.x / 2,
								  curr_room.position.y + curr_room.size.y / 2)

		# Горизонтальный коридор
		var x_start = int(prev_center.x)
		var x_end = int(curr_center.x)
		for x in range(min(x_start, x_end), max(x_start, x_end) + 1):
			dungeon_map[int(prev_center.y)][x] = 0

		# Вертикальный коридор
		var y_start = int(prev_center.y)
		var y_end = int(curr_center.y)
		for y in range(min(y_start, y_end), max(y_start, y_end) + 1):
			dungeon_map[y][int(curr_center.x)] = 0

func get_terrain_indices_by_name(terrain_name: String) -> Dictionary:
	var terrain_set_count = tilemap.tile_set.get_terrain_sets_count()
	for terrain_set_idx in range(terrain_set_count):
		var terrain_count = tilemap.tile_set.get_terrains_count(terrain_set_idx)
		for terrain_idx in range(terrain_count):
			var name = tilemap.tile_set.get_terrain_name(terrain_set_idx, terrain_idx)
			if name == terrain_name:
				return {"set": terrain_set_idx, "id": terrain_idx}
	print("Террейн с именем '", terrain_name, "' не найден.")
	return {}

func apply_map_to_tilemap():
	tilemap.clear()
	var floor_data = get_terrain_indices_by_name(floor_terrain_name)
	var wall_data = get_terrain_indices_by_name(wall_terrain_name)
	if floor_data.is_empty() or wall_data.is_empty():
		push_error("Один или оба террейна не найдены в TileSet!")
		return

	var floor_cells = []
	var wall_cells = []

	for y in range(height):
		for x in range(width):
			var coords = Vector2i(x, y)
			if dungeon_map[y][x] == 0:
				floor_cells.append(coords)
			else:
				wall_cells.append(coords)

	print("Количество пола: ", floor_cells.size(), ", количество стен: ", wall_cells.size())

	# Сначала ставим стены
	if not wall_cells.is_empty():
		tilemap.set_cells_terrain_connect(0, wall_cells, wall_data["set"], wall_data["id"])
	# Затем пол — он заменит часть стен
	if not floor_cells.is_empty():
		tilemap.set_cells_terrain_connect(0, floor_cells, floor_data["set"], floor_data["id"])

	tilemap.update_internals()
