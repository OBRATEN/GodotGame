
extends Control

# Ссылки на узлы UI
@onready var item_list = $ChestBackground/ChestBorder/ChestOrder/ItemList
@onready var close_button = $ChestBackground/ChestBorder/ChestOrder/Label/CloseButton

# Ссылка на глобальный инвентарь
@onready var global_inventory = get_node("/root/GlobalInventory")

# Список предметов в сундуке
var chest_items: Array[Item] = []

# --- ИНИЦИАЛИЗАЦИЯ ---

func _ready():
	# Подключаем сигналы
	item_list.item_selected.connect(_on_item_selected)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Заполняем сундук примерными предметами (можно загружать из файла или генерировать)
	_populate_chest()
	
	# Обновляем отображение списка предметов
	_update_item_list()

# --- ЛОГИКА СУНДУКА ---

# Заполняет сундук предметами (пример)
func _populate_chest():
	chest_items.clear()
	
	# Создаём предметы
	var nephrite = Item.new("Нефрит", "res://.godot/imported/I_Jade.png-89e4298401338230629dff5aff4ca982.ctex", "Ценный минерал")
	var ruby = Item.new("Рубин", "res://.godot/imported/I_Ruby.png-4e94014aaee34a33b54fa710c6eb2488.ctex", "Драгоценный камень")
	var healing_potion = Item.new("Зелье лечения", "res://.godot/imported/P_Red07.png-914d5bef54b0b64bf8cf51272d03da78.ctex", "Восстанавливает 2d4+2 здоровья")
	
	# Добавляем в сундук
	chest_items.append(nephrite)
	chest_items.append(ruby)
	chest_items.append(healing_potion)
	chest_items.append(healing_potion.duplicate()) # Копия
	chest_items.append(healing_potion.duplicate()) # Ещё одна копия

# Обновляет отображение списка предметов в ItemList
func _update_item_list():
	item_list.clear()
	for item in chest_items:
		var icon = load(item.icon_path) if item.icon_path else null
		var text = item.name
		item_list.add_item(text, icon)

# Обработчик выбора предмета в ItemList
func _on_item_selected(index: int):
	if index < 0 or index >= chest_items.size():
		return
	
	var selected_item = chest_items[index]
	
	# Проверяем, есть ли у игрока место в инвентаре через *глобальный* инвентарь
	if not global_inventory.has_space():
		print("Инвентарь игрока полон!")
		return
	
	# Перемещаем предмет из сундука в *глобальный* инвентарь
	if global_inventory.add_item(selected_item):
		# Удаляем предмет из сундука
		chest_items.remove_at(index)
		# Обновляем отображение
		_update_item_list()
		print("Предмет '%s' перемещён в инвентарь." % selected_item.name)

# Обработчик нажатия кнопки закрытия
func _on_close_button_pressed():
	hide()
