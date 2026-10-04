extends Control

const SCENE_ASSETS := {
	"home": "res://assets/scenes/lab.webp",
	"shop": "res://assets/scenes/shop.webp",
	"backyard_puddle": "res://assets/habitats/backyard_puddle.webp",
	"pond": "res://assets/habitats/pond.webp"
}

const TANK_ASSETS := [
	"res://assets/tanks/tank_small_01.webp",
	"res://assets/tanks/tank_small_02.webp",
	"res://assets/tanks/tank_small_03.webp",
	"res://assets/tanks/tank_small_04.webp"
]

var habitat_picker: OptionButton
var habitat_targets: Array[Dictionary] = []
var _target_serial := 0
var _last_period_key := ""
var _notice_text := ""

var capture_bar: ProgressBar
var capture_running := false
var capture_value := 0.0
var capture_direction := 1.0
var capture_speed := 85.0
var capture_low := 40.0
var capture_high := 60.0
var active_target: Dictionary = {}

func _ready() -> void:
	GameState.state_changed.connect(_render)
	GameState.notice.connect(_on_notice)
	_render()

func _process(delta: float) -> void:
	if not capture_running or capture_bar == null:
		return
	capture_value += capture_direction * capture_speed * delta
	if capture_value >= 100.0:
		capture_value = 100.0
		capture_direction = -1.0
	elif capture_value <= 0.0:
		capture_value = 0.0
		capture_direction = 1.0
	capture_bar.value = capture_value

func _render() -> void:
	capture_running = false
	_clear_children()
	match GameState.current_screen:
		"shop":
			_render_shop()
		"habitat":
			_render_habitat()
		_:
			_render_home()

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

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
		add_child(image)

func _root_box() -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	return box

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.modulate = Color(1, 1, 1, 0.94)
	return p

func _label(text: String, size: int = 18) -> Label:
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
	row.add_child(_label("Day %d" % GameState.day, 22))
	row.add_child(_label("$%d" % GameState.cash, 22))
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
	var p := _panel()
	root.add_child(p)
	p.add_child(_label(_notice_text, 16))

func _render_home() -> void:
	_add_background("home", Color("314238"))
	var root := _root_box()
	_navigation(root)
	_notice(root)

	var upkeep := _panel()
	root.add_child(upkeep)
	var upkeep_row := HBoxContainer.new()
	upkeep.add_child(upkeep_row)
	upkeep_row.add_child(_label("Morning Upkeep: %s" % ("COMPLETE" if GameState.upkeep_complete() else "FEED FROGS"), 20))
	var up_fill := Control.new()
	up_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upkeep_row.add_child(up_fill)
	upkeep_row.add_child(_label("Feeder bugs: %d" % GameState.feeder_food, 16))
	upkeep_row.add_child(_button("Feed All", Callable(GameState, "feed_all")))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	root.add_child(columns)

	var frog_panel := _panel()
	frog_panel.custom_minimum_size = Vector2(450, 0)
	columns.add_child(frog_panel)
	var frogs_box := VBoxContainer.new()
	frog_panel.add_child(frogs_box)
	frogs_box.add_child(_label("Frogs", 23))
	frogs_box.add_child(_label("6-Frog Case: %d / %d" % [GameState.case_count(), GameState.CASE_CAPACITY], 15))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frogs_box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	if GameState.frogs.is_empty():
		list.add_child(_label("No frogs yet. Start at the Backyard Puddle and catch them by hand.", 17))
	else:
		for frog in GameState.frogs:
			list.add_child(_frog_card(frog))

	var tank_panel := _panel()
	tank_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(tank_panel)
	var tank_box := VBoxContainer.new()
	tank_panel.add_child(tank_box)
	var tank: Dictionary = GameState.current_tank()
	tank_box.add_child(_label("%s — %d/%d frogs" % [tank["name"], tank["frog_ids"].size(), tank["capacity"]], 23))
	var tank_view := CenterContainer.new()
	tank_view.custom_minimum_size = Vector2(0, 300)
	tank_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tank_box.add_child(tank_view)
	var index := mini(GameState.selected_tank, TANK_ASSETS.size() - 1)
	var tank_path: String = TANK_ASSETS[index]
	if ResourceLoader.exists(tank_path):
		var tex := TextureRect.new()
		tex.texture = load(tank_path)
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(650, 280)
		tank_view.add_child(tex)
	else:
		var item_names := ""
		for item in tank["items"]:
			if item_names != "":
				item_names += ", "
			item_names += str(item)
		var placeholder := _label("[Tank art slot]\nBackground: %s\nAuto-placed starter items: %s" % [tank["background"], item_names], 17)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tank_view.add_child(placeholder)
	var breed_row := HBoxContainer.new()
	tank_box.add_child(breed_row)
	breed_row.add_child(_button("Breed Pair", Callable(GameState, "breed_selected_tank")))
	breed_row.add_child(_label("Nursery: %s" % _nursery_summary(), 15))
	var thumbs := HBoxContainer.new()
	tank_box.add_child(thumbs)
	for i in range(GameState.tanks.size()):
		var t: Dictionary = GameState.tanks[i]
		var b := _button("%s\n%d/%d" % [t["name"], t["frog_ids"].size(), t["capacity"]], Callable(self, "_select_tank").bind(i))
		b.custom_minimum_size = Vector2(145, 60)
		thumbs.add_child(b)

