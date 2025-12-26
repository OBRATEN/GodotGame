extends PanelContainer

@export var inventory: PanelContainer

# Ссылка на ItemList (поиск через get_node_or_null)
@onready var item_list = get_node_or_null("Border/Separator/Items/SeparatorItemsLabel/ScrollItems/PanelItems/SeparatorItems/ItemList")

# Ссылка на глобальный инвентарь
@onready var global_inventory = get_node("/root/GlobalInventory")

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
		var node = get_node_or_null(base + "/" + path)
		if node:
			node.text = str(value)
		else:
			print("Ошибка: Не найден узел для стата: " + base + "/" + path)

# --- ФУНКЦИЯ ОБНОВЛЕНИЯ СПИСКА ПРЕДМЕТОВ ---
func _update_item_list():
	if not is_instance_valid(item_list):
		print("Ошибка: ItemList не найден или недействителен. Попробуйте найти его вручную.")
		var found_list = find_item_list_recursive(self)
		if found_list:
			item_list = found_list
			print("Успешно найден ItemList: ", item_list.get_path())
			_update_item_list()
		else:
			print("Не удалось найти ItemList ни в одном месте.")
		return
	
	# Очищаем старые элементы
	item_list.clear()
	
	# Добавляем каждый предмет из *глобального* инвентаря в список
	for item in global_inventory.items:
		var icon = load(item.icon_path) if item.icon_path else null
		var text = item.name
		item_list.add_item(text, icon)
	
	# Подключаем сигнал item_selected
	item_list.item_selected.disconnect(_on_item_selected)
	item_list.item_selected.connect(_on_item_selected)

# --- ФУНКЦИЯ ОБРАБОТКИ КЛИКА ПО ПРЕДМЕТУ ---
func _on_item_selected(index: int):
	if index < 0 or index >= global_inventory.items.size():
		return
	
	var selected_item = global_inventory.items[index]
	
	if selected_item.name == "Зелье лечения":
		use_healing_potion()
		# Удаляем использованный предмет из *глобального* инвентаря
		global_inventory.remove_item(index)
		print("Использовано зелье лечения.")
	else:
		print("Предмет '%s' не может быть использован." % selected_item.name)

# --- ФУНКЦИЯ ИСПОЛЬЗОВАНИЯ ЗЕЛЬЯ ---
func use_healing_potion():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Ошибка: Не найден игрок в группе 'player'.")
		return

	var heal_amount = 8
	player.sheet.current_hit_points = min(player.sheet.max_hit_points, player.sheet.current_hit_points + heal_amount)
	player.health = player.sheet.current_hit_points
	
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

# --- НЕТ НУЖДЫ В _ready() ДЛЯ ДОБАВЛЕНИЯ В ГРУППУ ---
# func _ready():
# 	# AutoLoad узел не нуждается в ручном добавлении в группы для поиска через /root/
# 	# global_inventory уже доступен как /root/GlobalInventory
# 	_update_item_list() # Вызовем здесь, чтобы обновить при открытии UI
# 	# Подписка на сигнал изменений инвентаря (опционально, если UI должен реагировать на внешние изменения)
# 	# global_inventory.inventory_changed.connect(_update_item_list)
# ```
# ---
