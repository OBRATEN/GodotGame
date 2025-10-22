# Enemy.gd
extends Node2D

class_name Enemy

# --- Параметры ---
var move_range: int = 6
var attack_range: int = 1

# --- Состояния ---
enum State { IDLE, MOVING, ATTACKING }
var state: State = State.IDLE

# --- Сетка ---
var grid_position: Vector2i = Vector2i.ZERO

# --- Цель ---
var target: Node2D = null

# --- Ссылки ---
@onready var animated_sprite = $AnimatedSprite2D

# --- Инициализация ---
func _ready():
	set_grid_position(Vector2i(5, 5))  # пример начальной позиции
	_set_animation("idle_down")       # начальное направление

# Устанавливает позицию на сетке и обновляет мировую позицию
func set_grid_position(pos: Vector2i):
	grid_position = pos
	position = Vector2(pos.x, pos.y) * 64  # 64 = размер клетки

func get_grid_position() -> Vector2i:
	return grid_position

func set_target(t: Node2D):
	target = t

# --- Основной ход ---
func take_turn():
	if target == null:
		print("Enemy has no target!")
		return

	var target_pos = target.get_grid_position() if target.has_method("get_grid_position") else grid_position
	var dist = grid_position.distance_to(target_pos)

	if dist <= attack_range:
		perform_attack()
	else:
		move_toward_target()

# --- Атака ---
func perform_attack():
	state = State.ATTACKING
	print("Enemy attacks %s!" % target.name)
	# Здесь можно добавить урон, эффекты и т.д.
	state = State.IDLE

# --- Движение к цели (8 направлений) ---
func move_toward_target():
	var target_pos = target.get_grid_position() if target.has_method("get_grid_position") else grid_position
	var direction = (target_pos - grid_position).sign()  # Vector2i(-1..1, -1..1)

	# Ограничиваем шаг одним тайлом за ход (можно сделать больше)
	var new_pos = grid_position + direction

	# (Опционально: проверка на препятствия или границы)

	if new_pos != grid_position:
		set_grid_position(new_pos)
		_update_direction(direction)

	print("Enemy moves to %s" % new_pos)

# --- Обновление анимации по направлению ---
func _update_direction(dir: Vector2i):
	var anim_name = "idle_"
	
	match dir:
		Vector2i(0, 1):     anim_name += "down"
		Vector2i(0, -1):    anim_name += "up"
		Vector2i(-1, 0):    anim_name += "left"
		Vector2i(1, 0):     anim_name += "right"
		Vector2i(1, 1):     anim_name += "down_right"
		Vector2i(-1, 1):    anim_name += "down_left"
		Vector2i(1, -1):    anim_name += "up_right"
		Vector2i(-1, -1):   anim_name += "up_left"
		_:                  anim_name = "idle_down"  # fallback

	_set_animation(anim_name)

# --- Установка анимации с проверкой ---
func _set_animation(name: String):
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(name):
		animated_sprite.play(name)
	else:
		printerr("Animation '%s' not found in AnimatedSprite2D!" % name)
		animated_sprite.stop()
