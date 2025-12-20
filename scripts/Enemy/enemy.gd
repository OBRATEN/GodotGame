# Enemy.gd
extends Node2D

class_name Enemy

# --- Параметры ---
var move_range: int = 6
var attack_range: float = 1.5
var health: int
var max_health: int = 10
var weapon: Weapon = null

# --- Состояние ---
var grid_position: Vector2i = Vector2i.ZERO
var target_node_name: String = "" # Храним имя цели, чтобы находить её каждый ход

# --- Плавное перемещение ---
var target_world_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var move_speed: float = 200.0  # пикселей в секунду

# --- Инициализация ---
func _ready():
	health = max_health
	# Позиция будет задана извне (например, из World.gd)
	weapon = Weapon.new("1d4")
	add_to_group("enemies")

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
	# Ищем цель каждый раз перед атакой
	var current_target = _find_target()
	if current_target == null:
		print("Enemy %s: No target found to attack!" % name)
		return

	print("Enemy attacks %s!" % current_target.name)
	if weapon != null and current_target.has_method("take_damage"):
		var damage = weapon.roll_damage()
		print("Enemy deals %d damage!" % damage)
		current_target.take_damage(damage)

		# Проверка окончания боя
		var bm = get_tree().get_first_node_in_group("battle_manager")
		if bm:
			bm.check_battle_end()
	else:
		current_target.take_damage(1)
		var bm = get_tree().get_first_node_in_group("battle_manager")
		if bm:
			bm.check_battle_end()

func _die():
	if health <= 0:
		print("Enemy defeated!")
		# animated_sprite.hide() # Убрано
		# Не queue_free сразу — BattleManager читает health
		# queue_free() вызовется позже, если нужно

func take_turn():
	if is_moving:
		print("Enemy is already moving!")
		return

	# Ищем цель каждый раз перед ходом
	var current_target = _find_target()
	if current_target == null:
		print("Enemy %s: No target found for turn!" % name)
		return

	var target_pos = _get_target_grid(current_target) # Передаём цель
	if target_pos == Vector2i.ZERO:
		print("Enemy %s: target has no grid position!" % name)
		return

	var dist = grid_position.distance_to(target_pos) # <-- Вычисляем расстояние

	if dist <= attack_range:        # <-- Проверяем расстояние
		_perform_attack()       # <-- Если <= 1, атакуем
	else:
		print("Distance: ", dist, attack_range)
		_move_toward_target(target_pos, dist) # <-- Иначе, идём к цели

func _find_target() -> Node2D:
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.is_empty():
		print_debug("No nodes found in 'player' group.")
		return null

	# Проходим по всем игрокам, чтобы найти ближайшего в зоне видимости
	var closest_player: Node2D = null
	var closest_distance = 999999.0 # <-- Инициализация
	print_debug("  -> DEBUG: Initial closest_distance: %s" % closest_distance) # <-- НОВАЯ СТРОКА
	# var closest_distance = 0.0 # <-- Проверим, что инициализация не сбрасывается случайно

	for player_node in player_nodes:
		if not player_node.has_method("get_grid_position"):
			print_debug("Player node %s has no get_grid_position method." % player_node.name)
			continue

		var player_grid_pos = player_node.get_grid_position()
		var my_grid_pos = self.get_grid_position()

		print_debug("Checking player %s at %s vs enemy %s at %s" % [player_node.name, player_grid_pos, name, my_grid_pos])

		# 1. Проверяем расстояние (евклидово)
		var distance = my_grid_pos.distance_to(player_grid_pos)
		print_debug("  -> Distance: %.2f (limit 6)" % distance)

		if distance > 6: # Радиус видимости
			print_debug("  -> OUT OF RANGE.")
			continue

		# 2. Проверяем прямую видимость
		var has_loS = _has_line_of_sight(my_grid_pos, player_grid_pos)
		print_debug("  -> Has Line of Sight: %s" % has_loS)

		if not has_loS:
			print_debug("  -> NO LINE OF SIGHT, skipping player %s." % player_node.name)
			continue

		# 3. Если видим и ближе, чем предыдущий, запоминаем
		# --- ДОБАВЛЕНА ОТЛАДКА ---
		print_debug("  -> DEBUG: Before comparison - distance: %.2f, closest_distance: %.2f" % [distance, closest_distance]) # <-- НОВАЯ СТРОКА
		if distance < closest_distance:
			print_debug("  -> Distance %.2f is less than closest_distance %.2f. Updating target." % [distance, closest_distance])
			closest_player = player_node
			closest_distance = distance
			print_debug("  -> NEW closest visible player: %s at distance %.2f" % [closest_player.name, closest_distance])
		else:
			# <-- Вот ЭТА строка появляется в логе!
			print_debug("  -> Distance %.2f is NOT less than closest_distance %.2f. Not updating target." % [distance, closest_distance])
		# ---

	if closest_player:
		print_debug("Enemy %s spotted player %s!" % [name, closest_player.name])
	else:
		print_debug("Enemy %s sees no players." % name)

	return closest_player
	
