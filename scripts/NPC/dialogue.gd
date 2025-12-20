extends CanvasLayer

# Экспортируемые переменные
@export_file("*.json") var dialogs_file: String = "res://dialogues/dialogs.json"
@export var starting_dialog_id: String = "start_conversation"

# Внутренние ссылки
@onready var text_label = $DialogTextWindow/DialogBackground/DialogBorder/DialogSeparator/Text as RichTextLabel
@onready var char_left_texture = $DialogTextWindow/DialogBackground/DialogBorder/DialogSeparator/CharLeft as TextureRect
@onready var char_right_texture = $DialogTextWindow/DialogBackground/DialogBorder/DialogSeparator/CharRight as TextureRect
@onready var option1_button = $DialogOptions/VBoxContainer/PanelContainer1/Option1 as Button
@onready var option2_button = $DialogOptions/VBoxContainer/PanelContainer2/Option2 as Button
@onready var option3_button = $DialogOptions/VBoxContainer/PanelContainer3/Option3 as Button

# Внутренние переменные
var dialogs_data: Dictionary = {}
var current_dialog_id: String = ""

func _ready():
	# Загружаем все диалоги из JSON
	load_dialogs_from_json()
	# Начинаем с первого диалога
	start_dialog_by_id(starting_dialog_id)

func load_dialogs_from_json():
	var file = FileAccess.open(dialogs_file, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json_result = JSON.parse_string(json_text)
		if json_result != null:
			dialogs_data = json_result
		else:
			printerr("JSON parse error in file: ", dialogs_file)
	else:
		printerr("Could not open dialog file: ", dialogs_file)

func start_dialog_by_id(dialog_id: String):
	current_dialog_id = dialog_id
	var dialog = dialogs_data.get(dialog_id)
	if dialog == null:
		printerr("Dialog with ID '", dialog_id, "' not found in JSON data.")
		queue_free()
		return

	# Устанавливаем текст
	if text_label:
		text_label.text = dialog.get("text", "...").strip_edges()
	else:
		printerr("Text label node (RichTextLabel) not found!")

	# Устанавливаем портрет
	var portrait_path = dialog.get("npc_portrait", "")
	if portrait_path != "":
		var texture = load(portrait_path)
		if texture:
			if char_left_texture:
				char_left_texture.texture = texture
			if char_right_texture:
				char_right_texture.texture = null
		else:
			printerr("Portrait texture not found: ", portrait_path)

	# Получаем опции
	var options = dialog.get("options", [])
	var next_ids = dialog.get("next_ids", [])

	# Если опций нет — закрываем окно
	if options.size() == 0:
		queue_free()
		return

	var btn1 = $DialogOptions/VBoxContainer/PanelContainer1/Option1 as Button
	var btn2 = $DialogOptions/VBoxContainer/PanelContainer2/Option2 as Button
	var btn3 = $DialogOptions/VBoxContainer/PanelContainer3/Option3 as Button

	var buttons = [btn1, btn2, btn3]

	for i in range(3):
		var button = buttons[i]
		if button == null:
			printerr("Button Option", i + 1, " not found!")
			continue

		if i < options.size():
			button.text = options[i]
			button.visible = true

			# Отключаем старые соединения
			if button.is_connected("pressed", _on_option_selected):
				button.disconnect("pressed", _on_option_selected)

			# Подключаем с передачей индекса
			var idx = i
			button.connect("pressed", Callable(self, "_on_option_selected").bind(idx))
		else:
			button.visible = false
			
func _on_option_selected(option_index: int):
	print("Option selected: ", option_index)  # Отладка
	var dialog = dialogs_data.get(current_dialog_id)
	if dialog == null:
		print("Dialog is null, closing window.")
		queue_free()
		return

	var next_ids = dialog.get("next_ids", [])
	var next_id = ""
	if option_index < next_ids.size():
		next_id = next_ids[option_index]

	print("Next dialog ID: ", next_id)  # Отладка

	if next_id != "":
		start_dialog_by_id(next_id)
	else:
		print("No next dialog, closing window.")
		queue_free()
