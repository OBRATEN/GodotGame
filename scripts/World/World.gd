extends Node2D

@onready var tilemap = $TileMap
@onready var player = $Player
@onready var battle_manager = $BattleManager
@onready var end_turn_button = $UiHud/HUD/CharacterFolder/CharacterBorder/CharacterOrder/EndTurnButton
@onready var start_button = $UiHud/HUD/CharacterFolder/CharacterBorder/CharacterOrder/SwitchModeButton
@onready var attack_button = $UiHud/HUD/CharacterFolder/CharacterBorder/CharacterOrder/AbilitiesHoarder/AbilitiesOrder1/AbilityBorder1/AbilityButton1
@onready var attack_button_text = $UiHud/HUD/CharacterFolder/CharacterBorder/CharacterOrder/AbilitiesHoarder/AbilitiesOrder1/AbilityBorder1/AbilityText1
@onready var move_button = $UiHud/HUD/CharacterFolder/CharacterBorder/CharacterOrder/AbilitiesHoarder/AbilitiesOrder2/AbilityBorder11/AbilityButton11
@onready var move_button_text = $UiHud/HUD/CharacterFolder/CharacterBorder/CharacterOrder/AbilitiesHoarder/AbilitiesOrder2/AbilityBorder11/AbilityText11

@onready var history = $UiHud/HUD/HistoryFolder/HistoryBorder/HistoryTabs
@onready var useful_history = $UiHud/HUD/HistoryFolder/HistoryBorder/HistoryTabs/UsefulHistory
@onready var debug_history = $UiHud/HUD/HistoryFolder/HistoryBorder/HistoryTabs/DebugHistory

@onready var move_range_indicator = $MoveRangeIndicator



var move_mode: bool = false
var attack_mode: bool = false
var is_player_turn: bool = false
var is_in_battle: bool = false


func _ready():
	start_button.pressed.connect(_on_start_battle_pressed)
	move_button.pressed.connect(_on_MoveButton_pressed)
	attack_button.pressed.connect(_on_AttackButton_pressed)
	end_turn_button.pressed.connect(_on_EndTurnButton_pressed)
	battle_manager.player_turn_started.connect(_on_player_turn)
	battle_manager.battle_finished.connect(_on_battle_finished)
	_set_battle_ui_visible(false)

func _show_move_range():
	_clear_children(move_range_indicator)
	var start = player.get_grid_position()
	var max_dist = player.move_range

	for dx in range(-max_dist, max_dist + 1):
		for dy in range(-max_dist, max_dist + 1):
			var pos = Vector2i(start.x + dx, start.y + dy)
			if start.distance_to(pos) <= max_dist and _is_walkable(pos):
				_create_move_indicator_tile(pos)

func _hide_move_range():
	_clear_children(move_range_indicator)

func _create_move_indicator_tile(grid_pos: Vector2i):
	var indicator = ColorRect.new()
	indicator.name = "MoveTile_%d_%d" % [grid_pos.x, grid_pos.y]
	indicator.color = Color(0.841, 0.948, 1.0, 0.4)
	indicator.custom_minimum_size = Vector2(Constants.CELL_SIZE, Constants.CELL_SIZE)
	indicator.position = Vector2(
		grid_pos.x * Constants.CELL_SIZE,
		grid_pos.y * Constants.CELL_SIZE
	)
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_range_indicator.add_child(indicator)

func _on_start_battle_pressed():
	is_in_battle = true

	var player_units: Array[Unit] = []
	player_units.append(Unit.create("Hero", player, true))

	var enemy_nodes = get_tree().get_nodes_in_group("enemies")
	var enemy_units: Array[Unit] = []

	for enemy_node in enemy_nodes:
		if enemy_node is Node2D and enemy_node != player:
			var current_world_pos = enemy_node.position
			var calculated_grid_pos = _world_to_grid(current_world_pos)
			enemy_node.set_grid_position(calculated_grid_pos)
			history.log(debug_history, str("DEBUG: Set grid position (%s) for enemy %s based on world pos (%s)" % [calculated_grid_pos, enemy_node.name, current_world_pos]))

			enemy_units.append(Unit.create(enemy_node.name, enemy_node, false))
			history.log(debug_history, str("Added enemy to battle: %s" % enemy_node.name))

	battle_manager.battle_started.connect(_on_battle_properly_started, CONNECT_ONE_SHOT)

	battle_manager.start_battle(player_units, enemy_units)
	


