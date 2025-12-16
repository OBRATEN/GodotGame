extends PanelContainer

@export var pause_menu: PanelContainer
@export var inventory: PanelContainer


func resume():
	toggle_visibility(pause_menu)
	get_tree().paused = false

func pause():
	toggle_visibility(pause_menu)
	get_tree().paused = true

func toggle_visibility(object):
	if object.visible:
		object.visible = false
	else:
		object.visible = true

func esc():
	if Input.is_action_just_pressed("Esc") and get_tree().paused == false and not inventory.visible == true:
		pause()
	elif Input.is_action_just_pressed("Esc") and get_tree().paused == true:
		resume()


func _on_resume_pressed():
	resume()

func _on_call_menu_pressed():
	pause()

func _on_exit_pressed():
	get_tree().quit()

func _process(delta):
	esc()
