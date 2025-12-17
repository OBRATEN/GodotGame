extends Node2D

@onready var tilemap = $TileMap

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

const GROUND_LAYER_ID = 0
const WALLS_LAYER_ID = 1

const TOP_WALL_BOTTOM = Vector2i(4, 2)
const TOP_WALL_MID = Vector2i(4, 1)
const TOP_WALL_TOP = Vector2i(4, 0)
const RIGHT_WALL = Vector2i(5, 2)
const LEFT_WALL = Vector2i(3, 2)
const BOTTOM_WALL = Vector2i(4, 3)

const TOP_TO_RIGHT_TOP = Vector2i(5, 0)
const TOP_TO_LEFT_TOP = Vector2i(3, 0)

const BOTTOM_TO_RIGHT = Vector2i(5, 3)
const BOTTOM_TO_LEFT = Vector2i(3, 3)

enum CellType { EMPTY = 0, FLOOR = 1, WALL = 2 }

enum WallRole {
	DEFAULT = 0,
	LEFT = 1,
	RIGHT = 2,
	BOTTOM = 3,
	TOP_BOTTOM = 4,
	TOP_MID = 5,
	TOP_TOP = 6,
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
		var new_pos = _find_free_space_with_gap(boss_room.size, MIN_ROOM_GAP)
		if new_pos != Vector2i(0, 0):
			boss_room.position = new_pos
			rooms[rooms.size() - 1] = boss_room
		else:
			print("Warning: Could not reposition boss room, keeping original.")

	var virtual_map = _create_virtual_map()
	_print_virtual_map(virtual_map)
	_apply_virtual_map_to_tilemap(virtual_map)

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
	var min_x = 9999; var max_x = -9999
	var min_y = 9999; var max_y = -9999

	for room in rooms:
		var r_min_x = room.position.x - 1
		var r_max_x = room.position.x + room.size.x
		var r_min_y = room.position.y - 3
		var r_max_y = room.position.y + room.size.y

		min_x = min(min_x, r_min_x)
		max_x = max(max_x, r_max_x)
		min_y = min(min_y, r_min_y)
		max_y = max(max_y, r_max_y)

	for i in range(rooms.size() - 1):
		var center_a = rooms[i].position + rooms[i].size / 2
		var center_b = rooms[i+1].position + rooms[i+1].size / 2
		var x = center_a.x
		var y = center_a.y
		var target_x = center_b.x
		var target_y = center_b.y

		while x != target_x:
			min_x = min(min_x, x); max_x = max(max_x, x)
			x += 1 if x < target_x else -1
		while y != target_y:
			min_y = min(min_y, y); max_y = max(max_y, y)
			y += 1 if y < target_y else -1

	var width = max_x - min_x + 1
	var height = max_y - min_y + 1
	var virtual_map = []
	for y in range(height):
		virtual_map.append([])
		for x in range(width):
			virtual_map[y].append({
				"type": CellType.EMPTY,
				"wall_role": WallRole.DEFAULT
			})

	for room in rooms:
		var r_min = global_to_local(room.position.x, room.position.y, min_x, min_y)
		var r_max = global_to_local(
			room.position.x + room.size.x - 1,
			room.position.y + room.size.y - 1,
			min_x, min_y
		)

		for y in range(r_min.y, r_max.y + 1):
			for x in range(r_min.x, r_max.x + 1):
				if x >= 0 and x < width and y >= 0 and y < height:
					virtual_map[y][x]["type"] = CellType.FLOOR

		for y_off in [-3, -2, -1]:
			var local_y = global_to_local(0, room.position.y + y_off, min_x, min_y).y
			if local_y >= 0 and local_y < height:
				for x in range(r_min.x, r_max.x + 1):
					if x >= 0 and x < width:
						virtual_map[local_y][x]["type"] = CellType.WALL
						if y_off == -1:
							virtual_map[local_y][x]["wall_role"] = WallRole.TOP_BOTTOM
						elif y_off == -2:
							virtual_map[local_y][x]["wall_role"] = WallRole.TOP_MID
						elif y_off == -3:
							virtual_map[local_y][x]["wall_role"] = WallRole.TOP_TOP

		for y in range(r_min.y, r_max.y + 1):
			var local_left_x = global_to_local(room.position.x - 1, 0, min_x, min_y).x
			var local_right_x = global_to_local(room.position.x + room.size.x, 0, min_x, min_y).x

			if local_left_x >= 0 and local_left_x < width:
				if y >= 0 and y < height:
					if virtual_map[y][local_left_x]["type"] != CellType.FLOOR:
						virtual_map[y][local_left_x]["type"] = CellType.WALL
						if y == r_min.y:
							virtual_map[y][local_left_x]["wall_role"] = WallRole.CORNER_TOP_LEFT
						elif y == r_max.y:
							virtual_map[y][local_left_x]["wall_role"] = WallRole.CORNER_BOTTOM_LEFT
						else:
							virtual_map[y][local_left_x]["wall_role"] = WallRole.LEFT

