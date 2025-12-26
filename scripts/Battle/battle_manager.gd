extends Node

var units: Array[Unit] = []
var current_turn_index: int = 0
var round: int = 1
var battle_ended: bool = false

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

func _on_actor_health_changed(current_health: int, max_health: int, unit: Unit):
	print("BattleManager: Received health change signal for %s: %d/%d" % [unit.name, current_health, max_health])
	
	if unit.is_player:
		_update_player_health_bar(current_health, max_health)
	
	update_initiative_ui()
	
	if current_health <= 0:
		_remove_dead_unit(unit)

func _update_player_health_bar(current_health: int, max_health: int):
	var ui_hud = get_tree().root.find_child("UiHud", true, false)
	if !ui_hud:
		print("UiHud not found, skipping player health bar update.")
		return

	var player_health_bar = ui_hud.get_node_or_null("HUD/PlayerHealthBar")
	if !player_health_bar or not player_health_bar is ProgressBar:
		print("PlayerHealthBar not found or is not a ProgressBar, skipping update.")
		return

	player_health_bar.max_value = max_health
	player_health_bar.value = current_health
	print("BattleManager: Updated Player Health Bar to %d/%d" % [current_health, max_health])

func start_battle(player_units: Array[Unit], enemy_units: Array[Unit]):
	units.clear()
	units.append_array(player_units)
	units.append_array(enemy_units)
	
	for unit in units:
		_subscribe_to_unit_health_change(unit)

	await _roll_initiative_for_all_units()

	units.sort_custom(func(a, b): return a.initiative > b.initiative)

	print("\n=== Battle Start! Round %d ===" % round)
	print_turn_order()

	update_initiative_ui()

	emit_signal("battle_started")
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

	for child in initiative_order.get_children():
		initiative_order.remove_child(child)
		child.queue_free()

	var hero_initiative_scene = load("res://scenes/Hero_Initiative.tscn") as PackedScene
	var enemy_initiative_scene = load("res://scenes/Enemy_Initiative.tscn") as PackedScene

	for unit in units:
		var scene_to_instance: PackedScene
		if unit.is_player:
			scene_to_instance = hero_initiative_scene
		else:
			scene_to_instance = enemy_initiative_scene

		var instance = scene_to_instance.instantiate()
		instance.name = "InitiativeEntry_%s" % unit.name
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

	if current_turn_index >= units.size():
		current_turn_index = 0
	else:
		var current_unit = units[current_turn_index]
		if !_is_unit_alive(current_unit):
			print("  %s is dead, skipping turn." % current_unit.name)
			_remove_dead_unit(current_unit)
			if current_turn_index >= units.size():
				current_turn_index = 0
		else:
			current_turn_index += 1

	if current_turn_index >= units.size() and !units.is_empty():
		current_turn_index = 0
		round += 1
		print("\n=== Round %d ===" % round)

		check_battle_end()

		if not battle_ended:
			update_initiative_ui()

	if not battle_ended and !units.is_empty():
		await start_next_turn()

func end_battle():
	if battle_ended:
		return
	battle_ended = true
	print("⚔️ Battle ended!")
	emit_signal("battle_ended_signal")
	emit_signal("battle_finished")
	
func check_battle_end():
	print("🔍 Checking battle end...")
	var alive_units = []
	for u in units:
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
	return unit.actor.health > 0

func _remove_dead_unit(unit: Unit):
	if units.has(unit):
		units.erase(unit)
		if unit.actor and !unit.actor.is_queued_for_deletion():
			if unit.actor.get_parent():
				unit.actor.get_parent().remove_child(unit.actor)
			unit.actor.queue_free()
		print("BattleManager: Removed dead unit %s from battle." % unit.name)
		update_initiative_ui()
		if current_turn_index >= units.size() and !units.is_empty():
			current_turn_index = 0
		check_battle_end()
	else:
		print("BattleManager: Attempted to remove unit %s, but it was not in the battle list." % unit.name)

func _roll_initiative_for_all_units():
	var completed_rolls = 0
	var total_rolls = 0

	for unit in units:
		if unit.actor and unit.actor.has_method("roll_initiative_async"):
			total_rolls += 1
			unit.actor.roll_initiative_async(Callable(self, "_on_unit_initiative_rolled").bind(unit))
		else:
			var initiative_value = randi() % 20 + 1 + 10
			unit.initiative = initiative_value
			print("BattleManager: Fallback initiative %d for unit %s (no async method)" % [initiative_value, unit.name])

	print("BattleManager: Waiting for %d initiative rolls to complete." % total_rolls)

	for i in range(total_rolls):
		await self.initiative_roll_completed

	print("BattleManager: All initiative rolls completed.")

func _on_unit_initiative_rolled(initiative_value: int, unit: Unit):
	unit.initiative = initiative_value
	print("BattleManager: Stored initiative %d for unit %s" % [initiative_value, unit.name])
	emit_signal("initiative_roll_completed")
