extends Node2D

@onready var tilemap = $TileMap

const FLOOR_TILE_SOURCE_ID = 0
const FLOOR_TILE_ATLAS_COORDS = Vector2i(1, 1)
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

const TOP_WALL_BOTTOM = Vector2i(4, 2)
const TOP_WALL_MID = Vector2i(4, 1)
const TOP_WALL_TOP = Vector2i(4, 0)
const RIGHT_WALL = Vector2i(5, 1)
const LEFT_WALL = Vector2i(3, 1)
const BOTTOM_WALL = Vector2i(4, 3)

const TOP_TO_RIGHT_TOP = Vector2i(5, 0)
const TOP_TO_RIGHT_MID = Vector2i(5, 1)
const TOP_TO_RIGHT_BOT = Vector2i(5, 1)

const TOP_TO_LEFT_TOP = Vector2i(3, 0)
const TOP_TO_LEFT_MID = Vector2i(3, 1)
const TOP_TO_LEFT_BOT = Vector2i(3, 1)

const BOTTOM_TO_RIGHT = Vector2i(5, 3)
const BOTTOM_TO_LEFT = Vector2i(3, 3)

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
		boss_room.position = _find_free_space_with_gap(boss_room.size, MIN_ROOM_GAP)
		rooms[rooms.size() - 1] = boss_room

	for room in rooms:
		_draw_room(room)
		_draw_walls(room)

	for i in range(rooms.size() - 1):
		_draw_cornered_corridor(rooms[i], rooms[i + 1])

	if rooms.size() > 0:
		tilemap.position = -Vector2(rooms[0].position.x * 16, rooms[0].position.y * 16)
	print("Dungeon generated with ", rooms.size(), " rooms.")
	if entrance_room:
		print("Entrance at: ", entrance_room.position)
	if boss_room:
		print("Boss room at: ", boss_room.position)

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

func _draw_room(room):
	for x in range(room.size.x):
		for y in range(room.size.y):
			var pos = room.position + Vector2i(x, y)
			tilemap.set_cell(0, pos, FLOOR_TILE_SOURCE_ID, FLOOR_TILE_ATLAS_COORDS, FLOOR_TILE_ALT_ID)

func _draw_walls(room):
	var pos = room.position
	var w = room.size.x
	var h = room.size.y

	for y in range(h):
		var left_pos = pos + Vector2i(-1, y)
		var right_pos = pos + Vector2i(w, y)

		if y == 0:
			tilemap.set_cell(WALL_LAYER_ID, left_pos, 0, TOP_TO_LEFT_BOT, 0)
			tilemap.set_cell(WALL_LAYER_ID, right_pos, 0, TOP_TO_RIGHT_BOT, 0)
		elif y == h - 1:
			tilemap.set_cell(WALL_LAYER_ID, left_pos, 0, LEFT_WALL, 0)
			tilemap.set_cell(WALL_LAYER_ID, right_pos, 0, RIGHT_WALL, 0)
		else:
			tilemap.set_cell(WALL_LAYER_ID, left_pos, 0, LEFT_WALL, 0)
			tilemap.set_cell(WALL_LAYER_ID, right_pos, 0, RIGHT_WALL, 0)

	for x in range(w):
		tilemap.set_cell(WALL_LAYER_ID, pos + Vector2i(x, h), 0, BOTTOM_WALL, 0)

	for x in range(w):
		tilemap.set_cell(WALL_LAYER_ID, pos + Vector2i(x, -1), 0, TOP_WALL_BOTTOM, 0)
		tilemap.set_cell(WALL_LAYER_ID, pos + Vector2i(x, -2), 0, TOP_WALL_MID, 0)
		tilemap.set_cell(WALL_LAYER_ID, pos + Vector2i(x, -3), 0, TOP_WALL_TOP, 0)

	tilemap.set_cell(WALL_LAYER_ID, pos + Vector2i(-1, -3), 0, TOP_TO_LEFT_TOP, 0)
	tilemap.set_cell(WALL_LAYER_ID, pos + Vector2i(-1, -2), 0, TOP_TO_LEFT_MID, 0)
	tilemap.set_cell(WALL_LAYER_ID, pos + Vector2i(-1, -1), 0, TOP_TO_LEFT_BOT, 0)

	tilemap.set_cell(WALL_LAYER_ID, pos + Vector2i(w, -3), 0, TOP_TO_RIGHT_TOP, 0)
	tilemap.set_cell(WALL_LAYER_ID, pos + Vector2i(w, -2), 0, TOP_TO_RIGHT_MID, 0)
	tilemap.set_cell(WALL_LAYER_ID, pos + Vector2i(w, -1), 0, TOP_TO_RIGHT_BOT, 0)

	tilemap.set_cell(WALL_LAYER_ID, pos + Vector2i(-1, h), 0, BOTTOM_TO_LEFT, 0)
	tilemap.set_cell(WALL_LAYER_ID, pos + Vector2i(w, h), 0, BOTTOM_TO_RIGHT, 0)

func _draw_cornered_corridor(a, b):
	var center_a = a.position + a.size / 2
	var center_b = b.position + b.size / 2

	var x = center_a.x
	var y = center_a.y
	var target_x = center_b.x

	while x != target_x:
		tilemap.set_cell(0, Vector2i(x, y), FLOOR_TILE_SOURCE_ID, FLOOR_TILE_ATLAS_COORDS, FLOOR_TILE_ALT_ID)
		x += 1 if x < target_x else -1

	var target_y = center_b.y
	while y != target_y:
		tilemap.set_cell(0, Vector2i(x, y), FLOOR_TILE_SOURCE_ID, FLOOR_TILE_ATLAS_COORDS, FLOOR_TILE_ALT_ID)
		y += 1 if y < target_y else -1

	tilemap.set_cell(0, center_b, FLOOR_TILE_SOURCE_ID, FLOOR_TILE_ATLAS_COORDS, FLOOR_TILE_ALT_ID)
