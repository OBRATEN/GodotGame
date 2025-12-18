# Hero_Initiative.gd
extends Control

@export var unit_name: String = "Hero"
@export var initiative_value: int = 0

# Можно добавить дополнительные свойства и методы

func set_unit_data(name: String, initiative: int):
	unit_name = name
	initiative_value = initiative
	# Обновите UI здесь, если нужно
	update_display()

func update_display():
	# Например, если у вас есть Label с именем name_label и initiative_label
	if has_node("MainCharacterName"):
		$NameLabel.text = unit_name
	if has_node("MainCharacterInitiative"):
		$InitiativeLabel.text = str(initiative_value)
