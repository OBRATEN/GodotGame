# World.gd
extends Node2D

@onready var tilemap = $DungeonGenerator/TileMap
@onready var player = $Player
@onready var battle_manager = $BattleManager
@onready var end_turn_button = $UiHud/HUD/CharacterFolder/CharacterBorder/CharacterOrder/EndTurnButton
@onready var start_button = $UiHud/HUD/CharacterFolder/CharacterBorder/CharacterOrder/SwitchModeButton
@onready var attack_button = $UiHud/HUD/CharacterFolder/CharacterBorder/CharacterOrder/AbilitiesHoarder/AbilitiesOrder1/AbilityBorder1/AbilityButton1
@onready var attack_button_text = $UiHud/HUD/CharacterFolder/CharacterBorder/CharacterOrder/AbilitiesHoarder/AbilitiesOrder1/AbilityBorder1/AbilityText1
@onready var move_button = $UiHud/HUD/CharacterFolder/CharacterBorder/CharacterOrder/AbilitiesHoarder/AbilitiesOrder2/AbilityBorder11/AbilityButton11
@onready var move_button_text = $UiHud/HUD/CharacterFolder/CharacterBorder/CharacterOrder/AbilitiesHoarder/AbilitiesOrder2/AbilityBorder11/AbilityText11


@onready var move_range_indicator = $MoveRangeIndicator


var enemies: Array[Node2D] = []
var move_mode: bool = false
var attack_mode: bool = false
var is_player_turn: bool = false


func _ready():
	start_button.pressed.connect(_on_start_battle_pressed)
	move_button.pressed.connect(_on_MoveButton_pressed)
	attack_button.pressed.connect(_on_AttackButton_pressed)  # ← подключение
	end_turn_button.pressed.connect(_on_EndTurnButton_pressed)
	battle_manager.player_turn_started.connect(_on_player_turn)
	battle_manager.battle_finished.connect(_on_battle_finished)
	_set_battle_ui_visible(false)
	# Переменная для хранения позиций тайлов индикатора
var move_tiles_positions: Array[Vector2i] = []

func _show_move_range():
	# Сначала очищаем предыдущую зону, если она была
	_hide_move_range()

	var start = player.get_grid_position()
	var max_dist = player.move_range

	for dx in range(-max_dist, max_dist + 1):
		for dy in range(-max_dist, max_dist + 1):
			var pos = Vector2i(start.x + dx, start.y + dy)
			if start.distance_to(pos) <= max_dist and _is_walkable(pos):
				_create_move_indicator_tile(pos)

func _hide_move_range():
	# Проходим по всем сохраненным позициям и удаляем тайлы индикатора
	for pos in move_tiles_positions:
		tilemap.set_cell(Constants.MOVE_INDICATOR_LAYER, pos, -1) # Удаляем тайл с индикаторного слоя

	# Очищаем список позиций
	move_tiles_positions.clear()

func _create_move_indicator_tile(grid_pos: Vector2i):
	# Используем ID базового проходимого тайла (например, ID 0 для "земли").
	# Замените `base_walkable_tile_id` на актуальный ID тайла в вашем TileSet.
	var base_walkable_tile_id = 0 # <-- Установите сюда правильный ID базового тайла
	var indicator_color = Color(0.841, 0.948, 1.0, 0.4) # Ваш цвет из ColorRect

	# Устанавливаем базовый тайл на индикаторный слой
	tilemap.set_cell(Constants.MOVE_INDICATOR_LAYER, grid_pos, base_walkable_tile_id)

	# Получаем TileData для этой ячейки на индикаторном слое
	var tile_data = tilemap.get_cell_tile_data(Constants.MOVE_INDICATOR_LAYER, grid_pos)
	if tile_data:
		# Устанавливаем цвет модуляции для этой ячейки
		tile_data.modulate = indicator_color

	# Сохраняем позицию, чтобы потом можно было её очистить
	move_tiles_positions.append(grid_pos)

func _on_start_battle_pressed():
	# Очистка старых врагов
	for e in enemies:
		e.queue_free()
	enemies.clear()

	# 1. Создаём и добавляем врагов НА СЦЕНУ (чтобы _ready() вызвался и health = 10)
	var EnemyScene = preload("res://scenes/Enemy.tscn")
	var enemy1 = EnemyScene.instantiate()
	enemy1.name = "Goblin1"
	add_child(enemy1)
	enemy1.set_grid_position(Vector2i(5, 5))
	enemy1.set_target(player)
	enemy1.add_to_group("enemies")

	var enemy2 = EnemyScene.instantiate()
	enemy2.name = "Goblin2"
	add_child(enemy2)
	enemy2.set_grid_position(Vector2i(6, 4))
	enemy2.set_target(player)
	enemy2.add_to_group("enemies")
	print("enemy1 = %s" % str(enemy1))
	print("enemy2 = %s" % str(enemy2))
	print("Same object? %s" % str(enemy1 == enemy2))

	enemies = [enemy1, enemy2]

	# 2. ЯВНО объявляем массивы как Array[Unit] — это ключ к решению ошибки!
	var player_units: Array[Unit] = []
	player_units.append(Unit.create("Hero", player, true))

	var enemy_units: Array[Unit] = []
	for e in enemies:
		enemy_units.append(Unit.create(e.name, e, false))

	# 3. Передаём ТИПИЗИРОВАННЫЕ массивы
	battle_manager.start_battle(player_units, enemy_units)

