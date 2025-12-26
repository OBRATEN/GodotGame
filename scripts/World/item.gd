extends Resource

class_name Item

@export var name: String = "Неизвестный предмет"

@export var icon_path: String = ""

@export var description: String = "Описание отсутствует."

func _init(name: String = "", icon_path: String = "", description: String = ""):
	self.name = name
	self.icon_path = icon_path
	self.description = description
