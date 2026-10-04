extends Control

const SCENE_ASSETS := {
	"home": "res://assets/scenes/lab.webp",
	"shop": "res://assets/scenes/shop.webp",
	"backyard_puddle": "res://assets/habitats/backyard_puddle.webp",
	"pond": "res://assets/habitats/pond.webp",
	"table": "res://assets/home/table.webp"
}

const TANK_ITEM_ASSETS := {
	"leaf_litter": "res://assets/tank_items/leaf_litter.webp",
	"broadleaf_plant": "res://assets/tank_items/broadleaf_plant.webp",
	"bark_bridge": "res://assets/tank_items/bark_bridge.webp",
	"rock_cluster": "res://assets/tank_items/rock_cluster.webp",
	"fern": "res://assets/tank_items/fern.webp",
	"moss_mound": "res://assets/tank_items/moss_mound.webp",
	"bark_cave": "res://assets/tank_items/bark_cave.webp",
	"water_dish": "res://assets/tank_items/water_dish.webp"
}

const TANK_BACKGROUNDS := {
	"rock_moss": "res://assets/tank_backgrounds/rock_moss.webp",
	"tropical_vines": "res://assets/tank_backgrounds/tropical_vines.webp",
	"bark_moss": "res://assets/tank_backgrounds/bark_moss.webp"
}

const STARTER_DECOR := [
	"water_dish", "fern", "bark_cave", "leaf_litter",
	"rock_cluster", "broadleaf_plant", "bark_bridge", "moss_mound"
]

const HABITAT_POSITIONS := [
	Vector2(0.12, 0.20), Vector2(0.31, 0.29), Vector2(0.51, 0.18), Vector2(0.73, 0.25),
	Vector2(0.88, 0.38), Vector2(0.20, 0.60), Vector2(0.43, 0.67), Vector2(0.66, 0.59),
	Vector2(0.82, 0.76)
]

var habitat_picker: OptionButton
var habitat_targets: Array[Dictionary] = []
var last_period_key := ""
var target_serial := 0
var notice_text := ""

var capture_running := false
var capture_value := 0.0
var capture_direction := 1.0
var capture_speed := 85.0
var capture_low := 40.0
var capture_high := 60.0
var capture_track: Control
var capture_marker: ColorRect
var active_target: Dictionary = {}

func _ready() -> void:
	GameState.state_changed.connect(_render)
	GameState.notice.connect(_on_notice)
	_render()

func _process(delta: float) -> void:
	if not capture_running or capture_track == null or capture_marker == null:
		return
	capture_value += capture_direction * capture_speed * delta
	if capture_value >= 100.0:
		capture_value = 100.0
		capture_direction = -1.0
	elif capture_value <= 0.0:
		capture_value = 0.0
		capture_direction = 1.0
	var width := capture_track.size.x
	capture_marker.position.x = clampf(width * capture_value / 100.0 - 5.0, 0.0, maxf(0.0, width - 10.0))

func _render() -> void:
	capture_running = false
	capture_track = null
	capture_marker = null
	_clear_all()
	match GameState.current_screen:
		"shop":
			_render_shop()
		"habitat":
			_render_habitat()
		_:
			_render_home()

func _clear_all() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _background(asset_key: String, fallback: Color) -> void:
	var back := ColorRect.new()
	back.color = fallback
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.z_index = -100
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var path: String = SCENE_ASSETS.get(asset_key, "")
	if path != "" and ResourceLoader.exists(path):
		var image := TextureRect.new()
		image.texture = load(path)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.z_index = -90
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(image)

func _panel(alpha: float = 0.94) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.065, 0.055, alpha)
	style.border_color = Color(0.66, 0.77, 0.50, 0.96)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(text: String, size: int = 18, wrap: bool = false, min_width: float = 0.0) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	if min_width > 0.0:
		label.custom_minimum_size.x = min_width
	if wrap:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _button(text: String, action: Callable, min_width: float = 120.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(min_width, 50)
	button.add_theme_font_size_override("font_size", 17)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button

func _begin_screen(with_navigation: bool = true) -> VBoxContainer:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	layer.add_child(margin)

	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	margin.add_child(outer)

	if with_navigation:
		_top_navigation(outer)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)

	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 960
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 9)
	scroll.add_child(content)
	return content

