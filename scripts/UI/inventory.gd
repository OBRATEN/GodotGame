extends PanelContainer

# --- НОВОЕ: Добавлены переменные для инвентаря ---
# Максимальное количество предметов в инвентаре (можно изменить)
@export var max_slots: int = 10

# Список предметов в инвентаре
var items: Array[Item] = []

# Сигнал, который испускается при изменении инвентаря
signal inventory_changed

# --- КОНЕЦ НОВОГО ---

@export var inventory: PanelContainer

# Ссылка на ItemList (поиск через get_node_or_null)
@onready var item_list = $Border/Separator/Inventory/VBoxContainer/PanelContainer/ScrollContainer/ItemList

# --- ОСНОВНЫЕ ФУНКЦИИ ИНВЕНТАРЯ ---

# Добавляет предмет в инвентарь
func add_item(item: Item) -> bool:
	if items.size() >= max_slots:
		print("Инвентарь полон!")
		return false
	
	items.append(item)
	inventory_changed.emit()
	print("Добавлен предмет: %s" % item.name)
	
	# Обновляем отображение предметов в UI
	_update_item_list()
	
	return true

# Удаляет предмет из инвентаря по индексу
func remove_item(index: int) -> bool:
	if index < 0 or index >= items.size():
		print("Неверный индекс предмета.")
		return false
	
	items.remove_at(index)
	inventory_changed.emit()
	
	# Обновляем отображение предметов в UI
	_update_item_list()
	
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

# --- ФУНКЦИИ УПРАВЛЕНИЯ ВИДИМОСТЬЮ ---

func close_inventory():
	toggle_visibility(inventory)

func open_inventory():
	update_stats_labels()
	# Обновляем список предметов при открытии
	_update_item_list()
	toggle_visibility(inventory)

func toggle_visibility(object):
	if object.visible:
		object.visible = false
	else:
		object.visible = true

func e():
	if Input.is_action_just_pressed("E") and inventory.visible == false:
		open_inventory()
	elif Input.is_action_just_pressed("E") and inventory.visible == true:
		close_inventory()

func _on_main_character_pressed():
	open_inventory()

func _process(delta):
	e()

# --- ФУНКЦИИ ОБНОВЛЕНИЯ СТАТОВ ---

func update_stats_labels():
	var player = get_tree().get_first_node_in_group("player")

	if not player:
		print("Ошибка: Не найден игрок в группе 'player'.")
		return

	var sheet = player.sheet
	var base = "Border/Separator/Stats/SeparatorStatsLabel/ScrollStats/PanelStats/SeparatorStats"
	
	var stats = [
		["Str/Сила/Значение", sheet.strength],
		["Str/Атлетика/Значение", sheet.strength],
		["Dex/Ловкость/Значение", sheet.dexterity],
		["Dex/Ловкость рук/Значение", sheet.dexterity],
		["Dex/Акробатика/Значение", sheet.dexterity],
		["Dex/Скрытность/Значение", sheet.dexterity],
		["Cst/Телосложение/Значение", sheet.constitution],
		["Int/Интелект/Значение", sheet.intelligence],
		["Int/История/Значение", sheet.intelligence],
		["Int/Магия/Значение", sheet.intelligence],
		["Int/Природа/Значение", sheet.intelligence],
		["Int/Расследование/Значение", sheet.intelligence],
		["Wis/Мудрость/Значение", sheet.wisdom],
		["Wis/Восприятие/Значение", sheet.wisdom],
		["Wis/Выживание/Значение", sheet.wisdom],
		["Wis/Медицина/Значение", sheet.wisdom],
		["Wis/Проницательность/Значение", sheet.wisdom],
		["Wis/Уход за животными/Значение", sheet.wisdom],
		["Cha/Харизма/Значение", sheet.charisma],
		["Cha/Выступление/Значение", sheet.charisma],
		["Cha/Запугивание/Значение", sheet.charisma],
		["Cha/Обман/Значение", sheet.charisma],
		["Cha/Убеждение/Значение", sheet.charisma],
	]
	
	for item in stats:
		var path = item[0]
		var value = item[1]
		# Добавлена проверка на существование узла
		var node = get_node_or_null(base + "/" + path)
		if node:
			node.text = str(value)
		else:
			print("Ошибка: Не найден узел для стата: " + base + "/" + path)

# --- НОВОЕ: Функция для обновления списка предметов в ItemList ---
func _update_item_list():
	if not is_instance_valid(item_list):
		print("Ошибка: ItemList не найден или недействителен. Попробуйте найти его вручную.")
		# Попробуем найти первый ItemList в дочерних узлах
		var found_list = find_item_list_recursive(self)
		if found_list:
			item_list = found_list
			print("Успешно найден ItemList: ", item_list.get_path())
			# Повторяем обновление
			_update_item_list()
		else:
			print("Не удалось найти ItemList ни в одном месте.")
		return
	
	# Очищаем старые элементы
	item_list.clear()
	
	# Добавляем каждый предмет в список
	for item in items:
		var icon = load(item.icon_path) if item.icon_path else null
		var text = item.name
		# Добавляем предмет в список
		item_list.add_item(text, icon)
	
	# --- НОВОЕ: Подключаем сигнал item_selected ---
	item_list.item_selected.disconnect(_on_item_selected) # Отключаем, чтобы не дублировать
	item_list.item_selected.connect(_on_item_selected)
	# ---

# --- НОВАЯ ФУНКЦИЯ: Обработка клика по предмету ---
func _on_item_selected(index: int):
	if index < 0 or index >= items.size():
		return
	
	var selected_item = items[index]
	
	# Проверяем имя предмета и выполняем действие
	if selected_item.name == "Зелье лечения":
		use_healing_potion()
		# Удаляем использованный предмет
		remove_item(index)
		print("Использовано зелье лечения.")
	else:
		print("Предмет '%s' не может быть использован." % selected_item.name)

# --- НОВАЯ ФУНКЦИЯ: Использование зелья лечения ---
func use_healing_potion():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Ошибка: Не найден игрок в группе 'player'.")
		return

	# Восстанавливаем 8 здоровья (или можно сделать бросок костей)
	var heal_amount = 8
	# player.health += heal_amount # Прямое изменение health
	player.sheet.current_hit_points = min(player.sheet.max_hit_points, player.sheet.current_hit_points + heal_amount) # Обновляем через CharacterSheet
	player.health = player.sheet.current_hit_points # Синхронизируем старую переменную health
	
	# Опционально: отправить сигнал о смене здоровья
	if player.has_signal("health_changed"):
		player.emit_signal("health_changed", player.health, player.max_health)
	
	print("Игрок восстановил %d здоровья. Текущее HP: %d/%d" % [
		heal_amount, 
		player.sheet.current_hit_points, 
		player.sheet.max_hit_points
	])

# --- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ: Поиск ItemList рекурсивно ---
func find_item_list_recursive(node: Node):
	for child in node.get_children():
		if child is ItemList:
			return child
		else:
			var result = find_item_list_recursive(child)
			if result:
				return result
	return null

# --- НОВОЕ: Добавление в группу при готовности ---
func _ready():
	add_to_group("player_inventory")
	# Обновляем список предметов при запуске
	_update_item_list()
