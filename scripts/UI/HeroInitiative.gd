# Hero_Initiative.gd
extends Control

@export var unit_name: String = "Hero"
@export var initiative_value: int = 0
var max_initiative: int = 20

# Можно добавить дополнительные свойства и методы

func set_unit_data(name: String, initiative: int):
	unit_name = name
	initiative_value = initiative
	# Обновите UI здесь, если нужно
	update_display()

func update_display():
	# Например, если у вас есть Label с именем name_label и initiative_label
	if has_node("InitiativeHoarder/MainCharacterName"):
		$InitiativeHoarder/MainCharacterName.text = unit_name
	var initiative_bar = $InitiativeHoarder/MainCharacterInitiative
	if initiative_bar:
		initiative_bar.visible = true # Добавим явно
		initiative_bar.max_value = float(max_initiative) # TextureProgressBar ожидает float
		initiative_bar.value = float(initiative_value)   # TextureProgressBar ожидает float
