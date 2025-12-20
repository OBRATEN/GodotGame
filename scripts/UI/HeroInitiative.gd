# Hero_Initiative.gd
extends Control

@export var unit_name: String = "Hero"
@export var initiative_value: int = 0
@export var health: int = 100 # Текущее здоровье
@export var max_health: int = 100 # Максимальное здоровье (для шкалы)

func set_unit_data(name: String, initiative: int, current_health: int, max_hp: int):
	unit_name = name
	initiative_value = initiative
	health = current_health
	max_health = max_hp
	update_display()

func update_display():
	# Обновляем имя
	if has_node("InitiativeHoarder/MainCharacterName"):
		$InitiativeHoarder/MainCharacterName.text = unit_name

	# Обновляем инициативу
	var initiative_bar = $InitiativeHoarder/MainCharacterInitiative
	if initiative_bar:
		initiative_bar.visible = true
		initiative_bar.max_value = float(20) # Или max_initiative, если вы хотите параметризировать
		initiative_bar.value = float(initiative_value)

	# Обновляем здоровье
	var health_bar = $InitiativeHoarder/MainCharacterHealth
	if health_bar:
		health_bar.visible = true
		health_bar.max_value = float(max_health)
		health_bar.value = float(health)