func _top_navigation(parent: VBoxContainer) -> void:
	var panel := _panel(0.98)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 18)
	box.add_child(status)
	status.add_child(_label("DAY %d" % GameState.day, 20, false, 110))
	status.add_child(_label("CASH $%d" % GameState.cash, 20, false, 135))
	status.add_child(_label("FOOD %d" % GameState.feeder_food, 18, false, 105))
	status.add_child(_label("CASE %d/%d" % [GameState.case_count(), GameState.CASE_CAPACITY], 18, false, 120))
	var status_fill := Control.new()
	status_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(status_fill)
	status.add_child(_label(str(GameState.current_screen).to_upper(), 16, false, 100))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	if GameState.current_screen == "home":
		actions.add_child(_button("PET SHOP", Callable(GameState, "travel_shop"), 150))
	elif GameState.current_screen == "shop":
		actions.add_child(_button("HOME / LAB", Callable(GameState, "travel_home"), 165))

	habitat_picker = OptionButton.new()
	habitat_picker.custom_minimum_size = Vector2(260, 50)
	habitat_picker.add_theme_font_size_override("font_size", 17)
	for habitat in GameState.unlocked_habitats:
		habitat_picker.add_item(_habitat_name(habitat))
		habitat_picker.set_item_metadata(habitat_picker.item_count - 1, habitat)
	actions.add_child(habitat_picker)
	actions.add_child(_button("GO TO HABITAT", Callable(self, "_go_selected_habitat"), 190))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(fill)

func _go_selected_habitat() -> void:
	if habitat_picker != null and habitat_picker.item_count > 0:
		GameState.travel_habitat(str(habitat_picker.get_item_metadata(habitat_picker.selected)))

func _show_notice(parent: VBoxContainer) -> void:
	if notice_text == "":
		return
	var panel := _panel(0.98)
	parent.add_child(panel)
	panel.add_child(_label(notice_text, 16, true, 500))

func _render_home() -> void:
	_background("home", Color("26342c"))
	var root := _begin_screen(true)
	_show_notice(root)
	_render_upkeep(root)
	_render_tank(root)
	_render_roster(root)

func _render_upkeep(parent: VBoxContainer) -> void:
	var panel := _panel(0.98)
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var status_text := "COMPLETE" if GameState.upkeep_complete() else "FEEDING REQUIRED"
	row.add_child(_label("MORNING FROG UPKEEP: %s" % status_text, 19, false, 390))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	row.add_child(_label("FEEDER BUGS: %d" % GameState.feeder_food, 17, false, 165))
	row.add_child(_button("FEED ALL", Callable(GameState, "feed_all"), 145))

func _render_tank(parent: VBoxContainer) -> void:
	var panel := _panel(0.96)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var tank: Dictionary = GameState.current_tank()
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	box.add_child(header)
	header.add_child(_label("%s" % tank["name"], 23, false, 260))
	header.add_child(_label("FROGS %d/%d" % [tank["frog_ids"].size(), tank["capacity"]], 17, false, 120))
	var header_fill := Control.new()
	header_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_fill)
	for i in range(GameState.tanks.size()):
		var t: Dictionary = GameState.tanks[i]
		var select := _button("TANK %d  %d/%d" % [i + 1, t["frog_ids"].size(), t["capacity"]], Callable(self, "_select_tank").bind(i), 145)
		select.disabled = i == GameState.selected_tank
		header.add_child(select)

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 330)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.clip_contents = true
	box.add_child(stage)
	_build_tank_stage(stage, tank)

	var background_title := _label("TANK BACKGROUND", 15)
	box.add_child(background_title)
	var background_grid := GridContainer.new()
	background_grid.columns = 3
	background_grid.add_theme_constant_override("h_separation", 8)
	background_grid.add_theme_constant_override("v_separation", 6)
	box.add_child(background_grid)
	for background_id in TANK_BACKGROUNDS.keys():
		var bg_button := _button(str(background_id).replace("_", " ").capitalize(), Callable(self, "_set_tank_background").bind(str(background_id)), 200)
		bg_button.disabled = str(tank.get("background", "rock_moss")) == str(background_id)
		background_grid.add_child(bg_button)

	box.add_child(_label("STARTER DECOR - tap an item in the tank to remove it; tap below to add it back", 15, true, 600))
	var decor_grid := GridContainer.new()
	decor_grid.columns = 4
	decor_grid.add_theme_constant_override("h_separation", 7)
	decor_grid.add_theme_constant_override("v_separation", 7)
	box.add_child(decor_grid)
	for item_id in STARTER_DECOR:
		if item_id not in tank.get("items", []):
			decor_grid.add_child(_button(str(item_id).replace("_", " ").capitalize(), Callable(self, "_add_tank_item").bind(str(item_id)), 170))
	if decor_grid.get_child_count() == 0:
		decor_grid.add_child(_label("All starter decor is currently in this tank.", 15, false, 340))

