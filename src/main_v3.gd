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

const TANK_SHELLS := [
	"res://assets/tanks/tank_small_01.webp",
	"res://assets/tanks/tank_small_02.webp",
	"res://assets/tanks/tank_small_03.webp",
	"res://assets/tanks/tank_small_04.webp"
]

const TANK_BACKGROUNDS := {
	"rock_moss": "res://assets/tank_backgrounds/rock_moss.webp",
	"tropical_vines": "res://assets/tank_backgrounds/tropical_vines.webp",
	"bark_moss": "res://assets/tank_backgrounds/bark_moss.webp"
}

const HABITAT_POSITIONS := [
	Vector2(0.14, 0.19), Vector2(0.34, 0.28), Vector2(0.58, 0.18), Vector2(0.79, 0.27),
	Vector2(0.20, 0.56), Vector2(0.46, 0.61), Vector2(0.70, 0.54), Vector2(0.84, 0.72)
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
	var w := capture_track.size.x
	capture_marker.position.x = clampf(w * capture_value / 100.0 - 5.0, 0.0, maxf(0.0, w - 10.0))

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

func _ui_box() -> VBoxContainer:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	layer.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(box)
	return box

func _panel(alpha := 0.94) -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.065, alpha)
	style.border_color = Color(0.67, 0.78, 0.52, 0.95)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	p.add_theme_stylebox_override("panel", style)
	return p

func _label(text: String, size := 18) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(action)
	return b

func _top_navigation(root: VBoxContainer) -> void:
	var p := _panel(0.97)
	root.add_child(p)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	p.add_child(row)
	row.add_child(_label("Day %d" % GameState.day, 22))
	row.add_child(_label("$%d" % GameState.cash, 22))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	if GameState.current_screen == "home":
		row.add_child(_button("PET SHOP", Callable(GameState, "travel_shop")))
	elif GameState.current_screen == "shop":
		row.add_child(_button("HOME / LAB", Callable(GameState, "travel_home")))
	habitat_picker = OptionButton.new()
	habitat_picker.custom_minimum_size = Vector2(210, 52)
	habitat_picker.add_theme_font_size_override("font_size", 18)
	for habitat in GameState.unlocked_habitats:
		habitat_picker.add_item(_habitat_name(habitat))
		habitat_picker.set_item_metadata(habitat_picker.item_count - 1, habitat)
	row.add_child(habitat_picker)
	row.add_child(_button("GO TO HABITAT", _go_selected_habitat))

func _go_selected_habitat() -> void:
	if habitat_picker != null and habitat_picker.item_count > 0:
		GameState.travel_habitat(str(habitat_picker.get_item_metadata(habitat_picker.selected)))

func _show_notice(root: VBoxContainer) -> void:
	if notice_text == "":
		return
	var p := _panel(0.98)
	root.add_child(p)
	p.add_child(_label(notice_text, 17))

func _render_home() -> void:
	_background("home", Color("26342c"))
	var root := _ui_box()
	_top_navigation(root)
	_show_notice(root)

	var upkeep := _panel(0.97)
	root.add_child(upkeep)
	var upkeep_row := HBoxContainer.new()
	upkeep.add_child(upkeep_row)
	upkeep_row.add_child(_label("Morning Frog Upkeep: %s" % ("COMPLETE" if GameState.upkeep_complete() else "FEEDING REQUIRED"), 19))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upkeep_row.add_child(fill)
	upkeep_row.add_child(_label("Food: %d" % GameState.feeder_food, 17))
	upkeep_row.add_child(_button("FEED ALL", Callable(GameState, "feed_all")))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	_render_roster(body)
	_render_tank(body)

