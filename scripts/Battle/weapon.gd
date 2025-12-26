# Weapon.gd
class_name Weapon

var dice_notation: String = "1d4" 

func _init(notation: String = "1d4"):
	dice_notation = notation

func roll_damage() -> int:
	var notation = dice_notation.strip_edges()
	if notation.is_empty():
		return 0

	var plus_split = notation.split("+")
	var dice_part = plus_split[0]
	var modifier = 0
	if plus_split.size() > 1:
		modifier = int(plus_split[1])

	var d_split = dice_part.split("d")
	if d_split.size() != 2:
		push_error("Invalid dice notation: %s" % dice_notation)
		return 0

	var num_dice = int(d_split[0])
	var sides = int(d_split[1])

	if num_dice <= 0 or sides <= 0:
		push_error("Invalid dice values in: %s" % dice_notation)
		return 0

	var total = 0
	for i in range(num_dice): 
		total += randi() % sides + 1

	total += modifier
	return total
