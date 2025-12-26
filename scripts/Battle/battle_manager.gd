# BattleManager.gd
extends Node

var units: Array[Unit] = []
var current_turn_index: int = 0
var round: int = 1
var battle_ended: bool = false

# СИГНАЛЫ — ОБЯЗАТЕЛЬНО НА УРОВНЕ КЛАССА
signal player_turn_started(unit)
signal battle_finished
signal initiative_roll_completed
signal battle_started
signal battle_ended_signal
signal actor_health_changed

func _ready():
	add_to_group("battle_manager")
	
func _subscribe_to_unit_health_change(unit: Unit):
	if unit.actor and unit.actor.is_connected("health_changed", Callable(self, "_on_actor_health_changed")) == false:
		unit.actor.connect("health_changed", Callable(self, "_on_actor_health_changed").bind(unit))

# НОВАЯ ФУНКЦИЯ: Обработчик сигнала здоровья
func _on_actor_health_changed(current_health: int, max_health: int, unit: Unit):
	print("BattleManager: Received health change signal for %s: %d/%d" % [unit.name, current_health, max_health])
	# Обновляем UI инициативы, где отображается здоровье
	update_initiative_ui()
	
	# Проверяем, не умер ли юнит
	if current_health <= 0:
		_remove_dead_unit(unit)

# --- ИЗМЕНЕНО: start_battle теперь асинхронная ---
func start_battle(player_units: Array[Unit], enemy_units: Array[Unit]):
	units.clear()
	units.append_array(player_units)
	units.append_array(enemy_units)
	
	for unit in units:
		_subscribe_to_unit_health_change(unit)

	# --- ИЗМЕНЕНО: Используем асинхронные броски для всех юнитов ---
	await _roll_initiative_for_all_units()
	# ---

	# Сортируем очередь после ВСЕХ бросков
	units.sort_custom(func(a, b): return a.initiative > b.initiative)

	print("\n=== Battle Start! Round %d ===" % round)
	print_turn_order()

	# --- ДОБАВЛЕНО: Обновляем UI инициативы ---
	update_initiative_ui()
	# ---

	emit_signal("battle_started") # <-- Добавить эту строку ПОСЛЕ update_initiative_ui()

	start_next_turn()

func update_initiative_ui():
	var ui_hud = get_tree().root.find_child("UiHud", true, false)
	if !ui_hud:
		print("UiHud not found, skipping initiative UI update.")
		return

	var initiative_border = ui_hud.get_node("HUD/InitiativeFolder/InitiativeBorder")
	if !initiative_border:
		print("InitiativeBorder not found, skipping initiative UI update.")
		return

	var initiative_order = initiative_border.get_node("InitiativeOrder")
	if !initiative_order:
		print("InitiativeOrder not found, skipping initiative UI update.")
		return

	# --- ИЗМЕНЕНО: Очищаем дочерние элементы через цикл ---
	# Перебираем копию списка дочерних узлов (get_children() возвращает копию)
	for child in initiative_order.get_children():
		initiative_order.remove_child(child) # Удаляем узел из родителя
		child.queue_free() # Помещаем узел в очередь на удаление
	# ---

	# --- ИЗМЕНЕНО: Загружаем сцены заранее ---
	var hero_initiative_scene = load("res://scenes/Hero_Initiative.tscn") as PackedScene
	var enemy_initiative_scene = load("res://scenes/Enemy_Initiative.tscn") as PackedScene
	# ---

	# Добавляем элементы в порядке инициативы
	for unit in units:
		var scene_to_instance: PackedScene
		if unit.is_player:
			scene_to_instance = hero_initiative_scene
		else:
			scene_to_instance = enemy_initiative_scene

		var instance = scene_to_instance.instantiate()
		instance.name = "InitiativeEntry_%s" % unit.name
		# Передаём данные в инстанс
		if instance.has_method("set_unit_data"):
			instance.set_unit_data(unit.name, unit.initiative, unit.actor.health, unit.actor.max_health)
		else:
			if instance.has_property("unit_name"):
				instance.unit_name = unit.name
			if instance.has_property("initiative_value"):
				instance.initiative_value = unit.initiative
			if instance.has_property("health"):
				instance.health = unit.actor.health
			if instance.has_property("max_health"):
				instance.max_health = unit.actor.max_health
		initiative_order.add_child(instance)

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

	# --- ИЗМЕНЕНО: Обновляем current_turn_index после проверки смерти ---
	# Если юнит умер и был удалён, current_turn_index может указывать не на того юнита
	# Поэтому сначала проверяем, жив ли текущий юнит
	if current_turn_index >= units.size():
		# Индекс вышел за пределы после удаления юнита, сбросим на 0
		current_turn_index = 0
	else:
		var current_unit = units[current_turn_index]
		if !_is_unit_alive(current_unit):
			# Если текущий юнит мёртв, пропускаем его
			print("  %s is dead, skipping turn." % current_unit.name)
			# Удаляем мёртвого юнита из списка
			_remove_dead_unit(current_unit)
			# current_turn_index остаётся тем же, но указывает на следующего юнита в списке
			# Если после удаления индекс стал >= units.size(), сбросим на 0
			if current_turn_index >= units.size():
				current_turn_index = 0
		else:
			# Если жив, переходим к следующему
			current_turn_index += 1

	# Проверяем, не нужно ли перейти к следующему раунду
	if current_turn_index >= units.size() and !units.is_empty():
		current_turn_index = 0
		round += 1
		print("\n=== Round %d ===" % round)

		# Проверяем, не закончился ли бой
		check_battle_end()

		if not battle_ended:
			# --- ДОБАВЛЕНО: Обновляем UI инициативы каждый раунд ---
			update_initiative_ui()
			# ---

	if not battle_ended and !units.is_empty():
		await start_next_turn()

