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

var habitat_targets: Array[Dictionary] = []
var _target_serial := 0
var _last_period_key := ""
var _notice_text := ""

var capture_overlay: Control
var capture_bar: ProgressBar
var capture_zone_label: Label
var capture_result_label: Label
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
		"shop": _render_shop()
		"habitat": _render_habitat()
		_: _render_home()

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _add_scene_background(asset_key: String, fallback: Color) -> void:
	var back := ColorRect.new()
	back.color = fallback
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var path: String = SCENE_ASSETS.get(asset_key, "")
	if path != "" and ResourceLoader.exists(path):
		var image := TextureRect.new()
		image.texture = load(path)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(image)

func _make_root() -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	return root

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.modulate = Color(1, 1, 1, 0.94)
	return p

func _label(text: String, size := 18) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _button(text: String, callable: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	b.pressed.connect(callable)
	return b

func _render_navigation(root: VBoxContainer) -> void:
	var p := _panel()
	root.add_child(p)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	p.add_child(row)
	row.add_child(_label("Day %d" % GameState.day, 22))
	row.add_child(_label("$%d" % GameState.cash, 22))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	if GameState.current_screen == "home":
		row.add_child(_button("Pet Shop", func(): GameState.travel_shop()))
	elif GameState.current_screen == "shop":
		row.add_child(_button("Home / Lab", func(): GameState.travel_home()))
	var picker := OptionButton.new()
	picker.name = "HabitatPicker"
	for habitat in GameState.unlocked_habitats:
		picker.add_item(_habitat_name(habitat))
		picker.set_item_metadata(picker.item_count - 1, habitat)
	row.add_child(picker)
	row.add_child(_button("Go to Habitat", func():
		if picker.item_count > 0:
			GameState.travel_habitat(str(picker.get_item_metadata(picker.selected)))
	))

func _render_notice(root: VBoxContainer) -> void:
	if _notice_text == "":
		return
	var p := _panel()
	root.add_child(p)
	var text := _label(_notice_text, 17)
	text.modulate = Color(0.18, 0.12, 0.03)
	p.add_child(text)

func _render_home() -> void:
	_add_scene_background("home", Color("314238"))
	var root := _make_root()
	_render_navigation(root)
	_render_notice(root)

	var upkeep := _panel()
	root.add_child(upkeep)
	var upkeep_row := HBoxContainer.new()
	upkeep.add_child(upkeep_row)
	upkeep_row.add_child(_label("Morning Frog Upkeep: %s" % ("COMPLETE" if GameState.upkeep_complete() else "FEEDING REQUIRED"), 20))
	var up_space := Control.new()
	up_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upkeep_row.add_child(up_space)
	upkeep_row.add_child(_label("Basic feeder bugs: %d" % GameState.feeder_food, 17))
	upkeep_row.add_child(_button("Feed All", func(): GameState.feed_all()))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	root.add_child(columns)

	var frog_panel := _panel()
	frog_panel.custom_minimum_size = Vector2(430, 0)
	columns.add_child(frog_panel)
	var frog_box := VBoxContainer.new()
	frog_box.add_theme_constant_override("separation", 6)
	frog_panel.add_child(frog_box)
	frog_box.add_child(_label("Your Frogs", 23))
	frog_box.add_child(_label("Carrying case: %d / %d" % [GameState.case_count(), GameState.CASE_CAPACITY], 16))
	var frog_scroll := ScrollContainer.new()
	frog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frog_box.add_child(frog_scroll)
	var frog_list := VBoxContainer.new()
	frog_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frog_scroll.add_child(frog_list)
	if GameState.frogs.is_empty():
		frog_list.add_child(_label("No frogs yet. Visit the Backyard Puddle and catch your first frogs by hand.", 17))
	else:
		for frog in GameState.frogs:
			frog_list.add_child(_frog_row(frog))

	var tank_panel := _panel()
	tank_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(tank_panel)
	var tank_box := VBoxContainer.new()
	tank_box.add_theme_constant_override("separation", 8)
	tank_panel.add_child(tank_box)
	var tank: Dictionary = GameState.current_tank()
	tank_box.add_child(_label("%s — %d/%d frogs" % [tank["name"], tank["frog_ids"].size(), tank["capacity"]], 24))

	var tank_view := CenterContainer.new()
	tank_view.custom_minimum_size = Vector2(0, 300)
	tank_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tank_box.add_child(tank_view)
	var tank_path := TANK_ASSETS[min(GameState.selected_tank, TANK_ASSETS.size() - 1)]
	if ResourceLoader.exists(tank_path):
		var tex := TextureRect.new()
		tex.texture = load(tank_path)
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(640, 280)
		tank_view.add_child(tex)
	else:
		var placeholder := _label("[Tank asset will appear here]\nBackground: %s\nAuto-placed items: %s" % [tank["background"], ", ".join(tank["items"])], 18)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tank_view.add_child(placeholder)

	var breed_row := HBoxContainer.new()
	tank_box.add_child(breed_row)
	breed_row.add_child(_button("Breed Pair", func(): GameState.breed_selected_tank()))
	breed_row.add_child(_label("Nursery: %s" % _nursery_summary(), 16))

	var thumbs := HBoxContainer.new()
	thumbs.add_theme_constant_override("separation", 6)
	tank_box.add_child(thumbs)
	for i in range(GameState.tanks.size()):
		var t: Dictionary = GameState.tanks[i]
		var button := _button("%s\n%d/%d" % [t["name"], t["frog_ids"].size(), t["capacity"]], func(index := i):
			GameState.selected_tank = index
			GameState.state_changed.emit()
		)
		button.custom_minimum_size = Vector2(150, 62)
		thumbs.add_child(button)

func _frog_row(frog: Dictionary) -> Control:
	var p := PanelContainer.new()
	var row := VBoxContainer.new()
	p.add_child(row)
	var hue_text := "Hue %03d" % frog.get("hue", 0)
	var glow := " • Fluorescent" if frog.get("fluorescent", false) else ""
	row.add_child(_label("%s — %s — %s%s" % [frog["name"], frog["sex"], hue_text, glow], 16))
	row.add_child(_label("Condition %d%% • %s • %s" % [frog.get("condition", 100), "Fed" if frog.get("fed_today", false) else "Hungry", "Case" if frog.get("tank_id", "") == "" else frog["tank_id"]], 14))
	var actions := HBoxContainer.new()
	row.add_child(actions)
	if not frog.get("fed_today", false):
		actions.add_child(_button("Feed", func(id := frog["id"]): GameState.feed_frog(id)))
	if frog.get("tank_id", "") == "":
		actions.add_child(_button("Move to Selected Tank", func(id := frog["id"]): GameState.move_frog_to_tank(id, GameState.selected_tank)))
	else:
		actions.add_child(_button("Move to Case", func(id := frog["id"]): GameState.move_frog_to_case(id)))
	return p

func _nursery_summary() -> String:
	if GameState.nursery.is_empty():
		return "empty"
	var counts := {"egg": 0, "tadpole": 0, "froglet": 0, "juvenile": 0}
	for baby in GameState.nursery:
		counts[baby["stage"]] = counts.get(baby["stage"], 0) + 1
	return "Egg %d | Tadpole %d | Froglet %d | Juvenile %d" % [counts["egg"], counts["tadpole"], counts["froglet"], counts["juvenile"]]

func _render_shop() -> void:
	_add_scene_background("shop", Color("55432f"))
	var root := _make_root()
	_render_navigation(root)
	_render_notice(root)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	root.add_child(columns)

	var buy_panel := _panel()
	buy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(buy_panel)
	var buy := VBoxContainer.new()
	buy_panel.add_child(buy)
	buy.add_child(_label("Pet Shop — Supplies & Equipment", 24))
	buy.add_child(_shop_item("Basic Feeder Bug Pack ×10", "$5", "feeder_pack"))
	buy.add_child(_shop_item("Small Hand Net — easier capture timing", "$30", "basic_net", GameState.upgrades["basic_net"]))
	buy.add_child(_shop_item("Blacklight Flashlight — evening/night fluorescence", "$40", "blacklight", GameState.upgrades["blacklight"]))
	buy.add_child(_shop_item("Larger Bug Container", "$35", "larger_bug_jar", GameState.upgrades["larger_bug_jar"]))
	buy.add_child(_shop_item("Additional 2-Frog Breeding Tank", "$65", "second_tank"))
	if "pond" not in GameState.unlocked_habitats:
		buy.add_child(_label("Shopkeeper: Keep working with your frogs. I may know another place worth visiting.", 16))
	else:
		buy.add_child(_label("Shopkeeper: Try the Pond. People have seen much larger frogs there.", 16))

	var sell_panel := _panel()
	sell_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(sell_panel)
	var sell := VBoxContainer.new()
	sell_panel.add_child(sell)
	sell.add_child(_label("Sell Frogs", 24))
	var has_sellable := false
	for frog in GameState.frogs:
		if frog.get("tank_id", "") != "":
			continue
		has_sellable = true
		var row := HBoxContainer.new()
		sell.add_child(row)
		row.add_child(_label("%s — $%d" % [frog["name"], GameState.frog_sale_value(frog)], 16))
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		row.add_child(_button("Sell", func(id := frog["id"]): GameState.sell_frog(id)))
	if not has_sellable:
		sell.add_child(_label("Frogs in tanks must be moved to the case before they can be sold.", 16))

func _shop_item(title: String, price: String, item_id: String, owned := false) -> Control:
	var row := HBoxContainer.new()
	row.add_child(_label("%s  %s" % [title, price], 17))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var b := _button("Owned" if owned else "Buy", func(): GameState.buy(item_id))
	b.disabled = owned
	row.add_child(b)
	return row

func _render_habitat() -> void:
	_add_scene_background(GameState.current_habitat, Color("355b3b") if GameState.current_habitat == "backyard_puddle" else Color("315b62"))
	_ensure_habitat_targets()
	var root := _make_root()
	var top := _panel()
	root.add_child(top)
	var bar := HBoxContainer.new()
	top.add_child(bar)
	bar.add_child(_label("%s — Day %d — %s" % [_habitat_name(GameState.current_habitat), GameState.day, GameState.time_name()], 23))
	bar.add_child(_label("Captures: %d / 3" % GameState.captures_this_period, 18))
	bar.add_child(_label("Frog case: %d / %d" % [GameState.case_count(), GameState.CASE_CAPACITY], 18))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	if GameState.upgrades["blacklight"] and GameState.time_index > 0:
		var black := CheckButton.new()
		black.text = "Blacklight"
		black.button_pressed = GameState.blacklight_on
		black.toggled.connect(func(on: bool):
			GameState.blacklight_on = on
			_render()
		)
		bar.add_child(black)
	bar.add_child(_button("Skip %s" % GameState.time_name(), func(): GameState.skip_time()))
	bar.add_child(_button("Go Home", func(): GameState.travel_home()))
	_render_notice(root)

	var search_panel := _panel()
	search_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(search_panel)
	var search_box := VBoxContainer.new()
	search_panel.add_child(search_box)
	search_box.add_child(_label("Search the area — choose what is worth a capture", 22))
	search_box.add_child(_label("A successful capture uses one of this period's three captures. A miss makes that animal escape.", 15))
	if GameState.upgrades["blacklight"] and GameState.time_index > 0:
		search_box.add_child(_label("Blacklight %s. Fluorescent animals are easier to identify while it is on." % ("ON" if GameState.blacklight_on else "OFF"), 15))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	search_box.add_child(grid)
	for target in habitat_targets:
		var card := Button.new()
		card.custom_minimum_size = Vector2(250, 120)
		card.text = _target_display_name(target)
		card.disabled = target["kind"] == "frog" and GameState.case_count() >= GameState.CASE_CAPACITY
		card.pressed.connect(func(t := target): _open_capture(t))
		grid.add_child(card)
	if habitat_targets.is_empty():
		search_box.add_child(_button("Search Again", func():
			_generate_targets()
			_render()
		))

func _ensure_habitat_targets() -> void:
	var key := "%s:%d:%d" % [GameState.current_habitat, GameState.day, GameState.time_index]
	if key != _last_period_key:
		_last_period_key = key
		_generate_targets()

func _generate_targets() -> void:
	habitat_targets.clear()
	var pool := _target_pool(GameState.current_habitat, GameState.time_index)
	var count := randi_range(4, 6)
	for i in count:
		var template: Dictionary = pool.pick_random().duplicate(true)
		_target_serial += 1
		template["uid"] = _target_serial
		template["fluorescent"] = randf() < 0.07
		habitat_targets.append(template)

func _target_pool(habitat: String, time: int) -> Array[Dictionary]:
	if habitat == "pond":
		if time == 0:
			return [{"kind":"frog","species":"regular_frog"}, {"kind":"frog","species":"bullfrog"}, {"kind":"bug","species":"water_beetle"}]
		elif time == 1:
			return [{"kind":"frog","species":"regular_frog"}, {"kind":"frog","species":"bullfrog"}, {"kind":"bug","species":"water_beetle"}, {"kind":"bug","species":"mosquito"}]
		return [{"kind":"frog","species":"bullfrog"}, {"kind":"frog","species":"regular_frog"}, {"kind":"bug","species":"mosquito"}]
	if time == 0:
		return [{"kind":"frog","species":"regular_frog"}, {"kind":"bug","species":"worm"}, {"kind":"bug","species":"worm"}]
	elif time == 1:
		return [{"kind":"frog","species":"regular_frog"}, {"kind":"bug","species":"worm"}, {"kind":"bug","species":"cricket"}]
	return [{"kind":"frog","species":"regular_frog"}, {"kind":"bug","species":"cricket"}, {"kind":"bug","species":"cricket"}]

func _target_display_name(target: Dictionary) -> String:
	var name := str(target["species"]).replace("_", " ").capitalize()
	if target.get("fluorescent", false) and GameState.blacklight_on and GameState.time_index > 0:
		name = "FLUORESCENT %s" % name.to_upper()
	return "%s\nTap to attempt capture" % name

func _open_capture(target: Dictionary) -> void:
	active_target = target
	capture_value = 0.0
	capture_direction = 1.0
	capture_speed = 58.0 if GameState.upgrades["basic_net"] else 85.0
	var width := 34.0 if GameState.upgrades["basic_net"] else 18.0
	var center := randf_range(25.0, 75.0)
	capture_low = max(2.0, center - width / 2.0)
	capture_high = min(98.0, center + width / 2.0)

	capture_overlay = ColorRect.new()
	capture_overlay.color = Color(0, 0, 0, 0.72)
	capture_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(capture_overlay)
	var center_box := CenterContainer.new()
	center_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capture_overlay.add_child(center_box)
	var p := _panel()
	p.custom_minimum_size = Vector2(700, 330)
	center_box.add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	p.add_child(box)
	box.add_child(_label("Capture: %s" % str(target["species"]).replace("_", " ").capitalize(), 25))
	box.add_child(_label("%s. Tap CATCH while the moving marker is inside the success zone." % ("Small net equipped" if GameState.upgrades["basic_net"] else "Catching by hand"), 17))
	capture_zone_label = _label("Success zone: %.0f – %.0f" % [capture_low, capture_high], 18)
	box.add_child(capture_zone_label)
	capture_bar = ProgressBar.new()
	capture_bar.min_value = 0
	capture_bar.max_value = 100
	capture_bar.value = 0
	capture_bar.show_percentage = true
	capture_bar.custom_minimum_size = Vector2(650, 55)
	box.add_child(capture_bar)
	capture_result_label = _label("", 18)
	box.add_child(capture_result_label)
	var catch_button := _button("CATCH!", _resolve_capture)
	catch_button.custom_minimum_size = Vector2(0, 70)
	box.add_child(catch_button)
	capture_running = true

func _resolve_capture() -> void:
	if not capture_running:
		return
	capture_running = false
	var success := capture_value >= capture_low and capture_value <= capture_high
	var uid: int = active_target.get("uid", -1)
	_remove_target(uid)
	if success:
		var fluorescent: bool = active_target.get("fluorescent", false)
		if active_target["kind"] == "frog":
			GameState.record_frog_capture(active_target["species"], fluorescent)
		else:
			GameState.record_bug_capture(active_target["species"], fluorescent)
		_notice_text = "Capture successful!"
	else:
		_notice_text = "Missed! The animal escaped. The capture slot is still available."
		GameState.state_changed.emit()

func _remove_target(uid: int) -> void:
	for i in range(habitat_targets.size() - 1, -1, -1):
		if habitat_targets[i].get("uid", -2) == uid:
			habitat_targets.remove_at(i)
			return

func _habitat_name(id: String) -> String:
	return "Backyard Puddle" if id == "backyard_puddle" else "Pond" if id == "pond" else id.capitalize()

func _on_notice(text: String) -> void:
	_notice_text = text
	_render()
