# Weapon.gd
class_name Weapon

# Примеры:
# "1d4" → 1 кость d4
# "2d6+3" → 2 кости d6 + 3 урона
# "1d8" → стандартный меч

var dice_notation: String = "1d4"  # формат: [N]d[S][+M]

func _init(notation: String = "1d4"):
	dice_notation = notation

# Бросает урон по формуле вида "NdS+M"
func roll_damage() -> int:
	var notation = dice_notation.strip_edges()
	if notation.is_empty():
		return 0

	# Разделяем на части: кости и модификатор
	var plus_split = notation.split("+")
	var dice_part = plus_split[0]
	var modifier = 0
	if plus_split.size() > 1:
		modifier = int(plus_split[1])

	# Разделяем "NdS"
	var d_split = dice_part.split("d")
	if d_split.size() != 2:
		push_error("Invalid dice notation: %s" % dice_notation)
		return 0

	var num_dice = int(d_split[0])
	var sides = int(d_split[1])

	if num_dice <= 0 or sides <= 0:
		push_error("Invalid dice values in: %s" % dice_notation)
		return 0

	# Бросаем кости
	var total = 0
	for i in num_dice:
		total += randi() % sides + 1  # 1..sides

	total += modifier
	return total
