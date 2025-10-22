# World.gd
extends Node2D

@onready var player = $Player
@onready var enemy = $Enemy
@onready var battle_manager = $BattleManager
@onready var end_turn_button = $Player/Camera2D/UiHud/HUD/EndTurn/EndTurnButton
@onready var start_button = $Player/Camera2D/UiHud/HUD/ModePanel/SwitchModeButton
@onready var attack_button = $Player/Camera2D/UiHud/HUD/ActionPanel/HBoxContainer/Actions/VBoxContainer/Row_1/AttackButton
@onready var move_button = $Player/Camera2D/UiHud/HUD/ActionPanel/HBoxContainer/Actions/VBoxContainer/Row_1/MoveButton


var move_mode: bool = false
var max_move_range: int = 6
var is_player_turn: bool = false

func _ready():
	start_button.pressed.connect(_on_start_battle_pressed)
	move_button.pressed.connect(_on_MoveButton_pressed)
	attack_button.pressed.connect(_on_AttackButton_pressed)  # ← подключение
	end_turn_button.pressed.connect(_on_EndTurnButton_pressed)
	battle_manager.player_turn_started.connect(_on_player_turn)
	battle_manager.battle_finished.connect(_on_battle_finished)
	_set_battle_ui_visible(false)

func _on_start_battle_pressed():
	enemy.set_target(player)
	var player_unit = Unit.new("Hero", player, true)
	var enemy_unit = Unit.new("Goblin", enemy, false)
	var players: Array[Unit] = [player_unit]
	var enemies: Array[Unit] = [enemy_unit]
	battle_manager.start_battle(players, enemies)

func _on_player_turn(unit: Unit):
	is_player_turn = true
	_set_battle_ui_visible(true)
	print("Your turn!")

func _on_MoveButton_pressed():
	if !is_player_turn: return
	move_mode = true
	move_button.disabled = true
	print("Move mode: click on map.")

func _on_AttackButton_pressed():
	if !is_player_turn:
		return

	var player_pos = player.get_grid_position()
	var enemy_pos = enemy.get_grid_position()
	var dist = player_pos.distance_to(enemy_pos)

	if dist <= 1:
		player.attack_target(enemy)  # ← используем метод с оружием

		if enemy.health <= 0:
			_on_battle_finished()
	else:
		print("Enemy is too far to attack!")

func _on_EndTurnButton_pressed():
	if !is_player_turn: return
	print("Player ends turn.")
	_end_player_turn()

func _end_player_turn():
	is_player_turn = false
	_set_battle_ui_visible(false)
	move_mode = false
	move_button.disabled = false
	battle_manager.next_turn()

func _input(event):
	if move_mode and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_pos = get_global_mouse_position()
		var target_grid = _world_to_grid(world_pos)
		var player_grid = player.get_grid_position()

		if target_grid == player_grid:
			print("Already there!")
		elif player_grid.distance_to(target_grid) > max_move_range:
			print("Too far! Max: %d tiles." % max_move_range)
		else:
			player.set_grid_position(target_grid)
			print("Moved to %s" % target_grid)

		move_mode = false
		move_button.disabled = false

func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var cell_size = 64
	return Vector2i(
		int(round(world_pos.x / cell_size)),
		int(round(world_pos.y / cell_size))
	)

func _set_battle_ui_visible(visible: bool):
	move_button.visible = visible
	attack_button.visible = visible      # ← показываем/скрываем
	end_turn_button.visible = visible
	
func _on_battle_finished():
	print("Battle finished! Returning to overworld.")
	_set_battle_ui_visible(false)
	is_player_turn = false
	move_mode = false
	# Здесь можно показать кнопку "Start Battle" снова, если нужно
