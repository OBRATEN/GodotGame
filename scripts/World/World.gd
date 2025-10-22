# World.gd
extends Node2D

@onready var player = $Player
@onready var enemy = $Enemy
@onready var battle_manager = $BattleManager
@onready var switch_mode_button = $Player/Camera2D/UiHud/HUD/ModePanel/SwitchModeButton

func _ready():
	switch_mode_button.pressed.connect(_on_start_battle_pressed)

	# Опционально: подключаем сигналы боя
	battle_manager.player_turn_started.connect(_on_player_turn)
	battle_manager.battle_finished.connect(_on_battle_finished)

func _on_start_battle_pressed():
	switch_mode_button.disabled = true
	print("Battle starting...")

	var player_unit = Unit.new("Hero", player, true)
	var enemy_unit = Unit.new("Goblin", enemy, false)

	# Явно создаём типизированные массивы
	var player_units: Array[Unit] = [player_unit]
	var enemy_units: Array[Unit] = [enemy_unit]

	battle_manager.start_battle(player_units, enemy_units)

func _on_player_turn(unit: Unit):
	# Пример: автоматическая атака
	unit.actor.take_turn()
	battle_manager.next_turn()

func _on_battle_finished():
	print("Battle ended!")
	switch_mode_button.disabled = false