func _build_tank_stage(stage: Control, tank: Dictionary) -> void:
	var table_path: String = SCENE_ASSETS["table"]
	if ResourceLoader.exists(table_path):
		var table := TextureRect.new()
		table.texture = load(table_path)
		table.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		table.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		table.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(table, Rect2(0.0, 0.70, 1.0, 0.30))
		stage.add_child(table)

	var tank_area := Panel.new()
	var tank_style := StyleBoxFlat.new()
	tank_style.bg_color = Color(0.04, 0.10, 0.09, 0.88)
	tank_style.border_color = Color(0.76, 0.88, 0.82, 1.0)
	tank_style.set_border_width_all(5)
	tank_style.corner_radius_top_left = 7
	tank_style.corner_radius_top_right = 7
	tank_style.corner_radius_bottom_left = 7
	tank_style.corner_radius_bottom_right = 7
	tank_area.add_theme_stylebox_override("panel", tank_style)
	tank_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(tank_area, Rect2(0.07, 0.04, 0.86, 0.86))
	stage.add_child(tank_area)

	var bg_path: String = TANK_BACKGROUNDS.get(str(tank.get("background", "rock_moss")), "")
	if bg_path != "" and ResourceLoader.exists(bg_path):
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(bg, Rect2(0.09, 0.08, 0.82, 0.72))
		stage.add_child(bg)

	var title := _label("ACTIVE FROG TANK", 15, false, 200)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(title, Rect2(0.39, 0.07, 0.22, 0.08))
	stage.add_child(title)

	for item_id in tank.get("items", []):
		var id := str(item_id)
		var item := Button.new()
		item.flat = true
		item.focus_mode = Control.FOCUS_NONE
		item.tooltip_text = "%s - tap to remove" % id.replace("_", " ").capitalize()
		item.pressed.connect(Callable(self, "_remove_tank_item").bind(id))
		var item_path: String = TANK_ITEM_ASSETS.get(id, "")
		if item_path != "" and ResourceLoader.exists(item_path):
			item.icon = load(item_path)
			item.expand_icon = true
		else:
			item.text = id.replace("_", " ").capitalize()
		item.add_theme_font_size_override("font_size", 14)
		_set_rect(item, _item_rect(id))
		stage.add_child(item)

	var frog_ids: Array = tank.get("frog_ids", [])
	for i in range(mini(2, frog_ids.size())):
		var frog := GameState.get_frog(int(frog_ids[i]))
		if frog.is_empty():
			continue
		var visual := FrogVisual.new()
		visual.configure(frog, "side")
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(visual, Rect2(0.27 + 0.29 * i, 0.45, 0.24, 0.24))
		stage.add_child(visual)

	if frog_ids.is_empty():
		var empty_label := _label("No frogs in this tank yet", 18, false, 260)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(empty_label, Rect2(0.36, 0.39, 0.28, 0.10))
		stage.add_child(empty_label)

func _item_rect(id: String) -> Rect2:
	match id:
		"leaf_litter": return Rect2(0.13, 0.65, 0.35, 0.18)
		"broadleaf_plant": return Rect2(0.12, 0.24, 0.24, 0.50)
		"bark_bridge": return Rect2(0.34, 0.56, 0.34, 0.22)
		"rock_cluster": return Rect2(0.67, 0.66, 0.20, 0.16)
		"fern": return Rect2(0.66, 0.24, 0.22, 0.48)
		"moss_mound": return Rect2(0.18, 0.70, 0.24, 0.13)
		"bark_cave": return Rect2(0.40, 0.55, 0.30, 0.24)
		"water_dish": return Rect2(0.70, 0.70, 0.18, 0.13)
		_: return Rect2(0.40, 0.55, 0.24, 0.20)

func _set_tank_background(background_id: String) -> void:
	GameState.current_tank()["background"] = background_id
	GameState.state_changed.emit()

func _add_tank_item(id: String) -> void:
	var tank := GameState.current_tank()
	if id not in tank["items"]:
		tank["items"].append(id)
		GameState.state_changed.emit()

func _remove_tank_item(id: String) -> void:
	var tank := GameState.current_tank()
	if id in tank["items"]:
		tank["items"].erase(id)
		GameState.state_changed.emit()

func _select_tank(index: int) -> void:
	if index >= 0 and index < GameState.tanks.size():
		GameState.selected_tank = index
		GameState.state_changed.emit()

