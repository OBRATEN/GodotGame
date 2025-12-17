extends PanelContainer

@export var inventory: PanelContainer


func close_inventory():
	toggle_visibility(inventory)

func open_inventory():
	update_stats_labels()
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
	var player = get_node("/root/TestingScene/Player")

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
		get_node(base + "/" + path).text = str(value)