func end_battle():
	if battle_ended:
		return
	battle_ended = true
	print("⚔️ Battle ended!")
	emit_signal("battle_ended_signal") # <-- Заменить или добавить эту строку
	emit_signal("battle_finished") # <-- Оставить эту строку
	
func check_battle_end():
	# Эта функция теперь вызывается после удаления юнитов, так что units уже обновлён
	print("🔍 Checking battle end...")
	var alive_units = []
	for u in units: # Проверяем только оставшихся в списке юнитов
		var alive = _is_unit_alive(u)
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

# --- НОВАЯ ФУНКЦИЯ: Удаляет мёртвого юнита из списка и сцены ---
func _remove_dead_unit(unit: Unit):
	if units.has(unit):
		units.erase(unit)
		# Опционально: удалить визуальный узел актёра с карты, если он есть
		if unit.actor and !unit.actor.is_queued_for_deletion():
			# Проверяем, есть ли у актёра родитель (например, на карте)
			if unit.actor.get_parent():
				unit.actor.get_parent().remove_child(unit.actor)
			unit.actor.queue_free()
		print("BattleManager: Removed dead unit %s from battle." % unit.name)
		# Обновляем UI, так как юнит ушёл
		update_initiative_ui()
		# Обновляем индекс текущего хода, если он превышает новый размер списка
		if current_turn_index >= units.size() and !units.is_empty():
			current_turn_index = 0
		# Проверяем конец боя, так как юнит ушёл
		check_battle_end()
	else:
		print("BattleManager: Attempted to remove unit %s, but it was not in the battle list." % unit.name)

# --- ИЗМЕНЕНАЯ ФУНКЦИЯ: Асинхронный бросок инициативы для всех юнитов ---
func _roll_initiative_for_all_units():
	var completed_rolls = 0
	var total_rolls = 0

	for unit in units:
		if unit.actor and unit.actor.has_method("roll_initiative_async"):
			total_rolls += 1
			unit.actor.roll_initiative_async(Callable(self, "_on_unit_initiative_rolled").bind(unit))
		else:
			var initiative_value = randi() % 20 + 1 + 10 # Пример: d20 + 10
			unit.initiative = initiative_value
			print("BattleManager: Fallback initiative %d for unit %s (no async method)" % [initiative_value, unit.name])
			# Для fallback не увеличиваем completed_rolls, так как он не асинхронный в этом контексте

	print("BattleManager: Waiting for %d initiative rolls to complete." % total_rolls)

	# Ждём сигнал initiative_roll_completed total_rolls раз
	for i in range(total_rolls):
		await self.initiative_roll_completed

	print("BattleManager: All initiative rolls completed.")

# --- ИЗМЕНЕНАЯ ФУНКЦИЯ: Обработка результата инициативы юнита ---
func _on_unit_initiative_rolled(initiative_value: int, unit: Unit):
	unit.initiative = initiative_value
	print("BattleManager: Stored initiative %d for unit %s" % [initiative_value, unit.name])
	emit_signal("initiative_roll_completed")

# --- УДАЛЕНО: старые функции _on_player_initiative_rolled и _on_enemy_initiative_rolled ---
