# BattleManager.gd
extends Node

var units: Array[Unit] = []
var current_turn_index: int = 0
var round: int = 1

# Запускается ВРУЧНУЮ извне
func start_battle(player_units: Array[Unit], enemy_units: Array[Unit]):
	units.clear()
	units.append_array(player_units)
	units.append_array(enemy_units)

	for unit in units:
		unit.roll_initiative()

	units.sort_custom(func(a, b): return a.initiative > b.initiative)

	print("\n=== Battle Start! Round %d ===" % round)
	print_turn_order()
	start_next_turn()

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
	current_turn_index += 1
	if current_turn_index >= units.size():
		current_turn_index = 0
		round += 1
		print("\n=== Round %d ===" % round)
	await start_next_turn()  # ← await здесь

func end_battle():
	print("Battle ended!")
	emit_signal("battle_finished")

# Сигналы
signal player_turn_started(unit)
signal battle_finished
