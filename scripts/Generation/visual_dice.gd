# VisualDice.gd
extends Node2D

var _displayed_value : int = 1:
	set(value):
		_displayed_value = value
		queue_redraw()
	get:
		return _displayed_value

var dice_type_sides : int = 6:
	set(value):
		dice_type_sides = value
		queue_redraw()
	get:
		return dice_type_sides

@export var dice_color : Color = Color.GRAY
@export var edge_color : Color = Color.LIGHT_GRAY
@export var text_color : Color = Color.WHITE
@export var font_size : int = 12


func _ready():
	_displayed_value = 1
	dice_type_sides = 6

func _draw():
	var center = Vector2.ZERO
	var radius = 40.0
	var sides = get_polygon_sides_for_dice_type(dice_type_sides)
	var shape_points = []

	if sides > 0:
		for i in range(sides):
			var angle = (TAU / sides) * i - (TAU / sides) / 2
			shape_points.append(center + Vector2.RIGHT.rotated(angle) * radius)

		draw_colored_polygon(shape_points, dice_color)
		draw_polygon_edges(shape_points, edge_color)

	draw_dice_text(_displayed_value, center)

func get_polygon_sides_for_dice_type(total_sides: int) -> int:
	match total_sides:
		4: return 3
		6: return 4
		8: return 6
		10: return 10
		12: return 12
		20: return 20
		_: return 6

func draw_polygon_edges(points: PackedVector2Array, color: Color):
	var n = points.size()
	if n < 2:
		return

	for i in range(n):
		var p1 = points[i]
		var p2 = points[(i + 1) % n]
		draw_line(p1, p2, color, 2.0, true)

func draw_dice_text(face_value: int, center_pos: Vector2):
	var text = str(face_value)
	var font = ThemeDB.fallback_font
	var font_height = font.get_height() * (font_size / ThemeDB.fallback_font_size)
	var text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x

	var text_pos = center_pos - Vector2(text_width / 2, font_height / 2)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

func update_visual(face_value: int, dice_sides: int):
	_displayed_value = face_value
	dice_type_sides = dice_sides
