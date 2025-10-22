# Player.gd
extends CharacterBody2D

var grid_position: Vector2i = Vector2i.ZERO
var target_grid_position: Vector2i = Vector2i.ZERO
var is_moving: bool = false
var move_speed: float = 256.0  # пикселей в секунду (64px за 0.25 сек при 256)

var health: int = 20
var max_health: int = 20
var attack_power: int = 5

var weapon: Weapon = null

func _ready():
	set_grid_position(Vector2i(2, 2))
	weapon = Weapon.new("1d6")

func set_grid_position(pos: Vector2i):
	grid_position = pos
	target_grid_position = pos
	position = Vector2(pos.x, pos.y) * 64.0
	is_moving = false

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

func _process(delta):
	if is_moving:
		var target_world = Vector2(target_grid_position.x, target_grid_position.y) * 64.0
		var direction = (target_world - position).normalized()
		var distance_to_target = position.distance_to(target_world)
		
		if distance_to_target <= move_speed * delta:
			# Достигли цели
			position = target_world
			grid_position = target_grid_position
			is_moving = false
			_on_reached_target()
		else:
			# Двигаемся плавно
			position += direction * move_speed * delta

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
	queue_free()
