extends PanelContainer

@export var inventory: PanelContainer


func _on_main_character_pressed():
	open_inventory()


func close_inventory():
	toggle_visibility(inventory)


func open_inventory():
	toggle_visibility(inventory)


func esc():
	if Input.is_action_just_pressed("Esc") and inventory.visible == true:
		close_inventory()


func toggle_visibility(object):
	if object.visible:
		object.visible = false
	else:
		object.visible = true


func _process(delta):
	esc()