func _render_roster(parent: VBoxContainer) -> void:
	var panel := _panel(0.97)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	head.add_child(_label("FROG CASE", 22, false, 180))
	head.add_child(_label("%d / %d frogs" % [GameState.case_count(), GameState.CASE_CAPACITY], 17, false, 120))
	if GameState.frogs.is_empty():
		box.add_child(_label("No frogs yet. Go to the Backyard Puddle and tap a visible frog to catch your first breeder.", 17, true, 620))
		return
	for frog in GameState.frogs:
		var card := _panel(0.98)
		box.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		row.add_child(_label("%s | %s | Hue %03d | Condition %d%%" % [frog["name"], frog["sex"], int(frog.get("hue", 0)), int(frog.get("condition", 100))], 16, false, 470))
		var fill := Control.new()
		fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(fill)
		var frog_id := int(frog["id"])
		if not frog.get("fed_today", false):
			row.add_child(_button("FEED", Callable(self, "_feed_frog").bind(frog_id), 100))
		if frog.get("tank_id", "") == "":
			row.add_child(_button("PUT IN TANK", Callable(self, "_put_frog_in_tank").bind(frog_id), 145))
		else:
			row.add_child(_button("MOVE TO CASE", Callable(self, "_move_frog_to_case").bind(frog_id), 150))

func _feed_frog(frog_id: int) -> void:
	GameState.feed_frog(frog_id)

func _put_frog_in_tank(frog_id: int) -> void:
	GameState.move_frog_to_tank(frog_id, GameState.selected_tank)

func _move_frog_to_case(frog_id: int) -> void:
	GameState.move_frog_to_case(frog_id)

func _render_shop() -> void:
	_background("shop", Color("493a2a"))
	var root := _begin_screen(true)
	_show_notice(root)
	var header := _panel(0.98)
	root.add_child(header)
	header.add_child(_label("PET SHOP - SUPPLIES, EQUIPMENT & FROG SALES", 24, false, 620))

	var inventory := _panel(0.98)
	root.add_child(inventory)
	var buy_box := VBoxContainer.new()
	buy_box.add_theme_constant_override("separation", 7)
	inventory.add_child(buy_box)
	buy_box.add_child(_label("SHOP INVENTORY", 22, false, 220))
	_add_shop_row(buy_box, "Basic feeder bugs x10", 5, "feeder_pack", false, "Food for daily frog upkeep")
	_add_shop_row(buy_box, "Small hand net", 30, "basic_net", bool(GameState.upgrades["basic_net"]), "Makes the capture timing zone wider")
	_add_shop_row(buy_box, "Blacklight flashlight", 40, "blacklight", bool(GameState.upgrades["blacklight"]), "Reveals fluorescent animals during evening and night")
	_add_shop_row(buy_box, "Larger bug container", 35, "larger_bug_jar", bool(GameState.upgrades["larger_bug_jar"]), "Field equipment upgrade")
	_add_shop_row(buy_box, "Additional 2-frog breeding tank", 65, "second_tank", false, "Adds another breeding tank at home")
	buy_box.add_child(_label("More genetics, field and laboratory equipment will unlock as the breeder progresses.", 15, true, 620))

	var sell_panel := _panel(0.98)
	root.add_child(sell_panel)
	var sell_box := VBoxContainer.new()
	sell_box.add_theme_constant_override("separation", 7)
	sell_panel.add_child(sell_box)
	sell_box.add_child(_label("SELL FROGS", 22, false, 180))
	var found := false
	for frog in GameState.frogs:
		if frog.get("tank_id", "") != "":
			continue
		found = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		sell_box.add_child(row)
		row.add_child(_label("%s | $%d" % [frog["name"], GameState.frog_sale_value(frog)], 17, false, 360))
		var fill := Control.new()
		fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(fill)
		row.add_child(_button("SELL", Callable(GameState, "sell_frog").bind(int(frog["id"])), 120))
	if not found:
		sell_box.add_child(_label("No frogs in the carrying case are available to sell yet.", 16, true, 500))

