# Enemy_Initiative.gd
extends Control

@export var unit_name: String = "Skeleton"
@export var initiative_value: int = 0

func set_unit_data(name: String, initiative: int):
	unit_name = name
	initiative_value = initiative
	update_display()

func update_display():
	if has_node("Enemy1Name"):
		$NameLabel.text = unit_name
	if has_node("Enemy1Initiative"):
		$InitiativeLabel.text = str(initiative_value)