func _get_target_grid(target_node: Node2D) -> Vector2i:
	if target_node == null:
		return Vector2i.ZERO
	if target_node.has_method("get_grid_position"):
		return target_node.get_grid_position()
	return Vector2i.ZERO

# --- ИЗМЕНЕНАЯ ФУНКЦИЯ: Принимает target_pos и dist ---
# --- ИЗМЕНЕНАЯ ФУНКЦИЯ: Принимает target_pos и dist ---
func _move_toward_target(target_pos: Vector2i, dist_to_target: int):
	# Вычисляем направление к цели
	var direction = (target_pos - grid_position).sign()
	var new_grid_pos = grid_position + direction

	# Проверка: не занята ли целевая клетка (куда враг хотел бы пойти)
	if _is_grid_occupied_by_others(new_grid_pos):
		print("Enemy %s: target cell %s is occupied. Looking for an adjacent free cell." % [name, new_grid_pos])

		# Ищем ближайшую свободную клетку рядом с целевой
		var free_adjacent_pos = _find_free_adjacent_cell(target_pos)
		if free_adjacent_pos != Vector2i.ZERO:
			# Направление теперь к найденной свободной клетке
			# Проверим, улучшит ли это положение (сократит ли дистанцию)
			var dist_to_adjacent = grid_position.distance_to(free_adjacent_pos)
			if dist_to_adjacent <= dist_to_target:
				# Только если новое положение не хуже, двигаемся к нему
				direction = (free_adjacent_pos - grid_position).sign()
				new_grid_pos = grid_position + direction
				# Повторно проверяем, может ли враг попасть на *эту* новую клетку
				if new_grid_pos != grid_position and !_is_grid_occupied_by_others(new_grid_pos):
					# ДОБАВЛЕНО: Проверка на проходимость КЛЕТКИ, на которую враг хочет встать
					var world_node = get_parent()
					if world_node and world_node.has_method("_is_walkable"):
						if world_node._is_walkable(new_grid_pos):
							# Целевая позиция — центр тайла
							target_world_position = Vector2(
								new_grid_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
								new_grid_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
							)
							is_moving = true
							grid_position = new_grid_pos  # обновляем логическую позицию сразу
							# _update_direction(direction) # Убрано
							print("Enemy %s starts moving to %s (adjacent to target %s)" % [name, new_grid_pos, target_pos])
							return
						else:
							print("Enemy %s: Found adjacent cell %s, but it's not walkable (wall/arch)." % [name, new_grid_pos])
					else:
						print("Warning: Could not check walkability for %s, assuming it's walkable." % new_grid_pos)
						# Целевая позиция — центр тайла
						target_world_position = Vector2(
							new_grid_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
							new_grid_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
						)
						is_moving = true
						grid_position = new_grid_pos  # обновляем логическую позицию сразу
						# _update_direction(direction) # Убрано
						print("Enemy %s starts moving to %s (adjacent to target %s)" % [name, new_grid_pos, target_pos])
						return
				else:
					print("Enemy %s: Could not find a valid path to an adjacent cell near target %s." % [name, target_pos])
					# Если путь заблокирован, пропускаем ход
					return
			else:
				print("Enemy %s: Found adjacent cell %s, but it's further than current target cell. Staying put." % [name, free_adjacent_pos])
				# Не двигаемся, если найденная клетка хуже текущего положения
				return
		else:
			print("Enemy %s: No free adjacent cells found near target %s." % [name, target_pos])
			# Если нет свободных клеток рядом, пропускаем ход
			return

	# Если целевая клетка не занята, действуем как раньше
	# ДОБАВЛЕНО: Проверка на проходимость КЛЕТКИ, на которую враг хочет встать
	var world_node = get_parent()
	if world_node and world_node.has_method("_is_walkable"):
		if world_node._is_walkable(new_grid_pos):
			if new_grid_pos != grid_position:
				# Целевая позиция — центр тайла
				target_world_position = Vector2(
					new_grid_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
					new_grid_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
				)
				is_moving = true
				grid_position = new_grid_pos  # обновляем логическую позицию сразу
				# _update_direction(direction) # Убрано
				print("Enemy %s starts moving to %s" % [name, new_grid_pos])
		else:
			print("Enemy %s: Target cell %s is not walkable (wall/arch)." % [name, new_grid_pos])
			# Если клетка непроходима, ищем свободную соседнюю клетку рядом с целью
			var free_adjacent_pos = _find_free_adjacent_cell(target_pos)
			if free_adjacent_pos != Vector2i.ZERO:
				# Направление теперь к найденной свободной клетке
				# Проверим, улучшит ли это положение (сократит ли дистанцию)
				var dist_to_adjacent = grid_position.distance_to(free_adjacent_pos)
				if dist_to_adjacent <= dist_to_target:
					# Только если новое положение не хуже, двигаемся к нему
					direction = (free_adjacent_pos - grid_position).sign()
					new_grid_pos = grid_position + direction
					# Повторно проверяем, может ли враг попасть на *эту* новую клетку
					if new_grid_pos != grid_position and !_is_grid_occupied_by_others(new_grid_pos):
						# ДОБАВЛЕНО: Проверка на проходимость КЛЕТКИ, на которую враг хочет встать
						if world_node._is_walkable(new_grid_pos):
							# Целевая позиция — центр тайла
							target_world_position = Vector2(
								new_grid_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
								new_grid_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
							)
							is_moving = true
							grid_position = new_grid_pos  # обновляем логическую позицию сразу
							# _update_direction(direction) # Убрано
							print("Enemy %s starts moving to %s (adjacent to target %s)" % [name, new_grid_pos, target_pos])
							return
						else:
							print("Enemy %s: Found adjacent cell %s, but it's not walkable (wall/arch)." % [name, new_grid_pos])
				else:
					print("Enemy %s: Found adjacent cell %s, but it's further than current target cell. Staying put." % [name, free_adjacent_pos])
			else:
				print("Enemy %s: No free adjacent cells found near target %s." % [name, target_pos])
				# Если нет свободных клеток рядом, пропускаем ход
				return
	else:
		print("Warning: Could not check walkability for %s, assuming it's walkable." % new_grid_pos)
		if new_grid_pos != grid_position:
			# Целевая позиция — центр тайла
			target_world_position = Vector2(
				new_grid_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
				new_grid_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
			)
			is_moving = true
			grid_position = new_grid_pos  # обновляем логическую позицию сразу
			# _update_direction(direction) # Убрано
			print("Enemy %s starts moving to %s" % [name, new_grid_pos])
			
