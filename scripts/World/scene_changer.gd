extends Node2D

@export var target_scene: PackedScene

@onready var click_area = $Area2D 

func _ready():
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			if is_point_in_area(mouse_pos):
				if target_scene:
					get_tree().change_scene_to_packed(target_scene)
				else:
					print("Ошибка: Сцена не выбрана в инспекторе.")

func is_point_in_area(point: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var results = space_state.intersect_point(query)
	for obj in results:
		if obj.collider == click_area:
			return true
	return false