func _on_player_turn(unit: Unit):
	is_player_turn = true
	_set_battle_ui_visible(true)
	
	if unit.actor == player:
		player.reset_turn()
		_update_action_buttons_text()  # ← обновляем UI
	
	print("Your turn!")

func _on_MoveButton_pressed():
	if !is_player_turn: return
	if player.remaining_move <= 0:
		print("No movement left!")
		return
	move_mode = true
	move_button.disabled = true
	_show_move_range()  # ← показываем зону
	print("Move mode: click on map.")

func _on_AttackButton_pressed():
	if !is_player_turn:
		return
	if !player.can_attack():
		print("No attacks remaining!")
		return
	attack_mode = true
	attack_button.disabled = true
	print("Attack mode: click on an enemy.")

func _on_EndTurnButton_pressed():
	if !is_player_turn: return
	if player.is_moving:
		print("Wait until movement finishes!")
		return
	print("Player ends turn.")
	_end_player_turn()

func _end_player_turn():
	is_player_turn = false
	move_mode = false
	attack_mode = false
	move_button.disabled = false
	attack_button.disabled = false
	_hide_move_range()  # ← добавь это
	battle_manager.next_turn()

func _clear_children(node: Node):
	for child in node.get_children():
		child.queue_free()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if move_mode:
			_handle_move_input(event)
		elif attack_mode:
			_handle_attack_input(event)

func _handle_move_input(event):
	var world_pos = get_global_mouse_position()
	var target_grid = _world_to_grid(world_pos)
	var player_grid = player.get_grid_position()

	if target_grid == player_grid:
		print("Already there!")
	else:
		var distance = player_grid.distance_to(target_grid)

		if distance > player.remaining_move:
			print("Not enough movement! Remaining: %d" % player.remaining_move)
		elif !_is_walkable(target_grid):  # ← заменил _is_grid_occupied на _is_walkable
			print("Cell %s is blocked by wall or occupied!" % target_grid)
		else:
			player.remaining_move -= distance
			player.start_move_to(target_grid)
			print("Moving to %s. Remaining move: %d" % [target_grid, player.remaining_move])

	_update_action_buttons_text()
	move_mode = false
	move_button.disabled = false
	_hide_move_range()
	
func _handle_attack_input(event):
	if !player.can_attack():
		print("No attacks left!")
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
			print("Target is too far to attack! (Range: 1)")
	else:
		print("No enemy selected.")

	attack_mode = false
	attack_button.disabled = false

func _get_enemy_at_position(world_pos: Vector2) -> Node2D:
	var enemies_in_group = get_tree().get_nodes_in_group("enemies")
	for e in enemies_in_group:
		if e.is_queued_for_deletion():
			continue
		# Хитбокс = весь тайл (16x16), центрирован на e.position
		var half = Constants.CELL_SIZE / 2.0
		var rect = Rect2(e.position - Vector2(half, half), Vector2(Constants.CELL_SIZE, Constants.CELL_SIZE))
		if rect.has_point(world_pos):
			return e
	return null

func _world_to_grid(world_pos: Vector2) -> Vector2i:
	# Определяем клетку по мировой позиции — без смещения!
	return Vector2i(
		int(floor(world_pos.x / Constants.CELL_SIZE)),
		int(floor(world_pos.y / Constants.CELL_SIZE))
	)

func _set_battle_ui_visible(visible: bool):     # ← показываем/скрываем
	end_turn_button.visible = visible
	
func _on_battle_finished():
	print("Battle finished! Returning to overworld.")
	_set_battle_ui_visible(false)
	is_player_turn = false
	move_mode = false
	attack_mode = false

	# Удаляем всех врагов и, возможно, игрока (если мёртв)
	for e in enemies:
		if e.is_inside_tree():
			e.queue_free()
	enemies.clear()
	
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

	# Обновляем текст кнопки перемещения
	move_button_text.set_text("(%d)" % player.remaining_move)

	# Обновляем текст кнопки атаки
	attack_button_text.set_text("(%d)" % (player.max_attacks_per_turn-player.attacks_used))

func _is_walkable(grid_pos: Vector2i) -> bool:
	if tilemap.get_cell_source_id(Constants.WALLS_LAYER, grid_pos) != -1:
		return false

	# Проверка юнитов
	if _is_grid_occupied(grid_pos):
		return false

	return true
