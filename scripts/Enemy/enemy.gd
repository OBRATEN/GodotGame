# Enemy.gd
extends Node2D

class_name Enemy

# --- Параметры ---
var move_range: int = 6
var attack_range: int = 1
var health: int
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
	health = max_health
	# Позиция будет задана извне (например, из World.gd)
	_set_animation("idle_down")
	weapon = Weapon.new("1d4")

# --- Сетка ---
func set_grid_position(pos: Vector2i):
	grid_position = pos
	if not is_moving:
		# Центрируем на тайле!
		position = Vector2(
			pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
			pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
		)

func get_grid_position() -> Vector2i:
	return grid_position

# --- Урон и смерть ---
func take_damage(dmg: int):
	print("Enemy %s takes %d damage! Current HP: %d" % [name, dmg, health])
	health = max(0, health - dmg)
	print(" → New HP: %d" % health)
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

		# Проверка окончания боя
		var bm = get_tree().get_first_node_in_group("battle_manager")
		if bm:
			bm.check_battle_end()
	else:
		target.take_damage(1)
		var bm = get_tree().get_first_node_in_group("battle_manager")
		if bm:
			bm.check_battle_end()

func _die():
	if health <= 0:
		print("Enemy defeated!")
		if animated_sprite:
			animated_sprite.hide()
		# Не queue_free сразу — BattleManager читает health
		# queue_free() вызовется позже, если нужно

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

	# Проверка: не занята ли клетка другим юнитом
	if _is_grid_occupied_by_others(new_grid_pos):
		print("Enemy %s: cell %s is occupied — cannot move!" % [name, new_grid_pos])
		return

	if new_grid_pos != grid_position:
		# Целевая позиция — центр тайла
		target_world_position = Vector2(
			new_grid_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
			new_grid_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
		)
		is_moving = true
		grid_position = new_grid_pos  # обновляем логическую позицию сразу
		_update_direction(direction)
		print("Enemy %s starts moving to %s" % [name, new_grid_pos])

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

# --- Проверка занятости клетки ---
func _is_grid_occupied_by_others(grid_pos: Vector2i) -> bool:
	var bm = get_tree().get_first_node_in_group("battle_manager")
	if bm == null:
		return false

	for unit in bm.units:
		if unit.actor == null or unit.actor.is_queued_for_deletion():
			continue
		if !_is_unit_alive(unit):
			continue
		if unit.actor == self:
			continue  # пропускаем себя
		if unit.actor.get_grid_position() == grid_pos:
			return true
	return false

func _is_unit_alive(unit) -> bool:
	if unit.actor == null:
		return false
	return unit.actor.health > 0
