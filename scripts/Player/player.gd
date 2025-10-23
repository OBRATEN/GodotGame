# Player.gd
extends CharacterBody2D

var grid_position: Vector2i = Vector2i.ZERO
var target_grid_position: Vector2i = Vector2i.ZERO

var move_speed: float = 128.0
var is_moving: bool = false

var health: int = 20
var max_health: int = 20
var max_attacks_per_turn: int = 1  # ← Максимум атак за ход
var attacks_used: int = 0
var move_range: int = 6
var remaining_move: int = 6 

var weapon: Weapon = null

func _ready():
	set_grid_position(Vector2i(2, 2))
	weapon = Weapon.new("1d10")
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
	# Центрируем позицию на тайле
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
		return  # Игнорировать, если уже движется (для пошаговой игры)
	
	# Проверка: можно ли двигаться (например, на соседнюю клетку)
	if (target - grid_position).length() > 1:
		return  # или добавь логику пути, если нужно
	
	target_grid_position = target
	is_moving = true

func _on_reached_target():
	# Можно вызвать сигнал или обработать конец хода
	print("Player reached target grid:", grid_position)
	# Например: emit_signal("move_finished") или вызвать следующий ход ИИ

func take_turn():
	print("Player's turn started.")

func take_damage(dmg: int):
	health = max(0, health - dmg)
	print("Player takes %d damage! HP: %d" % [dmg, health])
	if health <= 0:
		_die()

func _die():
	print("Player has died!")

func attack_target(target: Node2D):
	if attacks_used >= max_attacks_per_turn:
		print("Cannot attack: no attacks left this turn!")
		return

	if weapon == null:
		print("No weapon!")
		return
	if not target.has_method("take_damage"):
		print("Target cannot take damage!")
		return

	var damage = weapon.roll_damage()
	print("Player attacks %s for %d damage!" % [target.name, damage])
	target.take_damage(damage)

	use_attack()  # ← увеличиваем счётчик

	# Проверка окончания боя
	var bm = get_tree().get_first_node_in_group("battle_manager")
	if bm:
		bm.check_battle_end()