func _on_battle_properly_started():
	var alive_players = 0
	var alive_enemies = 0
	for unit in battle_manager.units:
		if unit.is_player and battle_manager._is_unit_alive(unit):
			alive_players += 1
		elif not unit.is_player and battle_manager._is_unit_alive(unit):
			alive_enemies += 1

	if alive_enemies == 0 and alive_players > 0:
		history.log(useful_history, "All enemies are dead or absent at the start of the battle! Battle won automatically.")
		if not battle_manager.battle_ended:
			battle_manager.end_battle()


func _on_player_turn(unit: Unit):
	is_player_turn = true
	_set_battle_ui_visible(true)
	
	if unit.actor == player:
		player.reset_turn()
		_update_action_buttons_text()
	
	history.log(useful_history, "Your turn!")


func _on_MoveButton_pressed():
	if !is_player_turn: return
	if player.remaining_move <= 0:
		history.log(debug_history, "No movement left!")
		return
	move_mode = true
	move_button.disabled = true
	_show_move_range()
	history.log(debug_history, "Move mode: click on map.")

func _on_AttackButton_pressed():
	if !is_player_turn:
		return
	if !player.can_attack():
		history.log(debug_history, "No attacks remaining!")
		return
	attack_mode = true
	attack_button.disabled = true
	history.log(debug_history, "Attack mode: click on an enemy.")

func _on_EndTurnButton_pressed():
	if !is_player_turn: return
	if player.is_moving:
		history.log(debug_history, "Wait until movement finishes!")
		return
	history.log(useful_history, "Player ends turn.")
	_end_player_turn()

func _end_player_turn():
	is_player_turn = false
	move_mode = false
	attack_mode = false
	move_button.disabled = false
	attack_button.disabled = false
	_hide_move_range()
	battle_manager.next_turn()

func _clear_children(node: Node):
	for child in node.get_children():
		child.queue_free()

func _input(event):
	if not is_in_battle and event is InputEventKey and event.pressed:
		var direction := Vector2.ZERO
		match event.keycode:
			KEY_W:
				direction.y -= 1
			KEY_S:
				direction.y += 1
			KEY_A:
				direction.x -= 1
			KEY_D:
				direction.x += 1
		
		if direction != Vector2.ZERO:
			direction = direction.normalized()
			var current_pos = player.get_grid_position()
			var new_pos = current_pos + Vector2i(direction.x, direction.y)
			
			if _is_walkable(new_pos):
				player.start_move_to(new_pos) 
			else:
				history.log(debug_history, str("Cannot move to ", new_pos, " - not walkable."))

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_pos = get_global_mouse_position()
		var clicked_grid_pos = _world_to_grid(world_pos)
		history.log(debug_history, str("Clicked at world position: ", world_pos, " -> grid position: ", clicked_grid_pos))

		if move_mode:
			_handle_move_input(event)
		elif attack_mode:
			_handle_attack_input(event)
	
func _handle_move_input(event):
	var world_pos = get_global_mouse_position()
	var target_grid = _world_to_grid(world_pos)
	var player_grid = player.get_grid_position()

	if target_grid == player_grid:
		history.log(debug_history, "Already there!")
	else:
		var distance = player_grid.distance_to(target_grid)

		if distance > player.remaining_move:
			history.log(debug_history, str("Not enough movement! Remaining: %d" % player.remaining_move))
		elif !_is_walkable(target_grid):
			history.log(debug_history, str("Cell %s is blocked by wall or occupied!" % target_grid))
		else:
			player.remaining_move -= distance
			player.start_move_to(target_grid)
			history.log(debug_history, str("Moving to %s. Remaining move: %d" % [target_grid, player.remaining_move]))

	_update_action_buttons_text()
	move_mode = false
	move_button.disabled = false
	_hide_move_range()
	
