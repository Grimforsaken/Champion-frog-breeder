extends "res://src/main_v4.gd"

# Mobile/tablet presentation layer.  The original prototype used nested
# Containers for the full HUD.  On some Android aspect ratios those Containers
# squeezed Labels down to a few pixels, so text wrapped one character per line
# and the menu expanded over the scene.  This layer uses anchored Controls with
# fixed screen regions instead.

func _label(text: String, size: int = 18, wrap: bool = false, min_width: float = 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	l.clip_text = not wrap
	if min_width > 0.0:
		l.custom_minimum_size.x = min_width
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

func _mobile_panel(parent: Control, rect: Rect2, alpha := 0.86) -> Panel:
	var p := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.045, alpha)
	style.border_color = Color(0.70, 0.82, 0.55, 0.94)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	p.add_theme_stylebox_override("panel", style)
	_set_rect(p, rect)
	parent.add_child(p)
	return p

func _mobile_label(parent: Control, text: String, rect: Rect2, size := 18, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := _label(text, size)
	l.horizontal_alignment = align
	_set_rect(l, rect)
	parent.add_child(l)
	return l

func _mobile_button(parent: Control, text: String, rect: Rect2, action: Callable, size := 16) -> Button:
	var b := _button(text, action)
	b.add_theme_font_size_override("font_size", size)
	b.clip_text = true
	_set_rect(b, rect)
	parent.add_child(b)
	return b

func _mobile_hud() -> Control:
	var hud := Control.new()
	_set_rect(hud, Rect2(0.012, 0.015, 0.976, 0.09))
	add_child(hud)
	var bg := _mobile_panel(hud, Rect2(0, 0, 1, 1), 0.90)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_label(hud, "DAY %d" % GameState.day, Rect2(0.015, 0.08, 0.085, 0.84), 19)
	_mobile_label(hud, "$%d" % GameState.cash, Rect2(0.105, 0.08, 0.07, 0.84), 19)
	_mobile_label(hud, "FOOD %d" % GameState.feeder_food, Rect2(0.18, 0.08, 0.105, 0.84), 16)
	return hud

func _mobile_travel(hud: Control, from_shop: bool) -> void:
	if from_shop:
		_mobile_button(hud, "HOME / LAB", Rect2(0.52, 0.10, 0.13, 0.80), Callable(GameState, "travel_home"), 15)
	else:
		_mobile_button(hud, "PET SHOP", Rect2(0.54, 0.10, 0.11, 0.80), Callable(GameState, "travel_shop"), 15)
	habitat_picker = OptionButton.new()
	habitat_picker.add_theme_font_size_override("font_size", 15)
	for habitat in GameState.unlocked_habitats:
		habitat_picker.add_item(_habitat_name(habitat))
		habitat_picker.set_item_metadata(habitat_picker.item_count - 1, habitat)
	_set_rect(habitat_picker, Rect2(0.67, 0.10, 0.19, 0.80))
	hud.add_child(habitat_picker)
	_mobile_button(hud, "GO", Rect2(0.87, 0.10, 0.115, 0.80), _go_selected_habitat, 16)

func _render_home() -> void:
	_background("home", Color("26342c"))
	var hud := _mobile_hud()
	_mobile_travel(hud, false)

	var upkeep := Control.new()
	_set_rect(upkeep, Rect2(0.012, 0.115, 0.976, 0.075))
	add_child(upkeep)
	var upkeep_bg := _mobile_panel(upkeep, Rect2(0, 0, 1, 1), 0.82)
	upkeep_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var status := "COMPLETE" if GameState.upkeep_complete() else "FEEDING REQUIRED"
	_mobile_label(upkeep, "MORNING FROG UPKEEP: %s" % status, Rect2(0.02, 0.08, 0.56, 0.84), 17)
	_mobile_label(upkeep, "CASE %d/%d" % [GameState.case_count(), GameState.CASE_CAPACITY], Rect2(0.60, 0.08, 0.12, 0.84), 16)
	_mobile_label(upkeep, "FOOD %d" % GameState.feeder_food, Rect2(0.73, 0.08, 0.09, 0.84), 16)
	_mobile_button(upkeep, "FEED ALL", Rect2(0.83, 0.08, 0.155, 0.84), Callable(GameState, "feed_all"), 16)

	var stage := Control.new()
	_set_rect(stage, Rect2(0.07, 0.205, 0.86, 0.57))
	stage.clip_contents = true
	add_child(stage)
	_build_tank_stage(stage, GameState.current_tank())

	var bottom := Control.new()
	_set_rect(bottom, Rect2(0.012, 0.79, 0.976, 0.19))
	add_child(bottom)
	var bottom_bg := _mobile_panel(bottom, Rect2(0, 0, 1, 1), 0.84)
	bottom_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tank: Dictionary = GameState.current_tank()
	_mobile_label(bottom, "%s  •  %d/%d frogs" % [tank["name"], tank["frog_ids"].size(), tank["capacity"]], Rect2(0.015, 0.04, 0.32, 0.38), 16)
	_mobile_button(bottom, "BREED", Rect2(0.34, 0.08, 0.10, 0.30), Callable(GameState, "breed_selected_tank"), 14)
	for i in range(mini(4, GameState.tanks.size())):
		var t: Dictionary = GameState.tanks[i]
		var b := _mobile_button(bottom, "TANK %d" % (i + 1), Rect2(0.46 + 0.09 * i, 0.08, 0.082, 0.30), Callable(self, "_select_tank").bind(i), 13)
		b.disabled = i == GameState.selected_tank
	_mobile_button(bottom, "ADD DECOR", Rect2(0.83, 0.08, 0.155, 0.30), _mobile_add_decor, 13)

	if GameState.frogs.is_empty():
		_mobile_label(bottom, "No frogs yet — go to the Backyard Puddle and catch your starter frogs by hand.", Rect2(0.015, 0.49, 0.78, 0.38), 15)
	else:
		var x := 0.015
		var shown := 0
		for frog in GameState.frogs:
			if shown >= 4:
				break
			var frog_id := int(frog["id"])
			var in_tank := frog.get("tank_id", "") != ""
			var action := Callable(self, "_move_frog_to_case").bind(frog_id) if in_tank else Callable(self, "_put_frog_in_tank").bind(frog_id)
			var destination := "CASE" if in_tank else "TANK"
			_mobile_button(bottom, "%s → %s" % [frog["name"], destination], Rect2(x, 0.49, 0.22, 0.38), action, 12)
			x += 0.23
			shown += 1
	_mobile_notice()

func _render_shop() -> void:
	_background("shop", Color("493a2a"))
	var hud := _mobile_hud()
	_mobile_travel(hud, true)

	var inventory := Control.new()
	_set_rect(inventory, Rect2(0.025, 0.13, 0.55, 0.82))
	add_child(inventory)
	var inv_bg := _mobile_panel(inventory, Rect2(0, 0, 1, 1), 0.86)
	inv_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_label(inventory, "SHOP INVENTORY", Rect2(0.035, 0.02, 0.60, 0.09), 22)
	_mobile_shop_row(inventory, 0, "Basic feeder bugs ×10", 5, "feeder_pack", false)
	_mobile_shop_row(inventory, 1, "Small hand net", 30, "basic_net", bool(GameState.upgrades["basic_net"]))
	_mobile_shop_row(inventory, 2, "Blacklight flashlight", 40, "blacklight", bool(GameState.upgrades["blacklight"]))
	_mobile_shop_row(inventory, 3, "Larger bug container", 35, "larger_bug_jar", bool(GameState.upgrades["larger_bug_jar"]))
	_mobile_shop_row(inventory, 4, "Additional breeding tank", 65, "second_tank", false)
	_mobile_label(inventory, "Buy supplies before going into the wild. The shop closes to you after entering a habitat.", Rect2(0.035, 0.88, 0.93, 0.08), 13)

	var sell := Control.new()
	_set_rect(sell, Rect2(0.60, 0.13, 0.375, 0.82))
	add_child(sell)
	var sell_bg := _mobile_panel(sell, Rect2(0, 0, 1, 1), 0.82)
	sell_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_label(sell, "SELL FROGS", Rect2(0.05, 0.02, 0.90, 0.09), 22)
	var y := 0.14
	var found := false
	for frog in GameState.frogs:
		if frog.get("tank_id", "") != "":
			continue
		found = true
		_mobile_label(sell, "%s  $%d" % [frog["name"], GameState.frog_sale_value(frog)], Rect2(0.05, y, 0.62, 0.10), 14)
		_mobile_button(sell, "SELL", Rect2(0.70, y + 0.01, 0.24, 0.08), Callable(GameState, "sell_frog").bind(int(frog["id"])), 14)
		y += 0.115
		if y > 0.80:
			break
	if not found:
		_mobile_label(sell, "No frogs in the carrying case yet.", Rect2(0.05, 0.18, 0.90, 0.10), 15)
	_mobile_notice()

func _mobile_shop_row(parent: Control, index: int, title: String, price: int, item_id: String, owned: bool) -> void:
	var y := 0.13 + 0.14 * index
	var row := Control.new()
	_set_rect(row, Rect2(0.03, y, 0.94, 0.115))
	parent.add_child(row)
	var row_bg := _mobile_panel(row, Rect2(0, 0, 1, 1), 0.76)
	row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_label(row, "%s   $%d" % [title, price], Rect2(0.035, 0.08, 0.68, 0.84), 15)
	var b := _mobile_button(row, "OWNED" if owned else "BUY", Rect2(0.76, 0.14, 0.20, 0.72), Callable(GameState, "buy").bind(item_id), 14)
	b.disabled = owned

func _render_habitat() -> void:
	_background(GameState.current_habitat, Color("38563b"))
	_ensure_targets()
	var hud := _mobile_hud()
	_mobile_label(hud, "%s • %s" % [_habitat_name(GameState.current_habitat), GameState.time_name()], Rect2(0.28, 0.08, 0.25, 0.84), 17)
	_mobile_label(hud, "%d/3 catches" % GameState.captures_this_period, Rect2(0.53, 0.08, 0.12, 0.84), 15)
	if GameState.upgrades["blacklight"] and GameState.time_index > 0:
		var black := CheckButton.new()
		black.text = "BLACKLIGHT"
		black.button_pressed = GameState.blacklight_on
		black.toggled.connect(_toggle_blacklight)
		black.add_theme_font_size_override("font_size", 13)
		_set_rect(black, Rect2(0.65, 0.10, 0.14, 0.80))
		hud.add_child(black)
	_mobile_button(hud, "SKIP", Rect2(0.80, 0.10, 0.085, 0.80), Callable(GameState, "skip_time"), 14)
	_mobile_button(hud, "HOME", Rect2(0.89, 0.10, 0.095, 0.80), Callable(GameState, "travel_home"), 14)

	var map := Control.new()
	_set_rect(map, Rect2(0.02, 0.12, 0.96, 0.84))
	add_child(map)
	for target in habitat_targets:
		_add_target(map, target)
	if habitat_targets.is_empty():
		_mobile_button(map, "SEARCH AGAIN", Rect2(0.40, 0.42, 0.20, 0.10), _search_again, 16)
	_mobile_notice()

func _mobile_add_decor() -> void:
	var tank := GameState.current_tank()
	for id in ["water_dish", "fern", "bark_cave", "leaf_litter", "rock_cluster", "broadleaf_plant", "bark_bridge", "moss_mound"]:
		if id not in tank["items"]:
			tank["items"].append(id)
			GameState.state_changed.emit()
			return
	notice_text = "All starter décor is already in this tank."
	_render()

func _mobile_notice() -> void:
	if notice_text == "":
		return
	var chip := Control.new()
	_set_rect(chip, Rect2(0.23, 0.925, 0.54, 0.055))
	add_child(chip)
	var chip_bg := _mobile_panel(chip, Rect2(0, 0, 1, 1), 0.94)
	chip_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_label(chip, notice_text, Rect2(0.03, 0.02, 0.94, 0.96), 13, HORIZONTAL_ALIGNMENT_CENTER)