func _render_roster(parent: Control) -> void:
	var p := _panel(0.96)
	p.custom_minimum_size = Vector2(360, 0)
	parent.add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	p.add_child(box)
	box.add_child(_label("FROG CASE", 24))
	box.add_child(_label("%d / %d frogs" % [GameState.case_count(), GameState.CASE_CAPACITY], 17))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	if GameState.frogs.is_empty():
		list.add_child(_label("No frogs yet. Go to the Backyard Puddle and catch your starter frogs by hand.", 17))
	else:
		for frog in GameState.frogs:
			var card := _panel(0.98)
			list.add_child(card)
			var cbox := VBoxContainer.new()
			card.add_child(cbox)
			cbox.add_child(_label("%s • %s • Hue %03d" % [frog["name"], frog["sex"], int(frog.get("hue", 0))], 16))
			var actions := HBoxContainer.new()
			cbox.add_child(actions)
			var frog_id := int(frog["id"])
			if not frog.get("fed_today", false):
				actions.add_child(_button("Feed", Callable(self, "_feed_frog").bind(frog_id)))
			if frog.get("tank_id", "") == "":
				actions.add_child(_button("Put in Tank", Callable(self, "_put_frog_in_tank").bind(frog_id)))
			else:
				actions.add_child(_button("Move to Case", Callable(self, "_move_frog_to_case").bind(frog_id)))

func _render_tank(parent: Control) -> void:
	var p := _panel(0.94)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	p.add_child(box)
	var tank: Dictionary = GameState.current_tank()
	box.add_child(_label("%s — %d/%d frogs" % [tank["name"], tank["frog_ids"].size(), tank["capacity"]], 24))

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(720, 430)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.clip_contents = true
	box.add_child(stage)
	_build_tank_stage(stage, tank)

	var tank_row := HBoxContainer.new()
	tank_row.add_theme_constant_override("separation", 8)
	box.add_child(tank_row)
	for i in range(GameState.tanks.size()):
		var t: Dictionary = GameState.tanks[i]
		var b := _button("%s\n%d/%d" % [t["name"], t["frog_ids"].size(), t["capacity"]], Callable(self, "_select_tank").bind(i))
		b.disabled = i == GameState.selected_tank
		tank_row.add_child(b)

	var storage := HBoxContainer.new()
	storage.add_theme_constant_override("separation", 6)
	box.add_child(storage)
	storage.add_child(_label("Starter décor:", 16))
	for item_id in ["water_dish", "fern", "bark_cave", "leaf_litter", "rock_cluster", "broadleaf_plant", "bark_bridge", "moss_mound"]:
		if item_id not in tank.get("items", []):
			storage.add_child(_button(str(item_id).replace("_", " ").capitalize(), Callable(self, "_add_tank_item").bind(str(item_id))))

