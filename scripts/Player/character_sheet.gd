# CharacterSheet.gd
class_name CharacterSheet

# --- Основные характеристики (DnD 5e) ---
var strength: int = 10
var dexterity: int = 10
var constitution: int = 10
var intelligence: int = 10
var wisdom: int = 10
var charisma: int = 10

# --- Производные параметры ---
var armor_class: int = 10  # AC = 10 + модификатор Ловкости
var proficiency_bonus: int = 2  # +2 на 1-4 уровне

# --- Здоровье ---
var max_hit_points: int = 10
var current_hit_points: int = max_hit_points

# --- Инвентарь ---
var weapon: Weapon = null
var armor: String = "None"  # можно расширить до Armor.gd

# --- Уровень и класс ---
var level: int = 1
var name_of_class: String = "Fighter"

# --- Модификаторы характеристик ---
func get_ability_modifier(score: int) -> int:
	return floor((score - 10) / 2)

func get_strength_mod() -> int:
	return get_ability_modifier(strength)

func get_dexterity_mod() -> int:
	return get_ability_modifier(dexterity)

func get_constitution_mod() -> int:
	return get_ability_modifier(constitution)

# --- Обновление производных параметров ---
func update_derived_stats():
	armor_class = 10 + get_dexterity_mod()
	max_hit_points = 10 + (get_constitution_mod() * level)  # упрощённо
	current_hit_points = min(current_hit_points, max_hit_points)

# --- Урон и здоровье ---
func take_damage(damage: int):
	current_hit_points = max(0, current_hit_points - damage)
	if current_hit_points <= 0:
		_on_death()

func _on_death():
	print("Character is dead!")

# --- Атака (melee) ---
func make_melee_attack(target) -> int:
	if weapon == null:
		return 0

	# Бросок атаки: d20 + модификатор Силы + бонус мастерства
	var attack_roll = randi() % 20 + 1 + get_strength_mod() + proficiency_bonus
	var damage = 0

	# Если попадание (предположим, AC цели = 10 + мод. Ловкости)
	if attack_roll >= target.armor_class:
		damage = weapon.roll_damage() + get_strength_mod()
		target.take_damage(damage)

	return damage
