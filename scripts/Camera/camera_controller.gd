extends Camera2D

# Настройки
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.2
@export var max_zoom: float = 5.0
@export var drag_button: MouseButton = MOUSE_BUTTON_LEFT

var is_dragging: bool = false
var drag_start: Vector2
var camera_start_position: Vector2

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	# === Зум колесом мыши ===
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(zoom_speed)

	# === Зум жестом тачпада / сенсорного экрана ===
	if event is InputEventMagnifyGesture:
		# event.factor > 1 — увеличение, < 1 — уменьшение
		var zoom_amount = (event.factor - 1.0) * 0.5  # регулируем чувствительность
		_apply_zoom(zoom_amount)

	# === Начало перетаскивания ===
	if event is InputEventMouseButton and event.button_index == drag_button:
		if event.pressed:
			is_dragging = true
			drag_start = get_global_mouse_position()
			camera_start_position = position
		else:
			is_dragging = false

	# === Перетаскивание камеры ===
	if event is InputEventMouseMotion and is_dragging:
		var mouse_pos = get_global_mouse_position()
		var delta = mouse_pos - drag_start
		position = camera_start_position - delta

func _apply_zoom(amount: float):
	var current_zoom = zoom.x
	var new_zoom = clamp(current_zoom + amount, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)