func _add_shop_row(parent: VBoxContainer, title: String, price: int, item_id: String, owned: bool, description: String) -> void:
	var row_panel := _panel(0.96)
	parent.add_child(row_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row_panel.add_child(row)
	var info := VBoxContainer.new()
	info.custom_minimum_size.x = 620
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(_label("%s   $%d" % [title, price], 18, false, 420))
	info.add_child(_label(description, 14, true, 420))
	var buy := _button("OWNED" if owned else "BUY", Callable(GameState, "buy").bind(item_id), 130)
	buy.disabled = owned
	row.add_child(buy)

func _render_habitat() -> void:
	_background(GameState.current_habitat, Color("38563b"))
	_ensure_targets()
	var root := _begin_screen(false)

	var top := _panel(0.98)
	root.add_child(top)
	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 6)
	top.add_child(top_box)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 16)
	top_box.add_child(status)
	status.add_child(_label("%s - %s" % [_habitat_name(GameState.current_habitat), GameState.time_name()], 22, false, 330))
	status.add_child(_label("CAPTURES %d/3" % GameState.captures_this_period, 17, false, 145))
	status.add_child(_label("CASE %d/%d" % [GameState.case_count(), GameState.CASE_CAPACITY], 17, false, 120))
	var status_fill := Control.new()
	status_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(status_fill)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	top_box.add_child(actions)
	if GameState.upgrades["blacklight"] and GameState.time_index > 0:
		var black := CheckButton.new()
		black.text = "BLACKLIGHT"
		black.custom_minimum_size = Vector2(170, 50)
		black.add_theme_font_size_override("font_size", 16)
		black.button_pressed = GameState.blacklight_on
		black.toggled.connect(_toggle_blacklight)
		actions.add_child(black)
	actions.add_child(_button("SKIP TIME", Callable(GameState, "skip_time"), 150))
	actions.add_child(_button("GO HOME", Callable(GameState, "travel_home"), 150))
	var action_fill := Control.new()
	action_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(action_fill)

	_show_notice(root)
	var hint := _panel(0.90)
	root.add_child(hint)
	hint.add_child(_label("Tap a visible FROG or BUG below to start the capture game. Three successful captures advance Day -> Evening -> Night.", 16, true, 700))

	var map_panel := _panel(0.34)
	root.add_child(map_panel)
	var map := Control.new()
	map.custom_minimum_size = Vector2(0, 440)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.add_child(map)
	for target in habitat_targets:
		_add_target(map, target)
	if habitat_targets.is_empty():
		var again := _button("SEARCH AGAIN", Callable(self, "_search_again"), 180)
		_set_rect(again, Rect2(0.40, 0.42, 0.20, 0.12))
		map.add_child(again)

func _add_target(map: Control, target: Dictionary) -> void:
	var pos: Vector2 = target.get("pos", Vector2(0.5, 0.5))
	var target_size := Vector2(0.16, 0.24) if target["kind"] == "frog" else Vector2(0.15, 0.15)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	button.tooltip_text = _target_name(target)
	button.disabled = target["kind"] == "frog" and GameState.case_count() >= GameState.CASE_CAPACITY
	button.pressed.connect(Callable(self, "_open_capture").bind(target))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.040, 0.88)
	style.border_color = Color(0.95, 0.88, 0.48, 1.0)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("normal", style)
	_set_rect(button, Rect2(pos.x - target_size.x / 2.0, pos.y - target_size.y / 2.0, target_size.x, target_size.y))
	map.add_child(button)

	if target["kind"] == "frog":
		button.text = ""
		var frog_data := {
			"species": target["species"],
			"hue": 110,
			"fluorescent": bool(target.get("fluorescent", false) and GameState.blacklight_on)
		}
		var visual := FrogVisual.new()
		visual.configure(frog_data, "top")
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		visual.modulate.a = 0.90
		button.add_child(visual)
		var tag := _label("FROG\n%s" % _target_name(target), 14, false, 0)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(tag)
	else:
		button.text = "BUG\n%s" % _target_name(target).to_upper()

func _ensure_targets() -> void:
	var key := "%s:%d:%d" % [GameState.current_habitat, GameState.day, GameState.time_index]
	if key != last_period_key:
		last_period_key = key
		_generate_targets()

func _generate_targets() -> void:
	habitat_targets.clear()
	var pool := _target_pool(GameState.current_habitat, GameState.time_index)
	var positions := HABITAT_POSITIONS.duplicate()
	positions.shuffle()
	var count := randi_range(5, 7)
	for i in range(count):
		var target: Dictionary = pool.pick_random().duplicate(true)
		target_serial += 1
		target["uid"] = target_serial
		target["fluorescent"] = randf() < 0.07
		target["pos"] = positions[i % positions.size()]
		habitat_targets.append(target)

