extends Control

@export var chest_menu: PanelContainer


func open():
	toggle_visibility(chest_menu)

func close():
	toggle_visibility(chest_menu)

func toggle_visibility(object):
	if object.visible:
		object.visible = false
	else:
		object.visible = true


func _on_close_button_pressed():
	close()
