extends Control

@export var unit_name: String = "Skeleton"
@export var initiative_value: int = 12
@export var health: int = 50
@export var max_health: int = 50

func set_unit_data(name: String, initiative: int, current_health: int, max_hp: int):
	unit_name = name
	initiative_value = initiative
	health = current_health
	max_health = max_hp
	update_display()

func update_display():
	if has_node("InitiativeHoarder2/Enemy1Name"):
		$InitiativeHoarder2/Enemy1Name.text = unit_name

	var initiative_bar = $InitiativeHoarder2/Enemy1Initiative
	if initiative_bar:
		initiative_bar.visible = true
		initiative_bar.max_value = float(20)
		initiative_bar.value = float(initiative_value)

	var health_bar = $InitiativeHoarder2/Enemy1Health
	if health_bar:
		health_bar.visible = true
		health_bar.max_value = float(max_health)
		health_bar.value = float(health)
