extends Node2D

class_name Enemy

var move_range: int = 6
var attack_range: float = 1.5
var health: int
var max_health: int = 10
var weapon: Weapon = null

var grid_position: Vector2i = Vector2i.ZERO
var target_node_name: String = ""

var target_world_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var move_speed: float = 200.0

signal health_changed(current_health: int, max_health: int)

func _ready():
	health = max_health
	weapon = Weapon.new("1d4")
	add_to_group("enemies")

func set_grid_position(pos: Vector2i):
	grid_position = pos
	if not is_moving:
		position = Vector2(
			pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
			pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
		)

func get_grid_position() -> Vector2i:
	return grid_position

func take_damage(dmg: int):
	print("Enemy %s takes %d damage! Current HP: %d" % [name, dmg, health])
	health = max(0, health - dmg)
	emit_signal("health_changed", health, max_health)
	print(" → New HP: %d" % health)
	if health <= 0:
		_die()

func _perform_attack():
	var current_target = _find_target()
	if current_target == null:
		print("Enemy %s: No target found to attack!" % name)
		return

	print("Enemy attacks %s!" % current_target.name)
	if weapon != null and current_target.has_method("take_damage"):
		var damage = weapon.roll_damage()
		print("Enemy deals %d damage!" % damage)
		current_target.take_damage(damage)

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

func take_turn():
	if is_moving:
		print("Enemy is already moving!")
		return

	var current_target = _find_target()
	if current_target == null:
		print("Enemy %s: No target found for turn!" % name)
		return

	var target_pos = _get_target_grid(current_target)
	if target_pos == Vector2i.ZERO:
		print("Enemy %s: target has no grid position!" % name)
		return

	var dist = grid_position.distance_to(target_pos)

	if dist <= attack_range:
		_perform_attack()
	else:
		print("Distance: ", dist, attack_range)
		_move_toward_target(target_pos, dist)

func _find_target() -> Node2D:
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.is_empty():
		print_debug("No nodes found in 'player' group.")
		return null

	var closest_player: Node2D = null
	var closest_distance = 999999.0
	print_debug("  -> DEBUG: Initial closest_distance: %s" % closest_distance)

	for player_node in player_nodes:
		if not player_node.has_method("get_grid_position"):
			print_debug("Player node %s has no get_grid_position method." % player_node.name)
			continue

		var player_grid_pos = player_node.get_grid_position()
		var my_grid_pos = self.get_grid_position()

		print_debug("Checking player %s at %s vs enemy %s at %s" % [player_node.name, player_grid_pos, name, my_grid_pos])

		var distance = my_grid_pos.distance_to(player_grid_pos)
		print_debug("  -> Distance: %.2f (limit 6)" % distance)

		if distance > 6:
			print_debug("  -> OUT OF RANGE.")
			continue

		var has_loS = _has_line_of_sight(my_grid_pos, player_grid_pos)
		print_debug("  -> Has Line of Sight: %s" % has_loS)

		if not has_loS:
			print_debug("  -> NO LINE OF SIGHT, skipping player %s." % player_node.name)
			continue

		print_debug("  -> DEBUG: Before comparison - distance: %.2f, closest_distance: %.2f" % [distance, closest_distance])
		if distance < closest_distance:
			print_debug("  -> Distance %.2f is less than closest_distance %.2f. Updating target." % [distance, closest_distance])
			closest_player = player_node
			closest_distance = distance
			print_debug("  -> NEW closest visible player: %s at distance %.2f" % [closest_player.name, closest_distance])
		else:
			print_debug("  -> Distance %.2f is NOT less than closest_distance %.2f. Not updating target." % [distance, closest_distance])

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