func _build_tank_stage(stage: Control, tank: Dictionary) -> void:
	var table_path: String = SCENE_ASSETS["table"]
	if ResourceLoader.exists(table_path):
		var table := TextureRect.new()
		table.texture = load(table_path)
		table.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		table.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		table.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(table, Rect2(0.0, 0.62, 1.0, 0.38))
		stage.add_child(table)

	var tank_area := Panel.new()
	var tank_style := StyleBoxFlat.new()
	tank_style.bg_color = Color(0.05, 0.11, 0.10, 0.72)
	tank_style.border_color = Color(0.78, 0.86, 0.78, 1.0)
	tank_style.set_border_width_all(5)
	tank_area.add_theme_stylebox_override("panel", tank_style)
	tank_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(tank_area, Rect2(0.08, 0.05, 0.84, 0.82))
	stage.add_child(tank_area)

	var bg_path: String = TANK_BACKGROUNDS.get(str(tank.get("background", "rock_moss")), "")
	if bg_path != "" and ResourceLoader.exists(bg_path):
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(bg, Rect2(0.11, 0.10, 0.78, 0.66))
		stage.add_child(bg)

	for item_id in tank.get("items", []):
		var id := str(item_id)
		var b := Button.new()
		b.flat = true
		b.tooltip_text = "%s — tap to move to storage" % id.replace("_", " ").capitalize()
		b.pressed.connect(Callable(self, "_remove_tank_item").bind(id))
		var path: String = TANK_ITEM_ASSETS.get(id, "")
		if path != "" and ResourceLoader.exists(path):
			b.icon = load(path)
			b.expand_icon = true
		else:
			b.text = id.replace("_", " ").capitalize()
		b.add_theme_font_size_override("font_size", 14)
		_set_rect(b, _item_rect(id))
		stage.add_child(b)

	var frog_ids: Array = tank.get("frog_ids", [])
	for i in range(mini(2, frog_ids.size())):
		var frog := GameState.get_frog(int(frog_ids[i]))
		if frog.is_empty():
			continue
		var visual := FrogVisual.new()
		visual.configure(frog, "side")
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(visual, Rect2(0.26 + 0.30 * i, 0.46, 0.25, 0.24))
		stage.add_child(visual)

	var shell_index := mini(GameState.selected_tank, TANK_SHELLS.size() - 1)
	var shell_path: String = TANK_SHELLS[shell_index]
	if ResourceLoader.exists(shell_path):
		var shell := TextureRect.new()
		shell.texture = load(shell_path)
		shell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(shell, Rect2(0.06, 0.02, 0.88, 0.88))
		stage.add_child(shell)

	var title := _label("ACTIVE FROG TANK", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(title, Rect2(0.36, 0.08, 0.28, 0.08))
	stage.add_child(title)

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

func _feed_frog(frog_id: int) -> void:
	GameState.feed_frog(frog_id)

func _put_frog_in_tank(frog_id: int) -> void:
	GameState.move_frog_to_tank(frog_id, GameState.selected_tank)

func _move_frog_to_case(frog_id: int) -> void:
	GameState.move_frog_to_case(frog_id)

func _render_shop() -> void:
	_background("shop", Color("493a2a"))
	var root := _ui_box()
	_top_navigation(root)
	_show_notice(root)
	var header := _panel(0.98)
	root.add_child(header)
	header.add_child(_label("PET SHOP — SUPPLIES, EQUIPMENT & FROG SALES", 25))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	root.add_child(columns)

	var buy_panel := _panel(0.98)
	buy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(buy_panel)
	var buy_box := VBoxContainer.new()
	buy_box.add_theme_constant_override("separation", 10)
	buy_panel.add_child(buy_box)
	buy_box.add_child(_label("SHOP INVENTORY", 24))
	_add_shop_row(buy_box, "Basic feeder bugs ×10", 5, "feeder_pack", false)
	_add_shop_row(buy_box, "Small hand net", 30, "basic_net", bool(GameState.upgrades["basic_net"]))
	_add_shop_row(buy_box, "Blacklight flashlight", 40, "blacklight", bool(GameState.upgrades["blacklight"]))
	_add_shop_row(buy_box, "Larger bug container", 35, "larger_bug_jar", bool(GameState.upgrades["larger_bug_jar"]))
	_add_shop_row(buy_box, "Additional 2-frog breeding tank", 65, "second_tank", false)
	buy_box.add_child(_label("More genetics, field and laboratory equipment will unlock as the breeder progresses.", 16))

	var sell_panel := _panel(0.98)
	sell_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(sell_panel)
	var sell_box := VBoxContainer.new()
	sell_box.add_theme_constant_override("separation", 9)
	sell_panel.add_child(sell_box)
	sell_box.add_child(_label("SELL FROGS", 24))
	var found := false
	for frog in GameState.frogs:
		if frog.get("tank_id", "") != "":
			continue
		found = true
		var row := HBoxContainer.new()
		sell_box.add_child(row)
		row.add_child(_label("%s — $%d" % [frog["name"], GameState.frog_sale_value(frog)], 17))
		var fill := Control.new()
		fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(fill)
		row.add_child(_button("SELL", Callable(GameState, "sell_frog").bind(int(frog["id"]))))
	if not found:
		sell_box.add_child(_label("No frogs in the carrying case are available to sell yet.", 17))

func _add_shop_row(parent: VBoxContainer, title: String, price: int, item_id: String, owned: bool) -> void:
	var row_panel := _panel(0.96)
	parent.add_child(row_panel)
	var row := HBoxContainer.new()
	row_panel.add_child(row)
	row.add_child(_label("%s   $%d" % [title, price], 18))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	var buy := _button("OWNED" if owned else "BUY", Callable(GameState, "buy").bind(item_id))
	buy.disabled = owned
	buy.custom_minimum_size.x = 120
	row.add_child(buy)

func _render_habitat() -> void:
	_background(GameState.current_habitat, Color("38563b"))
	_ensure_targets()
	var root := _ui_box()
	var top := _panel(0.98)
	root.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	top.add_child(row)
	row.add_child(_label("%s — %s" % [_habitat_name(GameState.current_habitat), GameState.time_name()], 24))
	row.add_child(_label("Captures %d/3" % GameState.captures_this_period, 18))
	row.add_child(_label("Case %d/%d" % [GameState.case_count(), GameState.CASE_CAPACITY], 18))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	if GameState.upgrades["blacklight"] and GameState.time_index > 0:
		var black := CheckButton.new()
		black.text = "BLACKLIGHT"
		black.button_pressed = GameState.blacklight_on
		black.toggled.connect(_toggle_blacklight)
		row.add_child(black)
	row.add_child(_button("SKIP TIME", Callable(GameState, "skip_time")))
	row.add_child(_button("GO HOME", Callable(GameState, "travel_home")))
	_show_notice(root)

	var hint := _panel(0.92)
	root.add_child(hint)
	hint.add_child(_label("Tap a visible frog or bug to start the capture timing game. Three successful captures advance Day → Evening → Night.", 17))

	var map := Control.new()
	map.custom_minimum_size = Vector2(0, 590)
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(map)
	for target in habitat_targets:
		_add_target(map, target)
	if habitat_targets.is_empty():
		var again := _button("SEARCH AGAIN", _search_again)
		_set_rect(again, Rect2(0.40, 0.42, 0.20, 0.12))
		map.add_child(again)

func _add_target(map: Control, target: Dictionary) -> void:
	var pos: Vector2 = target["pos"]
	var size := Vector2(0.15, 0.19) if target["kind"] == "frog" else Vector2(0.15, 0.12)
	var b := Button.new()
	b.add_theme_font_size_override("font_size", 18)
	b.text = _target_name(target)
	b.tooltip_text = b.text
	b.disabled = target["kind"] == "frog" and GameState.case_count() >= GameState.CASE_CAPACITY
	b.pressed.connect(Callable(self, "_open_capture").bind(target))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.11, 0.08, 0.88)
	style.border_color = Color(0.90, 0.92, 0.58, 1.0)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	b.add_theme_stylebox_override("normal", style)
	_set_rect(b, Rect2(pos.x - size.x / 2.0, pos.y - size.y / 2.0, size.x, size.y))
	map.add_child(b)
	if target["kind"] == "frog":
		var frog_data := {"species": target["species"], "hue": 110, "fluorescent": bool(target.get("fluorescent", false) and GameState.blacklight_on)}
		var visual := FrogVisual.new()
		visual.configure(frog_data, "top")
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		visual.modulate.a = 0.86
		b.add_child(visual)
		var tag := _label(_target_name(target), 15)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(tag)

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
		return [{"kind":"frog","species":"regular_frog"}, {"kind":"bug","species":"worm"}]
	if time == 1:
		return [{"kind":"frog","species":"regular_frog"}, {"kind":"bug","species":"worm"}, {"kind":"bug","species":"cricket"}]
	return [{"kind":"frog","species":"regular_frog"}, {"kind":"bug","species":"cricket"}]

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
	var width := 34.0 if GameState.upgrades["basic_net"] else 18.0
	var center := randf_range(25.0, 75.0)
	capture_low = maxf(2.0, center - width / 2.0)
	capture_high = minf(98.0, center + width / 2.0)

	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	var center_box := CenterContainer.new()
	center_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_box)
	var p := _panel(1.0)
	p.custom_minimum_size = Vector2(800, 400)
	center_box.add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	p.add_child(box)
	box.add_child(_label("CAPTURE %s" % _target_name(target).to_upper(), 28))
	box.add_child(_label("Tap CATCH while the white marker is inside the green zone.", 19))
	capture_track = Control.new()
	capture_track.custom_minimum_size = Vector2(720, 72)
	box.add_child(capture_track)
	var track_bg := ColorRect.new()
	track_bg.color = Color(0.15, 0.15, 0.15, 1)
	track_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capture_track.add_child(track_bg)
	var zone := ColorRect.new()
	zone.color = Color(0.20, 0.80, 0.30, 0.95)
	zone.anchor_left = capture_low / 100.0
	zone.anchor_right = capture_high / 100.0
	zone.anchor_bottom = 1.0
	capture_track.add_child(zone)
	capture_marker = ColorRect.new()
	capture_marker.color = Color.WHITE
	capture_marker.size = Vector2(10, 72)
	capture_track.add_child(capture_marker)
	var catch := _button("CATCH!", _resolve_capture)
	catch.custom_minimum_size.y = 78
	catch.add_theme_font_size_override("font_size", 26)
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