# --- Поиск свободной клетки рядом ---
func _find_free_adjacent_cell(target_pos: Vector2i) -> Vector2i:
	# Проверяем 4 основных направления (вверх, вниз, влево, вправо)
	var directions = [
		Vector2i(0, -1), # вверх
		Vector2i(0, 1),  # вниз
		Vector2i(-1, 0), # влево
		Vector2i(1, 0)   # вправо
	]

	for dir in directions:
		var adjacent_pos = target_pos + dir
		# Проверяем, свободна ли клетка (не занята другим юнитом)
		if !_is_grid_occupied_by_others(adjacent_pos):
			# Проверяем, можно ли туда пройти (например, нет стены)
			# Предположим, что у World.gd есть доступ к tilemap и функции _is_walkable
			var world_node = get_parent()
			if world_node and world_node.has_method("_is_walkable"):
				if world_node._is_walkable(adjacent_pos):
					return adjacent_pos
			else:
				# Если не можем проверить проходимость, просто возвращаем первую свободную
				# В реальном проекте стоит передать ссылку на функцию проверки или сам tilemap
				print("Warning: Could not check walkability for %s, assuming it's walkable." % adjacent_pos)
				return adjacent_pos

	# Если основные направления заняты, проверим диагонали (опционально)
	var diagonal_directions = [
		Vector2i(-1, -1), # вверх-влево
		Vector2i(1, -1),  # вверх-вправо
		Vector2i(-1, 1),  # вниз-влево
		Vector2i(1, 1)    # вниз-вправо
	]

	for dir in diagonal_directions:
		var adjacent_pos = target_pos + dir
		if !_is_grid_occupied_by_others(adjacent_pos):
			var world_node = get_parent()
			if world_node and world_node.has_method("_is_walkable"):
				if world_node._is_walkable(adjacent_pos):
					return adjacent_pos
			else:
				print("Warning: Could not check walkability for %s, assuming it's walkable." % adjacent_pos)
				return adjacent_pos

	# Если все соседние клетки заняты или непроходимы
	return Vector2i.ZERO


