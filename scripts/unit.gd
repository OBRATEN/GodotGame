# Unit.gd
# Базовый "обёрточный" класс для участников боя (игроков и врагов)
# Должен использоваться с class_name для корректной типизации

class_name Unit

# --- Поля ---
var name: String
var initiative: int = 0
var is_player: bool = false
var actor: Node2D = null  # Ссылка на реального актёра на сцене (Player, Enemy и т.д.)

# --- Конструктор ---
func _init(p_name: String, p_actor: Node2D, p_is_player: bool = false):
	name = p_name
	actor = p_actor
	is_player = p_is_player

# --- Бросок инициативы (1d20) ---
func roll_initiative():
	initiative = randi() % 20 + 1  # случайное число от 1 до 20
	print("%s rolled initiative: %d" % [name, initiative])

# --- Выполнение хода ---
func take_turn():
	if actor == null:
		printerr("Unit '%s' has no actor assigned!" % name)
		return

	if !actor.has_method("take_turn"):
		print("Actor for '%s' has no 'take_turn' method." % name)
		return

	# Вызываем take_turn у реального актёра (Player.gd или Enemy.gd)
	actor.take_turn()
