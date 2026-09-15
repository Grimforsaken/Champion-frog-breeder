class_name TankItemWidget
extends Button

var item_id := ""
var source_tank_index := -1

func configure(id: String, source_index: int, texture_path: String) -> void:
	item_id = id
	source_tank_index = source_index
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	tooltip_text = "%s\nDrag to another tank thumbnail to transfer." % id.replace("_", " ").capitalize()
	text = id.replace("_", " ").capitalize()
	if texture_path != "" and ResourceLoader.exists(texture_path):
		icon = load(texture_path)
		expand_icon = true
		icon_max_width = 220
		text = ""

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id == "":
		return null
	var preview := Label.new()
	preview.text = item_id.replace("_", " ").capitalize()
	preview.add_theme_font_size_override("font_size", 16)
	set_drag_preview(preview)
	return {
		"type": "tank_item",
		"item_id": item_id,
		"source_tank": source_tank_index
	}
