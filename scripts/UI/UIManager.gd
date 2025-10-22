extends Node

# Сигналы для связи между компонентами UI и игровой логикой
signal game_state_changed(new_state)
signal character_selected(character_id)
signal action_selected(action_name)

# Перечисление возможных состояний UI/игры
enum UIState { EXPLORATION, COMBAT, DIALOGUE, MENU, LOOTING }

var current_ui_state: UIState = UIState.EXPLORATION

# Ссылки на ноды UI, которые будут установлены при готовности сцены
var _ui_scene_instance: Control

func change_ui_state(new_state: UIState):
	if current_ui_state != new_state:
		current_ui_state = new_state
		game_state_changed.emit(new_state)
		# Здесь можно добавить логику, например, скрыть/показать определенные элементы
		_update_ui_visibility()

func _update_ui_visibility():
	# Логика скрытия/показа панелей в зависимости от состояния
	match current_ui_state:
		UIState.EXPLORATION:
			# Показать HUD, скрыть меню боя
			pass
		UIState.COMBAT:
			# Показать панель действий, инициативу и т.д.
			pass
		UIState.DIALOGUE:
			# Показать окно диалога, скрыть остальное
			pass

# Функция для инициализации ссылок на ноды UI после создания сцены
func register_ui_scene(ui_instance: Control):
	_ui_scene_instance = ui_instance	