func _frog_card(frog: Dictionary) -> Control:
	var p := PanelContainer.new()
	var box := VBoxContainer.new()
	p.add_child(box)
	var glow := " • Fluorescent" if frog.get("fluorescent", false) else ""
	box.add_child(_label("%s — %s — Hue %03d%s" % [frog["name"], frog["sex"], frog.get("hue", 0), glow], 15))
	box.add_child(_label("Condition %d%% • %s • %s" % [frog.get("condition", 100), "Fed" if frog.get("fed_today", false) else "Hungry", "Case" if frog.get("tank_id", "") == "" else frog["tank_id"]], 14))
	var row := HBoxContainer.new()
	box.add_child(row)
	var frog_id: int = frog["id"]
	if not frog.get("fed_today", false):
		row.add_child(_button("Feed", Callable(self, "_feed_frog").bind(frog_id)))
	if frog.get("tank_id", "") == "":
		row.add_child(_button("Move to Tank", Callable(self, "_move_frog_to_selected_tank").bind(frog_id)))
	else:
		row.add_child(_button("Move to Case", Callable(self, "_move_frog_to_case").bind(frog_id)))
	return p

func _select_tank(index: int) -> void:
	GameState.selected_tank = index
	GameState.state_changed.emit()

func _feed_frog(frog_id: int) -> void:
	GameState.feed_frog(frog_id)

func _move_frog_to_selected_tank(frog_id: int) -> void:
	GameState.move_frog_to_tank(frog_id, GameState.selected_tank)

func _move_frog_to_case(frog_id: int) -> void:
	GameState.move_frog_to_case(frog_id)

func _nursery_summary() -> String:
	if GameState.nursery.is_empty():
		return "empty"
	var counts := {"egg": 0, "tadpole": 0, "froglet": 0, "juvenile": 0}
	for baby in GameState.nursery:
		counts[baby["stage"]] = counts.get(baby["stage"], 0) + 1
	return "Egg %d | Tadpole %d | Froglet %d | Juvenile %d" % [counts["egg"], counts["tadpole"], counts["froglet"], counts["juvenile"]]

