# BattleManager.gd
extends Node

var units: Array[Unit] = []
var current_turn_index: int = 0
var round: int = 1
var battle_ended: bool = false

# СИГНАЛЫ — ОБЯЗАТЕЛЬНО НА УРОВНЕ КЛАССА
signal player_turn_started(unit)
signal battle_finished

func _ready():
	add_to_group("battle_manager")

# --- ИЗМЕНЕНО: start_battle теперь асинхронная ---
func start_battle(player_units: Array[Unit], enemy_units: Array[Unit]):
	units.clear()
	units.append_array(player_units)
	units.append_array(enemy_units)

	# --- ИЗМЕНЕНО: Используем асинхронные броски для всех юнитов ---
	await _roll_initiative_for_all_units()
	# ---

	# Сортируем очередь после ВСЕХ бросков
	units.sort_custom(func(a, b): return a.initiative > b.initiative)

	print("\n=== Battle Start! Round %d ===" % round)
	print_turn_order()
	# --- ИЗМЕНЕНО: Теперь начинаем ход только после всех бросков ---
	start_next_turn()
	# ---

# --- НОВАЯ ФУНКЦИЯ: Асинхронный бросок инициативы для всех юнитов ---
# --- НОВАЯ ФУНКЦИЯ: Асинхронный бросок инициативы для всех юнитов ---
func _roll_initiative_for_all_units():
	# Создаём счётчик завершённых бросков
	var completed_rolls = 0 # <-- Объявлена здесь
	var total_rolls = 0

	for unit in units:
		if unit.actor and unit.actor.has_method("roll_initiative_async"):
			total_rolls += 1
			# Передаём текущее значение completed_rolls по ссылке или используем замыкание
			# Лучше использовать замыкание через bind для конкретного юнита
			unit.actor.roll_initiative_async(Callable(self, "_on_unit_initiative_rolled").bind(unit))
		else:
			var initiative_value = randi() % 20 + 1 + 10 # Пример: d20 + 10
			unit.initiative = initiative_value
			print("BattleManager: Fallback initiative %d for unit %s (no async method)" % [initiative_value, unit.name])
			# completed_rolls не увеличиваем для fallback, так как он не асинхронный в этом контексте
			# Лучше сразу учитывать fallback в total_rolls и сразу же сигналить для них.
			# Нет, fallback не должен вызывать сигнал, он уже завершён.
			# Пересчитаем total_rolls только для async

	print("BattleManager: Waiting for %d initiative rolls to complete." % total_rolls)

	# Ждём сигнал initiative_roll_completed total_rolls раз
	for i in range(total_rolls):
		await self.initiative_roll_completed

	print("BattleManager: All initiative rolls completed.")


# --- НОВЫЙ СИГНАЛ ---
signal initiative_roll_completed

# --- ИЗМЕНЕНАЯ ФУНКЦИЯ: Обработка результата инициативы юнита ---
func _on_unit_initiative_rolled(initiative_value: int, unit: Unit):
	unit.initiative = initiative_value
	print("BattleManager: Stored initiative %d for unit %s" % [initiative_value, unit.name])
	# --- ОТПРАВЛЯЕМ СИГНАЛ О ЗАВЕРШЕНИИ БРОСКА ---
	emit_signal("initiative_roll_completed")
	# ---

# ---

func print_turn_order():
	for i in units.size():
		print("  %d. %s (Initiative: %d)" % [i + 1, units[i].name, units[i].initiative])

func start_next_turn():
	if units.is_empty():
		end_battle()
		return

	var current_unit = units[current_turn_index]
	print("\n>>> %s's turn <<<" % current_unit.name)

	if current_unit.is_player:
		emit_signal("player_turn_started", current_unit)
	else:
		current_unit.take_turn()
		await get_tree().process_frame
		await next_turn()

func next_turn():
	if battle_ended:
		return

	current_turn_index += 1
	if current_turn_index >= units.size():
		current_turn_index = 0
		round += 1
		print("\n=== Round %d ===" % round)

	# Проверяем, не закончился ли бой
	check_battle_end()

	if not battle_ended:
		await start_next_turn()

func end_battle():
	if battle_ended:
		return
	battle_ended = true
	print("⚔️ Battle ended!")
	emit_signal("battle_finished")

func check_battle_end():
	print("🔍 Checking battle end...")
	var alive_units = []
	for u in units:
		var alive = _is_unit_alive(u)
		# Просто читаем health — он есть у всех боевых актёров
		var hp = "N/A"
		if u.actor and !u.actor.is_queued_for_deletion():
			hp = str(u.actor.health)
		print("  %s (player: %s) — alive: %s, health: %s" % [
			u.name,
			u.is_player,
			alive,
			hp
		])
		if alive:
			alive_units.append(u)

	var players_alive = alive_units.filter(func(u): return u.is_player)
	var enemies_alive = alive_units.filter(func(u): return not u.is_player)

	print("  Players alive: %d, Enemies alive: %d" % [players_alive.size(), enemies_alive.size()])

	if players_alive.is_empty():
		print("💀 All players defeated!")
		end_battle()
	elif enemies_alive.is_empty():
		print("🎉 All enemies defeated!")
		end_battle()

func _is_unit_alive(unit: Unit) -> bool:
	if unit.actor == null:
		return false
	# Не проверяем is_queued_for_deletion — мы не удаляем сразу
	return unit.actor.health > 0

# --- УДАЛЕНО: старые функции _on_player_initiative_rolled и _on_enemy_initiative_rolled ---
