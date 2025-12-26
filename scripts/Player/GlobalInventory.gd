# GlobalInventory.gd
extends Node

# Максимальное количество предметов в инвентаре (можно изменить)
@export var max_slots: int = 10

# Список предметов в инвентаре
var items: Array[Item] = []

# Сигнал, который испускается при изменении инвентаря
signal inventory_changed

# --- ОСНОВНЫЕ ФУНКЦИИ ИНВЕНТАРЯ ---

# Добавляет предмет в инвентарь
func add_item(item: Item) -> bool:
	if items.size() >= max_slots:
		print("Инвентарь полон!")
		return false
	
	items.append(item.duplicate()) # Важно: дублируем предмет, чтобы избежать проблем с ресурсами
	inventory_changed.emit()
	print("Добавлен предмет: %s" % item.name)
	return true

# Удаляет предмет из инвентаря по индексу
func remove_item(index: int) -> bool:
	if index < 0 or index >= items.size():
		print("Неверный индекс предмета.")
		return false
	
	items.remove_at(index)
	inventory_changed.emit()
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

# --- ФУНКЦИИ СОХРАНЕНИЯ/ЗАГРУЗКИ (опционально, для полного сохранения между запусками) ---
# func save_inventory():
# 	var save_game = FileAccess.open("user://save_inventory.json", FileAccess.WRITE)
# 	var data = {"items": items}
# 	save_game.store_string(JSON.stringify(data))
# 	save_game.close()

# func load_inventory():
# 	if not FileAccess.file_exists("user://save_inventory.json"):
# 		return
# 	var save_game = FileAccess.open("user://save_inventory.json", FileAccess.READ)
# 	var data = JSON.parse_string(save_game.get_as_text())
# 	save_game.close()
# 	if data and data.has("items"):
# 		# Загрузка предметов из сохранения
# 		# Требует более сложной логики десериализации для Item Resources
# 		# Пока что оставим как есть, AutoLoad решает основную задачу между сценами
# 		items = data.items
# 		inventory_changed.emit()