func _render_shop() -> void:
	_add_background("shop", Color("55432f"))
	var root := _root_box()
	_navigation(root)
	_notice(root)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	root.add_child(columns)

	var buy_panel := _panel()
	buy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(buy_panel)
	var buy := VBoxContainer.new()
	buy_panel.add_child(buy)
	buy.add_child(_label("Pet Shop — Supplies & Equipment", 24))
	buy.add_child(_shop_item("Basic feeder bugs ×10", "$5", "feeder_pack", false))
	buy.add_child(_shop_item("Small hand net", "$30", "basic_net", GameState.upgrades["basic_net"]))
	buy.add_child(_shop_item("Blacklight flashlight", "$40", "blacklight", GameState.upgrades["blacklight"]))
	buy.add_child(_shop_item("Larger bug container", "$35", "larger_bug_jar", GameState.upgrades["larger_bug_jar"]))
	buy.add_child(_shop_item("Additional 2-frog tank", "$65", "second_tank", false))
	buy.add_child(_label("Shopkeeper: %s" % ("I've heard about a pond nearby. You should take a look." if "pond" in GameState.unlocked_habitats else "Bring me some frogs and I'll let you know about other places to search."), 16))

	var sell_panel := _panel()
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
	var top := _panel()
	root.add_child(top)
	var row := HBoxContainer.new()
	top.add_child(row)
	row.add_child(_label("%s — Day %d — %s" % [_habitat_name(GameState.current_habitat), GameState.day, GameState.time_name()], 22))
	row.add_child(_label("Captures %d/3" % GameState.captures_this_period, 17))
	row.add_child(_label("Case %d/%d" % [GameState.case_count(), GameState.CASE_CAPACITY], 17))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	if GameState.upgrades["blacklight"] and GameState.time_index > 0:
		var black := CheckButton.new()
		black.text = "Blacklight"
		black.button_pressed = GameState.blacklight_on
		black.toggled.connect(Callable(self, "_toggle_blacklight"))
		row.add_child(black)
	row.add_child(_button("Skip %s" % GameState.time_name(), Callable(GameState, "skip_time")))
	row.add_child(_button("Go Home", Callable(GameState, "travel_home")))
	_notice(root)

	var p := _panel()
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(p)
	var box := VBoxContainer.new()
	p.add_child(box)
	box.add_child(_label("Search the area — several opportunities may be visible at once", 22))
	box.add_child(_label("Three successful captures advance the time period. A missed animal escapes without using a capture slot.", 15))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(grid)
	for target in habitat_targets:
		var b := Button.new()
		b.custom_minimum_size = Vector2(250, 115)
		b.text = _target_name(target)
		b.disabled = target["kind"] == "frog" and GameState.case_count() >= GameState.CASE_CAPACITY
		b.pressed.connect(Callable(self, "_open_capture").bind(target))
		grid.add_child(b)
	if habitat_targets.is_empty():
		box.add_child(_button("Search Again", Callable(self, "_search_again")))

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
	for i in range(count):
		var target: Dictionary = pool.pick_random().duplicate(true)
		_target_serial += 1
		target["uid"] = _target_serial
		target["fluorescent"] = randf() < 0.07
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
	return "%s\nTap to capture" % name

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
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var centered := CenterContainer.new()
	centered.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centered)
	var p := _panel()
	p.custom_minimum_size = Vector2(700, 330)
	centered.add_child(p)
	var box := VBoxContainer.new()
	p.add_child(box)
	box.add_child(_label("Capture %s" % str(target["species"]).replace("_", " ").capitalize(), 24))
	box.add_child(_label("%s. Tap CATCH while the marker is inside %.0f–%.0f." % ["Small net equipped" if GameState.upgrades["basic_net"] else "Catching by hand", capture_low, capture_high], 17))
	capture_bar = ProgressBar.new()
	capture_bar.min_value = 0.0
	capture_bar.max_value = 100.0
	capture_bar.value = 0.0
	capture_bar.custom_minimum_size = Vector2(650, 60)
	box.add_child(capture_bar)
	var catch_button := _button("CATCH!", Callable(self, "_resolve_capture"))
	catch_button.custom_minimum_size = Vector2(0, 72)
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
