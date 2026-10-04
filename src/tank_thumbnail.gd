class_name TankThumbnail
extends Button

signal tank_selected(index: int)
signal tank_item_dropped(item_id: String, source_index: int, destination_index: int)

var tank_index := -1

func configure(index: int, title: String) -> void:
	tank_index = index
	text = title
	custom_minimum_size = Vector2(150, 70)
	pressed.connect(func(): tank_selected.emit(tank_index))
	tooltip_text = "Select this tank. Drag a tank item here to transfer it."

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type", "") == "tank_item" and int(data.get("source_tank", -2)) != tank_index

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	tank_item_dropped.emit(str(data.get("item_id", "")), int(data.get("source_tank", -1)), tank_index)
