extends Control

const TINT_SHADER := preload("res://src/frog_tint.gdshader")

const SCENE_ASSETS := {
	"home": "res://assets/scenes/lab.webp",
	"shop": "res://assets/scenes/shop.webp",
	"backyard_puddle": "res://assets/habitats/backyard_puddle.webp",
	"pond": "res://assets/habitats/pond.webp",
	"table": "res://assets/home/table.webp"
}

const TANK_ASSETS := [
	"res://assets/tanks/tank_small_01.webp",
	"res://assets/tanks/tank_small_02.webp",
	"res://assets/tanks/tank_small_03.webp",
	"res://assets/tanks/tank_small_04.webp"
]

const TANK_BACKGROUND_ASSETS := {
	"rock_moss": "res://assets/tank_backgrounds/rock_moss.webp",
	"tropical_vines": "res://assets/tank_backgrounds/tropical_vines.webp",
	"bark_moss": "res://assets/tank_backgrounds/bark_moss.webp"
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

const STARTER_ITEMS := [
	"leaf_litter", "broadleaf_plant", "bark_bridge", "rock_cluster",
	"fern", "moss_mound", "bark_cave", "water_dish"
]

const ITEM_RECTS := {
	"leaf_litter": Rect2(0.12, 0.67, 0.52, 0.22),
	"broadleaf_plant": Rect2(0.08, 0.27, 0.29, 0.54),
	"bark_bridge": Rect2(0.32, 0.55, 0.38, 0.28),
	"rock_cluster": Rect2(0.63, 0.66, 0.25, 0.20),
	"fern": Rect2(0.62, 0.27, 0.29, 0.52),
	"moss_mound": Rect2(0.16, 0.70, 0.28, 0.17),
	"bark_cave": Rect2(0.37, 0.55, 0.35, 0.30),
	"water_dish": Rect2(0.68, 0.70, 0.23, 0.16)
}

const LIFECYCLE_ASSETS := {
	"egg": "res://assets/lifecycle/eggs_petri_dish.webp",
	"tadpole": "res://assets/lifecycle/tadpole_tank.webp",
	"froglet": "res://assets/lifecycle/froglet_tank.webp",
	"juvenile": "res://assets/lifecycle/juvenile_tank.webp"
}

const HABITAT_POSITIONS := [
	Vector2(0.16, 0.25), Vector2(0.42, 0.18), Vector2(0.73, 0.23),
	Vector2(0.24, 0.58), Vector2(0.55, 0.53), Vector2(0.79, 0.62),
	Vector2(0.40, 0.74), Vector2(0.66, 0.79)
]

var habitat_picker: OptionButton
var habitat_targets: Array[Dictionary] = []
var _target_serial := 0
var _last_period_key := ""
var _notice_text := ""

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
	_ensure_starter_storage()
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
	capture_marker.position.x = clampf(width * capture_value / 100.0 - 4.0, 0.0, maxf(0.0, width - 8.0))

func _render() -> void:
	capture_running = false
	capture_track = null
	capture_marker = null
	_clear_children()
	match GameState.current_screen:
		"shop": _render_shop()
		"habitat": _render_habitat()
		_: _render_home()

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _ensure_starter_storage() -> void:
	if GameState.has_meta("tank_storage_items"):
		return
	var placed := {}
	for tank in GameState.tanks:
		for item in tank.get("items", []):
			placed[str(item)] = true
	var stored: Array[String] = []
	for item in STARTER_ITEMS:
		if not placed.has(item):
			stored.append(item)
	GameState.set_meta("tank_storage_items", stored)

func _add_background(asset_key: String, fallback: Color) -> void:
	var color_back := ColorRect.new()
	color_back.color = fallback
	color_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(color_back)
	var path: String = SCENE_ASSETS.get(asset_key, "")
	if path != "" and ResourceLoader.exists(path):
		var image := TextureRect.new()
		image.texture = load(path)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(image)

func _root_box() -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	margin.add_child(box)
	return box

func _panel(alpha := 0.93) -> PanelContainer:
	var p := PanelContainer.new()
	p.modulate = Color(1, 1, 1, alpha)
	return p

func _label(text: String, size := 18) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(action)
	return b

func _navigation(root: VBoxContainer) -> void:
	var p := _panel()
	root.add_child(p)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	p.add_child(row)
	row.add_child(_label("Day %d" % GameState.day, 21))
	row.add_child(_label("$%d" % GameState.cash, 21))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	if GameState.current_screen == "home":
		row.add_child(_button("Pet Shop", Callable(GameState, "travel_shop")))
	elif GameState.current_screen == "shop":
		row.add_child(_button("Home / Lab", Callable(GameState, "travel_home")))
	habitat_picker = OptionButton.new()
	for habitat in GameState.unlocked_habitats:
		habitat_picker.add_item(_habitat_name(habitat))
		habitat_picker.set_item_metadata(habitat_picker.item_count - 1, habitat)
	row.add_child(habitat_picker)
	row.add_child(_button("Go to Habitat", Callable(self, "_go_selected_habitat")))

func _go_selected_habitat() -> void:
	if habitat_picker != null and habitat_picker.item_count > 0:
		GameState.travel_habitat(str(habitat_picker.get_item_metadata(habitat_picker.selected)))

func _notice(root: VBoxContainer) -> void:
	if _notice_text == "":
		return
	var p := _panel(0.96)
	root.add_child(p)
	p.add_child(_label(_notice_text, 16))

func _render_home() -> void:
	_add_background("home", Color("314238"))
	var root := _root_box()
	_navigation(root)
	_notice(root)
	_render_upkeep(root)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	root.add_child(body)
	_render_frog_roster(body)
	_render_tank_management(body)

func _render_upkeep(root: VBoxContainer) -> void:
	var p := _panel()
	root.add_child(p)
	var row := HBoxContainer.new()
	p.add_child(row)
	row.add_child(_label("Morning Frog Upkeep: %s" % ("COMPLETE" if GameState.upkeep_complete() else "FEEDING REQUIRED"), 19))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	row.add_child(_label("Basic feeder bugs: %d" % GameState.feeder_food, 16))
	row.add_child(_button("Feed All", Callable(GameState, "feed_all")))

func _render_frog_roster(parent: Control) -> void:
	var p := _panel()
	p.custom_minimum_size = Vector2(390, 0)
	parent.add_child(p)
	var box := VBoxContainer.new()
	p.add_child(box)
	box.add_child(_label("Frogs", 22))
	box.add_child(_label("6-Frog Case: %d / %d" % [GameState.case_count(), GameState.CASE_CAPACITY], 15))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	if GameState.frogs.is_empty():
		list.add_child(_label("No frogs yet. Visit the Backyard Puddle and catch the first frogs by hand.", 16))
	else:
		for frog in GameState.frogs:
			list.add_child(_frog_card(frog))

func _frog_card(frog: Dictionary) -> Control:
	var p := PanelContainer.new()
	var box := VBoxContainer.new()
	p.add_child(box)
	var glow := " • Fluorescent" if frog.get("fluorescent", false) else ""
	box.add_child(_label("%s — %s — Hue %03d%s" % [frog["name"], frog["sex"], frog.get("hue", 0), glow], 14))
	box.add_child(_label("Condition %d%% • %s • %s" % [frog.get("condition", 100), "Fed" if frog.get("fed_today", false) else "Hungry", "Case" if frog.get("tank_id", "") == "" else frog["tank_id"]], 13))
	var row := HBoxContainer.new()
	box.add_child(row)
	var frog_id := int(frog["id"])
	if not frog.get("fed_today", false):
		row.add_child(_button("Feed", Callable(self, "_feed_frog").bind(frog_id)))
	if frog.get("tank_id", "") == "":
		row.add_child(_button("Move to Tank", Callable(self, "_move_frog_to_selected_tank").bind(frog_id)))
	else:
		row.add_child(_button("Move to Case", Callable(self, "_move_frog_to_case").bind(frog_id)))
	return p

func _render_tank_management(parent: Control) -> void:
	var p := _panel(0.88)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	p.add_child(box)
	var tank: Dictionary = GameState.current_tank()
	box.add_child(_label("%s — %d/%d frogs" % [tank["name"], tank["frog_ids"].size(), tank["capacity"]], 22))

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(760, 390)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.clip_contents = true
	box.add_child(stage)
	_build_tank_stage(stage, tank)

	var background_row := HBoxContainer.new()
	box.add_child(background_row)
	background_row.add_child(_label("Background:", 15))
	for bg_id in TANK_BACKGROUND_ASSETS.keys():
		var b := _button(str(bg_id).replace("_", " ").capitalize(), Callable(self, "_set_tank_background").bind(str(bg_id)))
		b.disabled = str(tank.get("background", "")) == str(bg_id)
		background_row.add_child(b)

	var storage: Array = GameState.get_meta("tank_storage_items", [])
	var storage_row := HBoxContainer.new()
	box.add_child(storage_row)
	storage_row.add_child(_label("Starter Item Storage:", 15))
	if storage.is_empty():
		storage_row.add_child(_label("empty", 14))
	else:
		for item in storage:
			storage_row.add_child(_button(str(item).replace("_", " ").capitalize(), Callable(self, "_add_stored_item").bind(str(item))))

	var actions := HBoxContainer.new()
	box.add_child(actions)
	actions.add_child(_button("Breed Pair", Callable(GameState, "breed_selected_tank")))
	actions.add_child(_label("Nursery: %s" % _nursery_summary(), 14))

	var nursery_view := _build_nursery_preview()
	if nursery_view != null:
		box.add_child(nursery_view)

	var thumbs := HBoxContainer.new()
	thumbs.add_theme_constant_override("separation", 6)
	box.add_child(thumbs)
	for i in range(GameState.tanks.size()):
		var t: Dictionary = GameState.tanks[i]
		var thumb := TankThumbnail.new()
		thumb.configure(i, "%s\n%d/%d" % [t["name"], t["frog_ids"].size(), t["capacity"]])
		thumb.disabled = i == GameState.selected_tank
		thumb.tank_selected.connect(_select_tank)
		thumb.tank_item_dropped.connect(_transfer_tank_item)
		thumbs.add_child(thumb)
	var storage_drop := TankThumbnail.new()
	storage_drop.configure(-1, "Storage\nDrop Items Here")
	storage_drop.tank_selected.connect(_select_tank)
	storage_drop.tank_item_dropped.connect(_transfer_tank_item)
	thumbs.add_child(storage_drop)

func _build_tank_stage(stage: Control, tank: Dictionary) -> void:
	var table_path: String = SCENE_ASSETS["table"]
	if ResourceLoader.exists(table_path):
		var table := TextureRect.new()
		table.texture = load(table_path)
		table.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		table.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_set_rect(table, Rect2(0.0, 0.55, 1.0, 0.45))
		table.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(table)

	var tank_rect := Rect2(0.08, 0.05, 0.84, 0.84)
	var background_path: String = TANK_BACKGROUND_ASSETS.get(str(tank.get("background", "rock_moss")), "")
	if background_path != "" and ResourceLoader.exists(background_path):
		var bg := TextureRect.new()
		bg.texture = load(background_path)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_set_rect(bg, Rect2(0.13, 0.16, 0.74, 0.58))
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(bg)

	for item_id in tank.get("items", []):
		var id := str(item_id)
		var item := TankItemWidget.new()
		item.configure(id, GameState.selected_tank, str(TANK_ITEM_ASSETS.get(id, "")))
		_set_rect(item, ITEM_RECTS.get(id, Rect2(0.35, 0.60, 0.30, 0.22)))
		stage.add_child(item)

	var frog_ids: Array = tank.get("frog_ids", [])
	for i in range(mini(frog_ids.size(), 2)):
		var frog := GameState.get_frog(int(frog_ids[i]))
		if frog.is_empty():
			continue
		var visual := FrogVisual.new()
		visual.configure(frog, "side")
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var frog_rect := Rect2(0.25, 0.48, 0.28, 0.28) if i == 0 else Rect2(0.49, 0.48, 0.28, 0.28)
		_set_rect(visual, frog_rect)
		stage.add_child(visual)

	var shell_path: String = TANK_ASSETS[mini(GameState.selected_tank, TANK_ASSETS.size() - 1)]
	if ResourceLoader.exists(shell_path):
		var shell := TextureRect.new()
		shell.texture = load(shell_path)
		shell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_set_rect(shell, tank_rect)
		shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(shell)
	else:
		var fallback := Panel.new()
		_set_rect(fallback, tank_rect)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(fallback)
		var msg := _label("Tank art appears here when the WebP shell is present.", 15)
		msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_set_rect(msg, Rect2(0.28, 0.40, 0.44, 0.12))
		stage.add_child(msg)

func _set_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0

func _set_tank_background(background_id: String) -> void:
	GameState.current_tank()["background"] = background_id
	GameState.state_changed.emit()

func _add_stored_item(item_id: String) -> void:
	var storage: Array = GameState.get_meta("tank_storage_items", [])
	if item_id not in storage:
		return
	var tank := GameState.current_tank()
	if item_id in tank.get("items", []):
		return
	storage.erase(item_id)
	tank["items"].append(item_id)
	GameState.set_meta("tank_storage_items", storage)
	GameState.state_changed.emit()

func _transfer_tank_item(item_id: String, source_index: int, destination_index: int) -> void:
	if source_index < 0 or source_index >= GameState.tanks.size():
		return
	var source: Dictionary = GameState.tanks[source_index]
	if item_id not in source.get("items", []):
		return
	source["items"].erase(item_id)
	if destination_index < 0:
		var storage: Array = GameState.get_meta("tank_storage_items", [])
		if item_id not in storage:
			storage.append(item_id)
		GameState.set_meta("tank_storage_items", storage)
	else:
		if destination_index >= GameState.tanks.size():
			return
		var destination: Dictionary = GameState.tanks[destination_index]
		if item_id not in destination.get("items", []):
			destination["items"].append(item_id)
	GameState.state_changed.emit()

func _build_nursery_preview() -> Control:
	if GameState.nursery.is_empty():
		return null
	var baby: Dictionary = GameState.nursery[0]
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 120)
	var path: String = LIFECYCLE_ASSETS.get(str(baby.get("stage", "egg")), "")
	if path != "" and ResourceLoader.exists(path):
		var tex := TextureRect.new()
		tex.texture = load(path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(220, 115)
		row.add_child(tex)
	else:
		row.add_child(_label("[%s life-stage art]" % str(baby.get("stage", "egg")).capitalize(), 15))
	row.add_child(_label("Oldest nursery frog: %s • age %d days • inherited hue %03d" % [str(baby.get("stage", "egg")).capitalize(), int(baby.get("age_days", 0)), int(baby.get("hue", 0))], 14))
	return row

func _nursery_summary() -> String:
	if GameState.nursery.is_empty():
		return "empty"
	var counts := {"egg": 0, "tadpole": 0, "froglet": 0, "juvenile": 0}
	for baby in GameState.nursery:
		counts[baby["stage"]] = counts.get(baby["stage"], 0) + 1
	return "Egg %d | Tadpole %d | Froglet %d | Juvenile %d" % [counts["egg"], counts["tadpole"], counts["froglet"], counts["juvenile"]]

func _select_tank(index: int) -> void:
	if index < 0 or index >= GameState.tanks.size():
		return
	GameState.selected_tank = index
	GameState.state_changed.emit()

func _feed_frog(frog_id: int) -> void:
	GameState.feed_frog(frog_id)

func _move_frog_to_selected_tank(frog_id: int) -> void:
	GameState.move_frog_to_tank(frog_id, GameState.selected_tank)

func _move_frog_to_case(frog_id: int) -> void:
	GameState.move_frog_to_case(frog_id)

func _render_shop() -> void:
	_add_background("shop", Color("55432f"))
	var root := _root_box()
	_navigation(root)
	_notice(root)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	root.add_child(columns)

	var buy_panel := _panel(0.91)
	buy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(buy_panel)
	var buy := VBoxContainer.new()
	buy_panel.add_child(buy)
	buy.add_child(_label("Pet Shop — Supplies & Equipment", 24))
	buy.add_child(_shop_item("Basic feeder bugs ×10", "$5", "feeder_pack", false))
	buy.add_child(_shop_item("Small hand net — easier capture timing", "$30", "basic_net", GameState.upgrades["basic_net"]))
	buy.add_child(_shop_item("Blacklight flashlight — evening/night", "$40", "blacklight", GameState.upgrades["blacklight"]))
	buy.add_child(_shop_item("Larger bug container", "$35", "larger_bug_jar", GameState.upgrades["larger_bug_jar"]))
	buy.add_child(_shop_item("Additional 2-frog breeding tank", "$65", "second_tank", false))
	buy.add_child(_label("Shopkeeper: %s" % ("I've heard about a pond nearby. You should take a look." if "pond" in GameState.unlocked_habitats else "Bring me some frogs and I'll let you know about other places to search."), 16))

	var sell_panel := _panel(0.91)
	sell_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(sell_panel)
	var sell := VBoxContainer.new()
	sell_panel.add_child(sell)
	sell.add_child(_label("Sell Frogs", 24))
	var any_sellable := false
	for frog in GameState.frogs:
		if frog.get("tank_id", "") != "":
			continue
		any_sellable = true
		var row := HBoxContainer.new()
		sell.add_child(row)
		row.add_child(_label("%s — $%d" % [frog["name"], GameState.frog_sale_value(frog)], 15))
		var fill := Control.new()
		fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(fill)
		row.add_child(_button("Sell", Callable(self, "_sell_frog").bind(int(frog["id"]))))
	if not any_sellable:
		sell.add_child(_label("No frogs in the carrying case are available to sell.", 16))

func _shop_item(title: String, price: String, item_id: String, owned: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_child(_label("%s  %s" % [title, price], 17))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	var b := _button("Owned" if owned else "Buy", Callable(self, "_buy_item").bind(item_id))
	b.disabled = owned
	row.add_child(b)
	return row

func _buy_item(item_id: String) -> void:
	GameState.buy(item_id)

func _sell_frog(frog_id: int) -> void:
	GameState.sell_frog(frog_id)

func _render_habitat() -> void:
	_add_background(GameState.current_habitat, Color("355b3b") if GameState.current_habitat == "backyard_puddle" else Color("315b62"))
	_ensure_targets()
	var root := _root_box()
	var top := _panel(0.91)
	root.add_child(top)
	var row := HBoxContainer.new()
	top.add_child(row)
	row.add_child(_label("%s — Day %d — %s" % [_habitat_name(GameState.current_habitat), GameState.day, GameState.time_name()], 21))
	row.add_child(_label("Captures %d/3" % GameState.captures_this_period, 16))
	row.add_child(_label("Case %d/%d" % [GameState.case_count(), GameState.CASE_CAPACITY], 16))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	if GameState.upgrades["blacklight"] and GameState.time_index > 0:
		var black := CheckButton.new()
		black.text = "Blacklight Flashlight"
		black.button_pressed = GameState.blacklight_on
		black.toggled.connect(_toggle_blacklight)
		row.add_child(black)
	row.add_child(_button("Skip %s" % GameState.time_name(), Callable(GameState, "skip_time")))
	row.add_child(_button("Go Home", Callable(GameState, "travel_home")))
	_notice(root)

	var hint := _panel(0.84)
	root.add_child(hint)
	hint.add_child(_label("Search the top-down habitat. Several capture opportunities can be visible at once. Three successful captures advance the time period.", 15))

	var map := Control.new()
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(map)
	for target in habitat_targets:
		_add_habitat_target(map, target)
	if habitat_targets.is_empty():
		var again := _button("Search Again", Callable(self, "_search_again"))
		_set_rect(again, Rect2(0.42, 0.45, 0.16, 0.10))
		map.add_child(again)

func _add_habitat_target(map: Control, target: Dictionary) -> void:
	var position: Vector2 = target.get("pos", Vector2(0.5, 0.5))
	var size := Vector2(0.13, 0.18) if target["kind"] == "frog" else Vector2(0.11, 0.12)
	var rect := Rect2(position.x - size.x / 2.0, position.y - size.y / 2.0, size.x, size.y)
	var b := Button.new()
	b.tooltip_text = _target_name(target).replace("\n", " ")
	b.disabled = target["kind"] == "frog" and GameState.case_count() >= GameState.CASE_CAPACITY
	b.pressed.connect(Callable(self, "_open_capture").bind(target))
	b.modulate = Color(1, 1, 1, 0.90)
	_set_rect(b, rect)
	map.add_child(b)
	if target["kind"] == "frog":
		b.text = ""
		var frog_data := {"species": str(target["species"]), "hue": 110, "fluorescent": bool(target.get("fluorescent", false) and GameState.blacklight_on)}
		var visual := FrogVisual.new()
		visual.configure(frog_data, "top")
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(visual)
		var tag := _label("Frog", 12)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(tag)
	else:
		b.text = _target_name(target)
	if target.get("fluorescent", false) and GameState.blacklight_on and GameState.time_index > 0:
		b.modulate = Color(1.20, 1.20, 1.20, 1.0)

func _toggle_blacklight(on: bool) -> void:
	GameState.blacklight_on = on
	_render()

func _search_again() -> void:
	_generate_targets()
	_render()

func _ensure_targets() -> void:
	var key := "%s:%d:%d" % [GameState.current_habitat, GameState.day, GameState.time_index]
	if key != _last_period_key:
		_last_period_key = key
		_generate_targets()

func _generate_targets() -> void:
	habitat_targets.clear()
	var pool := _target_pool(GameState.current_habitat, GameState.time_index)
	var count := randi_range(4, 6)
	var positions := HABITAT_POSITIONS.duplicate()
	positions.shuffle()
	for i in range(count):
		var target: Dictionary = pool.pick_random().duplicate(true)
		_target_serial += 1
		target["uid"] = _target_serial
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

func _open_capture(target: Dictionary) -> void:
	active_target = target
	capture_value = 0.0
	capture_direction = 1.0
	capture_speed = 58.0 if GameState.upgrades["basic_net"] else 85.0
	var width := 34.0 if GameState.upgrades["basic_net"] else 18.0
	var center := randf_range(25.0, 75.0)
	capture_low = maxf(2.0, center - width / 2.0)
	capture_high = minf(98.0, center + width / 2.0)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.74)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var centered := CenterContainer.new()
	centered.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centered)
	var p := _panel(0.98)
	p.custom_minimum_size = Vector2(740, 360)
	centered.add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	p.add_child(box)
	box.add_child(_label("Capture %s" % str(target["species"]).replace("_", " ").capitalize(), 24))
	box.add_child(_label("%s. Tap CATCH when the moving marker is inside the highlighted capture zone." % ("Small net equipped" if GameState.upgrades["basic_net"] else "Catching by hand"), 16))

	capture_track = Control.new()
	capture_track.custom_minimum_size = Vector2(670, 64)
	box.add_child(capture_track)
	var track_bg := ColorRect.new()
	track_bg.color = Color(0.15, 0.15, 0.15, 1.0)
	track_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capture_track.add_child(track_bg)
	var zone := ColorRect.new()
	zone.color = Color(0.25, 0.80, 0.35, 0.80)
	zone.anchor_left = capture_low / 100.0
	zone.anchor_right = capture_high / 100.0
	zone.anchor_top = 0.0
	zone.anchor_bottom = 1.0
	capture_track.add_child(zone)
	capture_marker = ColorRect.new()
	capture_marker.color = Color(1, 1, 1, 1)
	capture_marker.size = Vector2(8, 64)
	capture_track.add_child(capture_marker)

	var catch_button := _button("CATCH!", Callable(self, "_resolve_capture"))
	catch_button.custom_minimum_size = Vector2(0, 70)
	box.add_child(catch_button)
	capture_running = true

func _resolve_capture() -> void:
	if not capture_running:
		return
	capture_running = false
	var success := capture_value >= capture_low and capture_value <= capture_high
	_remove_target(int(active_target.get("uid", -1)))
	if success:
		_notice_text = "Capture successful!"
		var fluorescent: bool = active_target.get("fluorescent", false)
		if active_target["kind"] == "frog":
			GameState.record_frog_capture(str(active_target["species"]), fluorescent)
		else:
			GameState.record_bug_capture(str(active_target["species"]), fluorescent)
	else:
		_notice_text = "Missed! The animal escaped, but the capture slot remains available."
		GameState.state_changed.emit()

func _remove_target(uid: int) -> void:
	for i in range(habitat_targets.size() - 1, -1, -1):
		if int(habitat_targets[i].get("uid", -2)) == uid:
			habitat_targets.remove_at(i)
			return

func _habitat_name(id: String) -> String:
	if id == "backyard_puddle":
		return "Backyard Puddle"
	if id == "pond":
		return "Pond"
	return id.capitalize()

func _on_notice(text: String) -> void:
	_notice_text = text
	_render()
