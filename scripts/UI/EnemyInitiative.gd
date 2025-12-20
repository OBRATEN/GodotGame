# Enemy_Initiative.gd
extends Control

@export var unit_name: String = "Skeleton"
@export var initiative_value: int = 12
# Максимальное значение для шкалы инициативы (обычно 20 для D20)
@export var max_initiative: int = 20

func set_unit_data(name: String, initiative: int):
	unit_name = name
	initiative_value = initiative
	# Ограничиваем значение прогресс-бара диапазоном [0, max_initiative]
	initiative_value = clamp(initiative_value, 0, max_initiative)
	update_display()

func update_display():
	if has_node("InitiativeHoarder2/Enemy1Name"): # Предполагаемый путь к Label с именем
		$InitiativeHoarder2/Enemy1Name.text = unit_name
	var initiative_bar = $InitiativeHoarder2/Enemy1Initiative # Теперь это TextureProgressBar
	if initiative_bar:
		initiative_bar.visible = true # Добавим явно
		initiative_bar.max_value = float(max_initiative) # TextureProgressBar ожидает float
		initiative_bar.value = float(initiative_value)   # TextureProgressBar ожидает float
