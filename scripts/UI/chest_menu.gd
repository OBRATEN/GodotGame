extends CharacterBody2D

var chest_menu: Control

var player_node: Node2D
var tile_size: Vector2 = Vector2(64, 64)


func open():
	chest_menu.visible = true

func close():
	chest_menu.visible = false


func _on_close_button_pressed():
	close()



func _ready():
	player_node = get_tree().get_first_node_in_group("player")
	chest_menu = get_tree().current_scene.get_node("UiHud/HUD/Chest")
	var close_button = chest_menu.get_node("ChestBackground/ChestBorder/ChestOrder/Label/CloseButton")
	if close_button.is_connected("pressed", Callable(self, "_on_close_button_pressed")):
		close_button.disconnect("pressed", Callable(self, "_on_close_button_pressed"))
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_position = get_global_mouse_position()
		var self_position = global_position
		
		if is_position_in_chest(click_position):
			if player_node:
				var distance_in_tiles = calculate_tile_distance(player_node.global_position, self_position)
				
				if distance_in_tiles <= 5:
					open()

func is_position_in_chest(click_position: Vector2) -> bool:
	var local_click_pos = to_local(click_position)
	var collision_shape = $CollisionShape2D.shape
	var half_size = collision_shape.size / 2.0

	return (
		abs(local_click_pos.x) <= half_size.x and
		abs(local_click_pos.y) <= half_size.y
	)

func calculate_tile_distance(pos1: Vector2, pos2: Vector2) -> float:
	var delta = (pos1 - pos2).abs()
	var tiles_x = delta.x / tile_size.x
	var tiles_y = delta.y / tile_size.y
	return ceil(tiles_x + tiles_y)
