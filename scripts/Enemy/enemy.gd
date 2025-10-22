extends Node2D

class_name Enemy

# --- Параметры ---
var move_range: int = 6
var attack_range: int = 1
var health: int = 10
var max_health: int = 10

var weapon: Weapon = null

# --- Состояние ---
var grid_position: Vector2i = Vector2i.ZERO
var target: Node2D = null

# --- Плавное перемещение ---
var target_world_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var move_speed: float = 200.0  # пикселей в секунду

@onready var animated_sprite = $AnimatedSprite2D

# --- Инициализация ---
func _ready():
	set_grid_position(Vector2i(5, 5))
	_set_animation("idle_down")
	weapon = Weapon.new("1d4")

# --- Сетка ---
func set_grid_position(pos: Vector2i):
	grid_position = pos
	# Не меняем position напрямую — оставляем для логики
	# Но можно обновить текущую позицию сразу, если не двигаемся
	if not is_moving:
		position = Vector2(pos.x, pos.y) * 64

func get_grid_position() -> Vector2i:
	return grid_position

# --- Урон и смерть ---
func take_damage(dmg: int):
	health = max(0, health - dmg)
	print("Enemy takes %d damage! HP: %d" % [dmg, health])
	if health <= 0:
		_die()

func _perform_attack():
	if target == null:
		return
	print("Enemy attacks %s!" % target.name)
	if weapon != null and target.has_method("take_damage"):
		var damage = weapon.roll_damage()
		print("Enemy deals %d damage!" % damage)
		target.take_damage(damage)
	else:
		target.take_damage(1)

func _die():
	print("Enemy defeated!")
	queue_free()

# --- ОСНОВНОЙ ХОД (вызывается из боевой системы) ---
func take_turn():
	if is_moving:
		print("Enemy is already moving!")
		return

	if target == null:
		print("Enemy has no target!")
		return

	var target_pos = _get_target_grid()
	if target_pos == Vector2i.ZERO and target != null:
		print("Target has no grid position!")
		return

	var dist = grid_position.distance_to(target_pos)

	if dist <= attack_range:
		_perform_attack()
	else:
		_move_toward_target(target_pos)

# --- Вспомогательные методы ИИ ---
func _get_target_grid() -> Vector2i:
	if target == null:
		return Vector2i.ZERO
	if target.has_method("get_grid_position"):
		return target.get_grid_position()
	return Vector2i.ZERO

func _move_toward_target(target_pos: Vector2i):
	var direction = (target_pos - grid_position).sign()
	var new_grid_pos = grid_position + direction

	# Опционально: проверка на препятствия или границы

	if new_grid_pos != grid_position:
		# Начинаем плавное движение
		target_world_position = Vector2(new_grid_pos.x, new_grid_pos.y) * 64
		is_moving = true
		grid_position = new_grid_pos  # обновляем логическую позицию сразу
		_update_direction(direction)
		print("Enemy starts moving to %s" % new_grid_pos)

# --- Анимация ---
func _update_direction(dir: Vector2i):
	var anim_name = "walk_"
	match dir:
		Vector2i(0, 1):     anim_name += "down"
		Vector2i(0, -1):    anim_name += "up"
		Vector2i(-1, 0):    anim_name += "left"
		Vector2i(1, 0):     anim_name += "right"
		Vector2i(1, 1):     anim_name += "down_right"
		Vector2i(-1, 1):    anim_name += "down_left"
		Vector2i(1, -1):    anim_name += "up_right"
		Vector2i(-1, -1):   anim_name += "up_left"
		_:                  anim_name = "walk_down"
	_set_animation(anim_name)

func _set_animation(name: String):
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(name):
		animated_sprite.play(name)
	else:
		printerr("Animation '%s' not found!" % name)
		animated_sprite.stop()

# --- Плавное перемещение ---
func _process(delta):
	if is_moving:
		var diff = target_world_position - position
		if diff.length() < 1.0:
			# Достигли цели
			position = target_world_position
			is_moving = false
			# Переключаемся на idle-анимацию
			var idle_name = animated_sprite.animation.replace("walk_", "idle_")
			_set_animation(idle_name)
		else:
			position += diff.normalized() * move_speed * delta

# --- Внешний интерфейс ---
func set_target(t: Node2D):
	target = t