# --- Плавное перемещение ---
func _process(delta):
	if is_moving:
		var diff = target_world_position - position
		if diff.length() < 1.0:
			# Достигли цели
			position = target_world_position
			is_moving = false
			# _set_animation(idle_name) # Убрано
		else:
			position += diff.normalized() * move_speed * delta

# --- Внешний интерфейс ---
# Убираем старый метод set_target
# func set_target(t: Node2D):
# 	target = t

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

# Enemy.gd
# ... (предполагаем, что у Enemy есть CharacterSheet, health, и т.д.) ...

func roll_initiative_async(callback: Callable):
	# Получаем модификатор ловкости из CharacterSheet
	var dex_mod = 2
	print("%s dexterity modifier: %d" % [name, dex_mod])

	var ui_hud = get_tree().get_first_node_in_group("ui_hud")
	if ui_hud:
		var dice_roller = ui_hud.find_child("DiceRoller", true, false)
		if dice_roller and dice_roller.has_method("roll_dice_visual_async"):
			var dice_sides = 20
			dice_roller.roll_dice_visual_async(dice_sides, Callable(self, "_on_initiative_roll_finished").bind(callback, dex_mod))
		else:
			print("DiceRoller not found inside UiHud or invalid, using standard roll for initiative.")
			# --- ИЗМЕНЕНО: Вызываем стандартный бросок асинхронно ---
			_call_standard_initiative_roll_async(callback, dex_mod)
			# ---
	else:
		print("UiHud not found, using standard roll for initiative.")
		# --- ИЗМЕНЕНО: Вызываем стандартный бросок асинхронно ---
		_call_standard_initiative_roll_async(callback, dex_mod)
		# ---

func _on_initiative_roll_finished(roll_result: int, callback: Callable, dex_mod: int):
	var total_initiative = roll_result + dex_mod
	print("%s visual initiative roll result: %d + %d = %d" % [name, roll_result, dex_mod, total_initiative])
	callback.call(total_initiative)

# --- НОВАЯ ФУНКЦИЯ: Асинхронный стандартный бросок ---
func _call_standard_initiative_roll_async(callback: Callable, dex_mod: int):
	var roll_result = randi() % 20 + 1
	var total_initiative = roll_result + dex_mod
	print("%s standard initiative roll result: %d + %d = %d" % [name, roll_result, dex_mod, total_initiative])
	# Используем call_deferred, чтобы вызов произошёл в следующем цикле обновления,
	# тем самым симулируя асинхронное поведение и позволяя await в BattleManager дождаться этого.
	call_deferred("_deferred_callback_call", callback, total_initiative)

func _deferred_callback_call(callback: Callable, value: int):
	callback.call(value)
# ---

# --- В файл Enemy.gd ---

# Добавьте этот метод в класс Enemy
# --- В файл Enemy.gd ---
# ЗАМЕНИТЕ метод _has_line_of_sight на этот (с отладкой):

func _has_line_of_sight(start_pos: Vector2i, end_pos: Vector2i) -> bool:
	print_debug("LoS check from %s to %s" % [start_pos, end_pos])
	
	var dx = abs(end_pos.x - start_pos.x)
	var dy = abs(end_pos.y - start_pos.y)
	var sx = 1 if start_pos.x < end_pos.x else -1
	var sy = 1 if start_pos.y < end_pos.y else -1
	var err = dx - dy

	var x = start_pos.x
	var y = start_pos.y

	while true:
		var current_pos = Vector2i(x, y)
		print_debug("  -> Checking tile at %s" % current_pos)

		# Не проверяем начальную клетку (где стоит сам враг)
		if current_pos != start_pos:
			var world_ref = get_parent()
			if not world_ref or not world_ref.has_method("_is_tile_blocking_vision"):
				print_debug("  -> ERROR: Cannot access World.gd or _is_tile_blocking_vision method!")
				return false # <-- Если метод недоступен, путь точно не свободен

			if world_ref._is_tile_blocking_vision(current_pos):
				print_debug("  -> LoS BLOCKED at %s by tile" % current_pos)
				return false  # Путь заблокирован препятствием
			else:
				print_debug("  -> Tile at %s is clear" % current_pos)
		else:
			print_debug("  -> Skipping start tile %s" % current_pos)

		if x == end_pos.x and y == end_pos.y:
			print_debug("  -> Reached target %s, LoS CLEAR!" % end_pos)
			break # Добрались до цели

		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy

	return true # Путь свободен
