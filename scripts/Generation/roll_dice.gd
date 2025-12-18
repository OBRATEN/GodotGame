# main.gd
extends Control

# Настройки физического мира
const MIN_IMPULSE = 1000
const MAX_IMPULSE = 1500
const MIN_SPIN = -100
const MAX_SPIN = 100
const SIMULATION_TIME = 2.0 # Сколько времени симулировать "бросок"

@onready var dice_sides_spinbox = $Panel/SpinBox
@onready var roll_button = $Panel/Button
@onready var result_label = $Panel/DiceArea/Label
@onready var dice_area = $Panel/DiceArea
@onready var dice_rigid_body = $Panel/DiceArea/DiceRigidBody
@onready var visual_dice = $Panel/DiceArea/DiceRigidBody/VisualDice

var is_simulating = false

func _ready():
	if !roll_button or !dice_sides_spinbox or !result_label or !dice_area or !dice_rigid_body or !visual_dice:
		push_error("One or more nodes not found! Check paths.")
		return

	roll_button.pressed.connect(_on_roll_pressed)
	# --- НОВОЕ: Подключаем сигнал изменения значения SpinBox ---
	dice_sides_spinbox.value_changed.connect(_on_dice_sides_changed)
	# ---

	init_dice()
	# --- НОВОЕ: Устанавливаем начальный тип кости ---
	_on_dice_sides_changed(dice_sides_spinbox.value)
	# ---

func init_dice():
	dice_rigid_body.freeze = true
	dice_rigid_body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	dice_rigid_body.linear_velocity = Vector2.ZERO
	dice_rigid_body.angular_velocity = 0
	dice_rigid_body.global_position = dice_area.global_position + dice_area.size / 2
	dice_rigid_body.hide()

func _on_dice_sides_changed(new_value: float):
	var sides_int = int(new_value)
	# Обновляем тип кости у визуального элемента до броска
	visual_dice.dice_type_sides = sides_int
	# Если кость видна (например, после броска), обновим её отображение
	if dice_rigid_body.visible: # Проверяем свойство visible вместо is_hidden()
		# Не меняем _displayed_value, просто перерисуем форму
		visual_dice.queue_redraw()

# ---

func _on_roll_pressed():
	if is_simulating:
		return

	var sides = int(dice_sides_spinbox.value)
	_start_roll_simulation(sides)

func _start_roll_simulation(sides):
	is_simulating = true
	result_label.text = "Бросаем..."
	dice_rigid_body.show()

	dice_rigid_body.global_position = dice_area.global_position + dice_area.size / 2
	dice_rigid_body.rotation = 0
	dice_rigid_body.freeze = false
	dice_rigid_body.linear_velocity = Vector2.ZERO
	dice_rigid_body.angular_velocity = 0

	var impulse_dir = Vector2(randf_range(-1, 1), randf_range(-1, 0)).normalized()
	var impulse_strength = randf_range(MIN_IMPULSE, MAX_IMPULSE)
	dice_rigid_body.apply_central_impulse(impulse_dir * impulse_strength)

	var spin_torque = randf_range(MIN_SPIN, MAX_SPIN)
	dice_rigid_body.apply_torque_impulse(spin_torque)

	await get_tree().create_timer(SIMULATION_TIME).timeout

	_finish_roll_simulation(sides)

func _finish_roll_simulation(sides):
	is_simulating = false
	dice_rigid_body.freeze = true
	dice_rigid_body.linear_velocity = Vector2.ZERO
	dice_rigid_body.angular_velocity = 0

	var result = randi() % sides + 1
	result_label.text = "Результат: %d (D%d)" % [result, sides]

	visual_dice.update_visual(result, sides)