			if local_right_x >= 0 and local_right_x < width:
				if y >= 0 and y < height:
					if virtual_map[y][local_right_x]["type"] != CellType.FLOOR:
						virtual_map[y][local_right_x]["type"] = CellType.WALL
						if y == r_min.y:
							virtual_map[y][local_right_x]["wall_role"] = WallRole.CORNER_TOP_RIGHT
						elif y == r_max.y:
							virtual_map[y][local_right_x]["wall_role"] = WallRole.CORNER_BOTTOM_RIGHT
						else:
							virtual_map[y][local_right_x]["wall_role"] = WallRole.RIGHT

		var local_bottom_y = global_to_local(0, room.position.y + room.size.y, min_x, min_y).y
		if local_bottom_y >= 0 and local_bottom_y < height:
			for x in range(r_min.x, r_max.x + 1):
				if x >= 0 and x < width:
					if virtual_map[local_bottom_y][x]["type"] != CellType.FLOOR:
						virtual_map[local_bottom_y][x]["type"] = CellType.WALL
						virtual_map[local_bottom_y][x]["wall_role"] = WallRole.BOTTOM

	for i in range(rooms.size() - 1):
		var center_a = rooms[i].position + rooms[i].size / 2
		var center_b = rooms[i+1].position + rooms[i+1].size / 2
		var x = center_a.x
		var y = center_a.y
		var target_x = center_b.x
		var target_y = center_b.y

		var local_start_x = global_to_local(x, y, min_x, min_y).x
		var local_start_y = global_to_local(x, y, min_x, min_y).y
		var local_target_x = global_to_local(target_x, target_y, min_x, min_y).x
		var local_target_y = global_to_local(target_y, target_y, min_x, min_y).y

		while local_start_x != local_target_x:
			if local_start_x >= 0 and local_start_x < width and local_start_y >= 0 and local_start_y < height:
				virtual_map[local_start_y][local_start_x]["type"] = CellType.FLOOR
			local_start_x += 1 if local_start_x < local_target_x else -1

		while local_start_y != local_target_y:
			if local_start_x >= 0 and local_start_x < width and local_start_y >= 0 and local_start_y < height:
				virtual_map[local_start_y][local_start_x]["type"] = CellType.FLOOR
			local_start_y += 1 if local_start_y < local_target_y else -1

	return virtual_map


func _print_virtual_map(map_data):
	var output = ""
	for row in map_data:
		var line = ""
		for cell in row:
			match cell["type"]:
				CellType.EMPTY:
					line += "# "
				CellType.FLOOR:
					line += ". "
				CellType.WALL:
					line += "W "
				_:
					line += "? "
		output += line + "\n"
	print(output)

func _apply_virtual_map_to_tilemap(map_data):
	var min_x = 9999; var max_x = -9999
	var min_y = 9999; var max_y = -9999

	for room in rooms:
		var r_min_x = room.position.x - 1
		var r_max_x = room.position.x + room.size.x
		var r_min_y = room.position.y - 3
		var r_max_y = room.position.y + room.size.y

		min_x = min(min_x, r_min_x)
		max_x = max(max_x, r_max_x)
		min_y = min(min_y, r_min_y)
		max_y = max(max_y, r_max_y)

	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			var world_x = x + min_x
			var world_y = y + min_y
			var cell_type = map_data[y][x]["type"]
			var wall_role = map_data[y][x]["wall_role"]

			if cell_type == CellType.FLOOR:
				tilemap.set_cell(GROUND_LAYER_ID, Vector2i(world_x, world_y), FLOOR_TILE_SOURCE_ID, FLOOR_TILE_ATLAS_COORDS, FLOOR_TILE_ALT_ID)
			else:
				tilemap.set_cell(GROUND_LAYER_ID, Vector2i(world_x, world_y), -1, Vector2i(0, 0), 0)
				
				var wall_atlas_coords = Vector2i(1, 1)
				match wall_role:
					WallRole.LEFT:
						wall_atlas_coords = LEFT_WALL
					WallRole.RIGHT:
						wall_atlas_coords = RIGHT_WALL
					WallRole.BOTTOM:
						wall_atlas_coords = BOTTOM_WALL
					WallRole.TOP_BOTTOM:
						wall_atlas_coords = TOP_WALL_BOTTOM
					WallRole.TOP_MID:
						wall_atlas_coords = TOP_WALL_MID
					WallRole.TOP_TOP:
						wall_atlas_coords = TOP_WALL_TOP
					WallRole.CORNER_TOP_LEFT:
						wall_atlas_coords = TOP_TO_LEFT_TOP
					WallRole.CORNER_TOP_RIGHT:
						wall_atlas_coords = TOP_TO_RIGHT_TOP
					WallRole.CORNER_BOTTOM_LEFT:
						wall_atlas_coords = BOTTOM_TO_LEFT
					WallRole.CORNER_BOTTOM_RIGHT:
						wall_atlas_coords = BOTTOM_TO_RIGHT

				tilemap.set_cell(WALLS_LAYER_ID, Vector2i(world_x, world_y), 0, wall_atlas_coords, 0)


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
