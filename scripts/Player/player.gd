extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)

var grid_position: Vector2i = Vector2i.ZERO
var target_grid_position: Vector2i = Vector2i.ZERO

var move_speed: float = 128.0
var is_moving: bool = false

var health: int = 20
var max_health: int = 20
var max_attacks_per_turn: int = 1
var attacks_used: int = 0
var move_range: int = 6
var remaining_move: int = 6 

var sheet: CharacterSheet = CharacterSheet.new()

func _ready():
	var initial_world_pos = position
	grid_position = Vector2i(
		floor((initial_world_pos.x - Constants.CELL_SIZE / 2) / Constants.CELL_SIZE + 0.5),
		floor((initial_world_pos.y - Constants.CELL_SIZE / 2) / Constants.CELL_SIZE + 0.5)
	)
	target_grid_position = grid_position
	set_grid_position(grid_position)

	sheet.strength = 16
	sheet.dexterity = 14
	sheet.constitution = 12
	sheet.update_derived_stats()
	
	sheet.weapon = Weapon.new("1d8")
	sheet.max_hit_points = 12
	sheet.current_hit_points = 12
	max_health = sheet.max_hit_points
	health = sheet.current_hit_points
	add_to_group("player")
	
	reset_turn()

func reset_turn():
	remaining_move = move_range
	attacks_used = 0
	print("Player turn reset. Move: %d, Attacks: %d/%d" % [
		remaining_move, attacks_used, max_attacks_per_turn
	])
	
func can_attack() -> bool:
	return attacks_used < max_attacks_per_turn
	
func use_attack():
	if can_attack():
		attacks_used += 1
		print("Attack used. %d/%d" % [attacks_used, max_attacks_per_turn])
	else:
		print("No attacks left!")

func set_grid_position(pos: Vector2i):
	grid_position = pos
	target_grid_position = pos
	position = Vector2(
		pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
		pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
	)
	is_moving = false

func start_move_to(target: Vector2i):
	if is_moving:
		return
	if target == grid_position:
		return

	target_grid_position = target
	is_moving = true
	print("Player starts moving from %s to %s" % [grid_position, target_grid_position])

func _process(delta):
	if is_moving:
		var target_world = Vector2(
			target_grid_position.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
			target_grid_position.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
		)
		var direction = (target_world - position).normalized()
		var distance_to_target = position.distance_to(target_world)
		
		if distance_to_target <= move_speed * delta:
			position = target_world
			grid_position = target_grid_position
			is_moving = false
			_on_reached_target()
		else:
			position += direction * move_speed * delta

func get_grid_position() -> Vector2i:
	return grid_position
	
func move_to_grid(target: Vector2i):
	if is_moving:
		return
	
	if (target - grid_position).length() > 1:
		return
	
	target_grid_position = target
	is_moving = true

func _on_reached_target():
	print("Player reached target grid:", grid_position)

func take_turn():
	print("Player's turn started.")

func take_damage(dmg: int):
	sheet.take_damage(dmg)
	print("Player takes %d damage! HP: %d" % [dmg, sheet.current_hit_points])
	health = sheet.current_hit_points
	emit_signal("health_changed", health, max_health)
	if health <= 0:
		_die()

func _die():
	print("Player has died!")

func attack_target(target: Node2D):
	if attacks_used >= max_attacks_per_turn:
		print("Cannot attack: no attacks left this turn!")
		return

	if sheet.weapon == null:
		print("No weapon!")
		return
	if not target.has_method("take_damage"):
		print("Target cannot take damage!")
		return

	var ui_hud = get_tree().root.find_child("UiHud", true, false)

	if ui_hud:
		var dice_roller = ui_hud.find_child("DiceRoller", true, false)
		if dice_roller and dice_roller.has_method("roll_dice_visual_async"):
			var weapon_notation = sheet.weapon.dice_notation
			var sides = extract_dice_sides(weapon_notation)
			if sides > 0:
				dice_roller.roll_dice_visual_async(sides, Callable(self, "_on_dice_roll_finished").bind(target))
			else:
				print("Could not extract dice sides from notation: %s, using standard roll." % weapon_notation)
				var damage = sheet.weapon.roll_damage()
				_apply_damage_to_target(target, damage)
		else:
			print("DiceRoller not found inside UiHud or invalid, using standard roll.")
			var damage = sheet.weapon.roll_damage()
			_apply_damage_to_target(target, damage)
	else:
		print("UiHud not found, using standard roll.")
		var damage = sheet.weapon.roll_damage()
		_apply_damage_to_target(target, damage)

func _on_dice_roll_finished(damage: int, target: Node2D):
	print("Visual dice roll result: %d" % damage)
	_apply_damage_to_target(target, damage)

func _apply_damage_to_target(target: Node2D, damage: int):
	print("Player attacks %s for %d damage!" % [target.name, damage])
	target.take_damage(damage)
	use_attack()

	var bm = get_tree().get_first_node_in_group("battle_manager")
	if bm:
		bm.check_battle_end()

func extract_dice_sides(dice_notation: String) -> int:
	var notation = dice_notation.strip_edges().to_lower()
	if notation.is_empty():
		return 0

	var plus_split = notation.split("+")
	var dice_part = plus_split[0]

	var d_split = dice_part.split("d")
	if d_split.size() != 2:
		push_error("Invalid dice notation: %s" % dice_notation)
		return 0

	var sides = int(d_split[1])

	if sides <= 0:
		push_error("Invalid dice sides in: %s" % dice_notation)
		return 0

	return sides

func roll_initiative_async(callback: Callable):
	var dex_mod = sheet.dexterity_modifier
	print("Player dexterity modifier: %d" % dex_mod)

	var ui_hud = get_tree().root.find_child("UiHud", true, false)
	if ui_hud:
		var dice_roller = ui_hud.find_child("DiceRoller", true, false)
		if dice_roller and dice_roller.has_method("roll_dice_visual_async"):
			var dice_sides = 20
			dice_roller.roll_dice_visual_async(dice_sides, Callable(self, "_on_initiative_roll_finished").bind(callback, dex_mod))
		else:
			print("DiceRoller not found inside UiHud or invalid, using standard roll for initiative.")
			var roll_result = randi() % 20 + 1
			var total_initiative = roll_result + dex_mod
			print("Standard initiative roll result: %d + %d = %d" % [roll_result, dex_mod, total_initiative])
			callback.call(total_initiative)
	else:
		print("UiHud not found, using standard roll for initiative.")
		var roll_result = randi() % 20 + 1
		var total_initiative = roll_result + dex_mod
		print("Standard initiative roll result: %d + %d = %d" % [roll_result, dex_mod, total_initiative])
		callback.call(total_initiative)

func _on_initiative_roll_finished(roll_result: int, callback: Callable, dex_mod: int):
	var total_initiative = roll_result + dex_mod
	print("Player visual initiative roll result: %d + %d = %d" % [roll_result, dex_mod, total_initiative])
	callback.call(total_initiative)