func _handle_attack_input(event):
	if !player.can_attack():
		history.log(debug_history, "No attacks left!")
		attack_mode = false
		attack_button.disabled = false
		return

	var world_pos = get_global_mouse_position()
	var clicked_enemy = _get_enemy_at_position(world_pos)

	if clicked_enemy:
		var player_pos = player.get_grid_position()
		var enemy_pos = clicked_enemy.get_grid_position()
		var dist = player_pos.distance_to(enemy_pos)

		if dist <= 1:
			player.attack_target(clicked_enemy)
			_update_action_buttons_text()
		else:
			history.log(debug_history, "Target is too far to attack! (Range: 1)")
	else:
		history.log(debug_history, "No enemy selected.")

	attack_mode = false
	attack_button.disabled = false

func _get_enemy_at_position(world_pos: Vector2) -> Node2D:
	var enemies_in_group = get_tree().get_nodes_in_group("enemies")
	for e in enemies_in_group:
		if e.is_queued_for_deletion():
			continue
		var half = Constants.CELL_SIZE / 2.0
		var rect = Rect2(e.position - Vector2(half, half), Vector2(Constants.CELL_SIZE, Constants.CELL_SIZE))
		if rect.has_point(world_pos):
			return e
	return null

func _world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / Constants.CELL_SIZE)),
		int(floor(world_pos.y / Constants.CELL_SIZE))
	)

func _set_battle_ui_visible(visible: bool):
	end_turn_button.visible = visible
	
func _on_battle_finished():
	history.log(useful_history, "Battle finished! Returning to overworld.")
	
	is_in_battle = false

	_set_battle_ui_visible(false)
	is_player_turn = false
	move_mode = false
	attack_mode = false


func _is_grid_occupied(grid_pos: Vector2i) -> bool:
	var bm = get_tree().get_first_node_in_group("battle_manager")
	if bm == null:
		return false

	for unit in bm.units:
		if unit.actor == null or unit.actor.is_queued_for_deletion():
			continue
		if !bm._is_unit_alive(unit):
			continue
		if unit.actor.get_grid_position() == grid_pos:
			return true
	return false
	
func _update_action_buttons_text():
	if player == null:
		return

	move_button_text.set_text("(%d)" % player.remaining_move)

	attack_button_text.set_text("(%d)" % (player.max_attacks_per_turn-player.attacks_used))

func _is_walkable(grid_pos: Vector2i) -> bool:
	var ground_layer = tilemap.get_node("Ground") as TileMapLayer
	var walls_layer = tilemap.get_node("Walls") as TileMapLayer
	var arch_layer = tilemap.get_node("Arch") as TileMapLayer

	if ground_layer and ground_layer.get_cell_source_id(grid_pos) == -1:
		return false

	if walls_layer and walls_layer.z_index > 0 and walls_layer.get_cell_source_id(grid_pos) != -1:
		return false
	if arch_layer and arch_layer.z_index > 0 and arch_layer.get_cell_source_id(grid_pos) != -1:
		return false

	if _is_grid_occupied(grid_pos):
		return false

	return true

func _is_tile_blocking_vision(grid_pos: Vector2i) -> bool:
	var walls_layer = tilemap.get_node("Walls") as TileMapLayer
	var arch_layer = tilemap.get_node("Arch") as TileMapLayer

	var wall_blocked = walls_layer and walls_layer.get_cell_source_id(grid_pos) != -1
	var arch_blocked = arch_layer and arch_layer.get_cell_source_id(grid_pos) != -1

	var is_blocked = wall_blocked or arch_blocked

	print_debug("  -> _is_tile_blocking_vision(%s): Wall=%s, Arch=%s => Blocked=%s" % [grid_pos, wall_blocked, arch_blocked, is_blocked])

	return is_blocked