func _move_toward_target(target_pos: Vector2i, dist_to_target: int):
	var direction = (target_pos - grid_position).sign()
	var new_grid_pos = grid_position + direction

	if _is_grid_occupied_by_others(new_grid_pos):
		print("Enemy %s: target cell %s is occupied. Looking for an adjacent free cell." % [name, new_grid_pos])

		var free_adjacent_pos = _find_free_adjacent_cell(target_pos)
		if free_adjacent_pos != Vector2i.ZERO:
			var dist_to_adjacent = grid_position.distance_to(free_adjacent_pos)
			if dist_to_adjacent <= dist_to_target:
				direction = (free_adjacent_pos - grid_position).sign()
				new_grid_pos = grid_position + direction
				if new_grid_pos != grid_position and !_is_grid_occupied_by_others(new_grid_pos):
					var world_node = get_parent()
					if world_node and world_node.has_method("_is_walkable"):
						if world_node._is_walkable(new_grid_pos):
							target_world_position = Vector2(
								new_grid_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
								new_grid_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
							)
							is_moving = true
							grid_position = new_grid_pos
							print("Enemy %s starts moving to %s (adjacent to target %s)" % [name, new_grid_pos, target_pos])
							return
						else:
							print("Enemy %s: Found adjacent cell %s, but it's not walkable (wall/arch)." % [name, new_grid_pos])
					else:
						print("Warning: Could not check walkability for %s, assuming it's walkable." % new_grid_pos)
						target_world_position = Vector2(
							new_grid_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
							new_grid_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
						)
						is_moving = true
						grid_position = new_grid_pos
						print("Enemy %s starts moving to %s (adjacent to target %s)" % [name, new_grid_pos, target_pos])
						return
				else:
					print("Enemy %s: Could not find a valid path to an adjacent cell near target %s." % [name, target_pos])
					return
			else:
				print("Enemy %s: Found adjacent cell %s, but it's further than current target cell. Staying put." % [name, free_adjacent_pos])
				return
		else:
			print("Enemy %s: No free adjacent cells found near target %s." % [name, target_pos])
			return

	var world_node = get_parent()
	if world_node and world_node.has_method("_is_walkable"):
		if world_node._is_walkable(new_grid_pos):
			if new_grid_pos != grid_position:
				target_world_position = Vector2(
					new_grid_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
					new_grid_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
				)
				is_moving = true
				grid_position = new_grid_pos
				print("Enemy %s starts moving to %s" % [name, new_grid_pos])
		else:
			print("Enemy %s: Target cell %s is not walkable (wall/arch)." % [name, new_grid_pos])
			var free_adjacent_pos = _find_free_adjacent_cell(target_pos)
			if free_adjacent_pos != Vector2i.ZERO:
				var dist_to_adjacent = grid_position.distance_to(free_adjacent_pos)
				if dist_to_adjacent <= dist_to_target:
					direction = (free_adjacent_pos - grid_position).sign()
					new_grid_pos = grid_position + direction
					if new_grid_pos != grid_position and !_is_grid_occupied_by_others(new_grid_pos):
						if world_node._is_walkable(new_grid_pos):
							target_world_position = Vector2(
								new_grid_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
								new_grid_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
							)
							is_moving = true
							grid_position = new_grid_pos
							print("Enemy %s starts moving to %s (adjacent to target %s)" % [name, new_grid_pos, target_pos])
							return
						else:
							print("Enemy %s: Found adjacent cell %s, but it's not walkable (wall/arch)." % [name, new_grid_pos])
				else:
					print("Enemy %s: Found adjacent cell %s, but it's further than current target cell. Staying put." % [name, free_adjacent_pos])
			else:
				print("Enemy %s: No free adjacent cells found near target %s." % [name, target_pos])
				return
	else:
		print("Warning: Could not check walkability for %s, assuming it's walkable." % new_grid_pos)
		if new_grid_pos != grid_position:
			target_world_position = Vector2(
				new_grid_pos.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2,
				new_grid_pos.y * Constants.CELL_SIZE + Constants.CELL_SIZE / 2
			)
			is_moving = true
			grid_position = new_grid_pos
			print("Enemy %s starts moving to %s" % [name, new_grid_pos])
			
func _find_free_adjacent_cell(target_pos: Vector2i) -> Vector2i:
	var directions = [
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0)
	]

	for dir in directions:
		var adjacent_pos = target_pos + dir
		if !_is_grid_occupied_by_others(adjacent_pos):
			var world_node = get_parent()
			if world_node and world_node.has_method("_is_walkable"):
				if world_node._is_walkable(adjacent_pos):
					return adjacent_pos
			else:
				print("Warning: Could not check walkability for %s, assuming it's walkable." % adjacent_pos)
				return adjacent_pos

	var diagonal_directions = [
		Vector2i(-1, -1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(1, 1)
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

	return Vector2i.ZERO


func _process(delta):
	if is_moving:
		var diff = target_world_position - position
		if diff.length() < 1.0:
			position = target_world_position
			is_moving = false
		else:
			position += diff.normalized() * move_speed * delta

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
			continue
		if unit.actor.get_grid_position() == grid_pos:
			return true
	return false

func _is_unit_alive(unit) -> bool:
	if unit.actor == null:
		return false
	return unit.actor.health > 0

func roll_initiative_async(callback: Callable):
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
			_call_standard_initiative_roll_async(callback, dex_mod)
	else:
		print("UiHud not found, using standard roll for initiative.")
		_call_standard_initiative_roll_async(callback, dex_mod)

func _on_initiative_roll_finished(roll_result: int, callback: Callable, dex_mod: int):
	var total_initiative = roll_result + dex_mod
	print("%s visual initiative roll result: %d + %d = %d" % [name, roll_result, dex_mod, total_initiative])
	callback.call(total_initiative)

func _call_standard_initiative_roll_async(callback: Callable, dex_mod: int):
	var roll_result = randi() % 20 + 1
	var total_initiative = roll_result + dex_mod
	print("%s standard initiative roll result: %d + %d = %d" % [name, roll_result, dex_mod, total_initiative])
	call_deferred("_deferred_callback_call", callback, total_initiative)

func _deferred_callback_call(callback: Callable, value: int):
	callback.call(value)

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

		if current_pos != start_pos:
			var world_ref = get_parent()
			if not world_ref or not world_ref.has_method("_is_tile_blocking_vision"):
				print_debug("  -> ERROR: Cannot access World.gd or _is_tile_blocking_vision method!")
				return false

			if world_ref._is_tile_blocking_vision(current_pos):
				print_debug("  -> LoS BLOCKED at %s by tile" % current_pos)
				return false
			else:
				print_debug("  -> Tile at %s is clear" % current_pos)
		else:
			print_debug("  -> Skipping start tile %s" % current_pos)

		if x == end_pos.x and y == end_pos.y:
			print_debug("  -> Reached target %s, LoS CLEAR!" % end_pos)
			break

		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy

	return true
