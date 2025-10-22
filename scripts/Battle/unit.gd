# Unit.gd
class_name Unit

var name: String
var initiative: int = 0
var is_player: bool = false

func _init(p_name: String, p_is_player: bool = false):
	name = p_name
	is_player = p_is_player

func roll_initiative():
	initiative = randi() % 20 + 1  # 1d20
	print("%s rolled initiative: %d" % [name, initiative])

func take_turn():
	print("%s takes their turn!" % name)
	# Здесь можно вызвать UI для выбора действия (атака, магия и т.д.)
