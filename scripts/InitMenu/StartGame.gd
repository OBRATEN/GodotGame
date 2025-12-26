extends Control

func _on_NewGameButton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")

func _on_LoadGameButton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/procedure_testing.tscn")

func _on_SettingsButton_pressed() -> void:
	print("Открытие настроек... (Пока не реализовано)")

func _on_ExitButton_pressed() -> void:
	get_tree().quit()
