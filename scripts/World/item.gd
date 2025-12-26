extends Resource

class_name Item

# Имя предмета
@export var name: String = "Неизвестный предмет"

# Путь к текстуре (иконке) предмета
@export var icon_path: String = ""

# Описание предмета
@export var description: String = "Описание отсутствует."

# Конструктор (опционально, можно создавать через редактор)
func _init(name: String = "", icon_path: String = "", description: String = ""):
	self.name = name
	self.icon_path = icon_path
	self.description = description