func _target_pool(habitat: String, time: int) -> Array[Dictionary]:
	if habitat == "pond":
		if time == 0:
			return [{"kind":"frog","species":"regular_frog"}, {"kind":"frog","species":"bullfrog"}, {"kind":"bug","species":"water_beetle"}]
		if time == 1:
			return [{"kind":"frog","species":"regular_frog"}, {"kind":"frog","species":"bullfrog"}, {"kind":"bug","species":"water_beetle"}, {"kind":"bug","species":"mosquito"}]
		return [{"kind":"frog","species":"regular_frog"}, {"kind":"frog","species":"bullfrog"}, {"kind":"bug","species":"mosquito"}]
	if time == 0:
		return [{"kind":"frog","species":"regular_frog"}, {"kind":"bug","species":"worm"}, {"kind":"bug","species":"worm"}]
	if time == 1:
		return [{"kind":"frog","species":"regular_frog"}, {"kind":"bug","species":"worm"}, {"kind":"bug","species":"cricket"}]
	return [{"kind":"frog","species":"regular_frog"}, {"kind":"bug","species":"cricket"}, {"kind":"bug","species":"cricket"}]

func _target_name(target: Dictionary) -> String:
	var name := str(target["species"]).replace("_", " ").capitalize()
	if target.get("fluorescent", false) and GameState.blacklight_on and GameState.time_index > 0:
		name = "FLUORESCENT %s" % name.to_upper()
	return name

func _toggle_blacklight(on: bool) -> void:
	GameState.blacklight_on = on
	_render()

func _search_again() -> void:
	_generate_targets()
	_render()

func _open_capture(target: Dictionary) -> void:
	active_target = target
	capture_value = 0.0
	capture_direction = 1.0
	capture_speed = 58.0 if GameState.upgrades["basic_net"] else 85.0
	var zone_width := 34.0 if GameState.upgrades["basic_net"] else 18.0
	var center := randf_range(25.0, 75.0)
	capture_low = maxf(2.0, center - zone_width / 2.0)
	capture_high = minf(98.0, center + zone_width / 2.0)

	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.84)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	var center_box := CenterContainer.new()
	center_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_box)
	var panel := _panel(1.0)
	panel.custom_minimum_size = Vector2(720, 330)
	center_box.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 13)
	panel.add_child(box)
	box.add_child(_label("CAPTURE %s" % _target_name(target).to_upper(), 26, false, 500))
	box.add_child(_label("Tap CATCH while the white marker is inside the green zone.", 17, true, 600))

	capture_track = Control.new()
	capture_track.custom_minimum_size = Vector2(660, 68)
	box.add_child(capture_track)
	var track_bg := ColorRect.new()
	track_bg.color = Color(0.14, 0.14, 0.14, 1.0)
	track_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capture_track.add_child(track_bg)
	var zone := ColorRect.new()
	zone.color = Color(0.18, 0.78, 0.28, 0.95)
	zone.anchor_left = capture_low / 100.0
	zone.anchor_right = capture_high / 100.0
	zone.anchor_top = 0.0
	zone.anchor_bottom = 1.0
	capture_track.add_child(zone)
	capture_marker = ColorRect.new()
	capture_marker.color = Color.WHITE
	capture_marker.size = Vector2(10, 68)
	capture_track.add_child(capture_marker)

	var catch := _button("CATCH!", Callable(self, "_resolve_capture"), 300)
	catch.custom_minimum_size.y = 72
	catch.add_theme_font_size_override("font_size", 25)
	box.add_child(catch)
	capture_running = true

func _resolve_capture() -> void:
	if not capture_running:
		return
	capture_running = false
	var success := capture_value >= capture_low and capture_value <= capture_high
	_remove_target(int(active_target.get("uid", -1)))
	if success:
		notice_text = "Capture successful!"
		if active_target["kind"] == "frog":
			GameState.record_frog_capture(str(active_target["species"]), bool(active_target.get("fluorescent", false)))
		else:
			GameState.record_bug_capture(str(active_target["species"]), bool(active_target.get("fluorescent", false)))
	else:
		notice_text = "Missed! The animal escaped."
		GameState.state_changed.emit()

func _remove_target(uid: int) -> void:
	for i in range(habitat_targets.size() - 1, -1, -1):
		if int(habitat_targets[i].get("uid", -2)) == uid:
			habitat_targets.remove_at(i)
			return

func _set_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0

func _habitat_name(id: String) -> String:
	if id == "backyard_puddle":
		return "Backyard Puddle"
	if id == "pond":
		return "Pond"
	return id.capitalize()

func _on_notice(text: String) -> void:
	notice_text = text
	_render()
