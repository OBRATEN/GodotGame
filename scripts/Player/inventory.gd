extends Node

@export var max_slots: int = 10

var items: Array[Item] = []

signal inventory_changed

func add_item(item: Item) -> bool:
	if items.size() >= max_slots:
		print("Инвентарь полон!")
		return false
	
	items.append(item)
	inventory_changed.emit()
	print("Добавлен предмет: %s" % item.name)
	return true

func remove_item(index: int) -> bool:
	if index < 0 or index >= items.size():
		print("Неверный индекс предмета.")
		return false
	
	items.remove_at(index)
	return true

func get_item(index: int) -> Item:
	if index < 0 or index >= items.size():
		return null
	return items[index]

func get_item_count() -> int:
	return items.size()

func has_space() -> bool:
	return items.size() < max_slots
