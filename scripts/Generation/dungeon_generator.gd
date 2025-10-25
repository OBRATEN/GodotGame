extends Node2D

@export var floor_terrain_name: String = "floor"
@export var wall_terrain_name: String = "wall"

var tilemap: TileMap
var width = 64
var height = 64
var initial_chance = 0.45
var birth_limit = 4
var death_limit = 3
var steps = 5

var dungeon_map = []

func _ready():
	tilemap = $TileMap
	generate_dungeon()

func generate_dungeon():
	if tilemap == null:
		push_error("TileMap не найден! Убедитесь, что имя узла TileMap — 'TileMap'")
		return
	randomize()
	initialize_map()
	for i in range(steps):
		dungeon_map = run_cellular_automata_step(dungeon_map)
	carve_rooms()
	apply_map_to_tilemap()

func initialize_map():
	dungeon_map.resize(height)
	for y in range(height):
		dungeon_map[y] = []
		dungeon_map[y].resize(width)
		for x in range(width):
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				dungeon_map[y][x] = 1
			else:
				dungeon_map[y][x] = 1 if randf() < initial_chance else 0

func count_alive_neighbors(x, y):
	var count = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i == 0 and j == 0:
				continue
			var nx = x + i
			var ny = y + j
			if nx < 0 or nx >= width or ny < 0 or ny >= height:
				count += 1
			else:
				count += dungeon_map[ny][nx]
	return count

func run_cellular_automata_step(old_map):
	var new_map = []
	new_map.resize(height)
	for y in range(height):
		new_map[y] = []
		new_map[y].resize(width)
		for x in range(width):
			var neighbors = count_alive_neighbors(x, y)
			if old_map[y][x] == 1:
				new_map[y][x] = 1 if neighbors >= death_limit else 0
			else:
				new_map[y][x] = 1 if neighbors > birth_limit else 0
	return new_map

func carve_rooms():
	var rooms = []
	var num_rooms = 8
	for i in range(num_rooms):
		var w = randi_range(5, 10)
		var h = randi_range(5, 10)
		var x = randi_range(1, width - w - 1)
		var y = randi_range(1, height - h - 1)
		var room = Rect2(x, y, w, h)
		if not intersects_any_room(room, rooms):
			rooms.append(room)
			carve_room(room)

func intersects_any_room(room, rooms):
	for r in rooms:
		if r.intersects(room):
			return true
	return false

func carve_room(room):
	for y in range(int(room.position.y), int(room.position.y + room.size.y)):
		for x in range(int(room.position.x), int(room.position.x + room.size.x)):
			dungeon_map[y][x] = 0

func get_terrain_indices_by_name(terrain_name: String) -> Dictionary:
	var terrain_set_count = tilemap.tile_set.get_terrain_sets_count()
	for terrain_set_idx in range(terrain_set_count):
		var terrain_count = tilemap.tile_set.get_terrains_count(terrain_set_idx)
		for terrain_idx in range(terrain_count):
			var name = tilemap.tile_set.get_terrain_name(terrain_set_idx, terrain_idx)
			if name == terrain_name:
				print("Найден террейн: ", name, " в наборе ", terrain_set_idx, " с индексом ", terrain_idx)
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

	# Устанавливаем террейны
	if not floor_cells.is_empty():
		tilemap.set_cells_terrain_connect(0, floor_cells, floor_data["set"], floor_data["id"])
	if not wall_cells.is_empty():
		tilemap.set_cells_terrain_connect(0, wall_cells, wall_data["set"], wall_data["id"])

	# Принудительное обновление
	tilemap.update_internals()
