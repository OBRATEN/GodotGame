extends Node

# Максимальное количество предметов в инвентаре (можно изменить)
@export var max_slots: int = 10

# Список предметов в инвентаре
var items: Array[Item] = []

# Сигнал, который испускается при изменении инвентаря
signal inventory_changed

# --- ОСНОВНЫЕ ФУНКЦИИ ---

# Добавляет предмет в инвентарь
func add_item(item: Item) -> bool:
	if items.size() >= max_slots:
		print("Инвентарь полон!")
		return false
	
	items.append(item)
	inventory_changed.emit()
	print("Добавлен предмет: %s" % item.name)
	return true

# Удаляет предмет из инвентаря по индексу
func remove_item(index: int) -> bool:
	if index < 0 or index >= items.size():
		print("Неверный индекс предмета.")
		return false
	
	items.remove_at(index)
	return true

# Получает предмет по индексу
func get_item(index: int) -> Item:
	if index < 0 or index >= items.size():
		return null
	return items[index]

# Возвращает количество предметов в инвентаре
func get_item_count() -> int:
	return items.size()

# Проверяет, есть ли место в инвентаре
func has_space() -> bool:
	return items.size() < max_slots

# --- ПРИМЕР ИСПОЛЬЗОВАНИЯ ---
# func _ready():
# 	var potion = Item.new("Зелье лечения", "potion_red.png", "Восстанавливает 2d4+2 здоровья")
# 	add_item(potion)
# 	var ruby = Item.new("Рубин", "ruby.png", "Драгоценный камень")
# 	add_item(ruby)
