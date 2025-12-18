# DiceRoller.gd
extends Control

signal dice_rolled(result) # <-- Новый сигнал

const MIN_IMPULSE = 1000
const MAX_IMPULSE = 1500
const MIN_SPIN = -100
const MAX_SPIN = 100
const SIMULATION_TIME = 2.0

@onready var dice_area = $Panel/DiceArea
@onready var dice_rigid_body = $Panel/DiceArea/DiceRigidBody
@onready var visual_dice = $Panel/DiceArea/DiceRigidBody/VisualDice

var is_simulating = false
var pending_callback: Callable # Для хранения обратного вызова

func _ready():
	if !dice_area or !dice_rigid_body or !visual_dice:
		push_error("One or more nodes not found! Check paths.")
		return

	init_dice()

func init_dice():
	dice_rigid_body.freeze = true
	dice_rigid_body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	dice_rigid_body.linear_velocity = Vector2.ZERO
	dice_rigid_body.angular_velocity = 0
	dice_rigid_body.global_position = dice_area.global_position + dice_area.size / 2
	dice_rigid_body.hide()

# DiceRoller.gd
# ... (остальной код как есть) ...

func roll_dice_visual_async(dice_sides: int, callback: Callable):
	print("DiceRoller: Received request to roll D%d" % dice_sides) # <-- Добавлено для отладки
	if is_simulating:
		print("DiceRoller is already simulating. Skipping roll.")
		callback.call(randi() % dice_sides + 1)
		return

	pending_callback = callback

	# Устанавливаем тип кости ДО показа
	print("DiceRoller: Setting visual dice type to D%d" % dice_sides) # <-- Добавлено для отладки
	visual_dice.dice_type_sides = dice_sides
	visual_dice.queue_redraw()

	is_simulating = true
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

	var result = randi() % dice_sides + 1
	print("DiceRoller: Simulation finished. Result: %d" % result) # <-- Добавлено для отладки
	visual_dice.update_visual(result, dice_sides)

	is_simulating = false
	dice_rigid_body.freeze = true
	dice_rigid_body.linear_velocity = Vector2.ZERO
	dice_rigid_body.angular_velocity = 0

	if pending_callback.is_valid():
		pending_callback.call(result)
		pending_callback = Callable()

# ...
