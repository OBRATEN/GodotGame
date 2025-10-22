# Unit.gd
class_name Unit

var name: String
var initiative: int = 0
var is_player: bool = false
var actor: Node2D = null

func _init(p_name: String, p_actor: Node2D, p_is_player: bool = false):
	name = p_name
	actor = p_actor
	is_player = p_is_player

func roll_initiative():
	initiative = randi() % 20 + 1
	print("%s rolled initiative: %d" % [name, initiative])

func take_turn():
	if actor == null:
		printerr("Unit '%s' has no actor!" % name)
		return
	if actor.has_method("take_turn"):
		actor.take_turn()
	else:
		print("Actor for '%s' missing take_turn()" % name)
