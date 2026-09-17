extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	root.size = Vector2i(1536, 709)
	var gs := root.get_node_or_null("GameState")
	if gs == null:
		_fail("GameState autoload missing")
		return
	var packed := load("res://src/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene failed to load")
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame

	var home_buttons := _count_type(main, "Button")
	print("UI_SMOKE home_buttons=%d" % home_buttons)
	if home_buttons < 4:
		_fail("Home UI did not create enough interactive buttons")
		return
	if not _label_has_width(main, "DAY ", 90.0):
		_fail("Top status label collapsed on 1536x709 mobile layout")
		return
	if not _label_has_width(main, "MORNING FROG UPKEEP", 300.0):
		_fail("Upkeep label collapsed on 1536x709 mobile layout")
		return

	gs.travel_shop()
	await process_frame
	await process_frame
	await process_frame
	var shop_buttons := _count_type(main, "Button")
	print("UI_SMOKE shop_buttons=%d" % shop_buttons)
	if shop_buttons < 7:
		_fail("Shop inventory UI is missing")
		return
	if not _label_has_width(main, "SHOP INVENTORY", 180.0):
		_fail("Shop inventory heading collapsed")
		return
	if not _label_has_width(main, "Basic feeder bugs", 400.0):
		_fail("Shop inventory rows collapsed")
		return

	gs.travel_home()
	await process_frame
	gs.travel_habitat("backyard_puddle")
	await process_frame
	await process_frame
	await process_frame
	var habitat_buttons := _count_type(main, "Button")
	print("UI_SMOKE habitat_buttons=%d" % habitat_buttons)
	if habitat_buttons < 6:
		_fail("Habitat capture targets are missing")
		return
	if not _label_has_width(main, "Backyard Puddle", 260.0):
		_fail("Habitat status label collapsed")
		return
	print("UI_SMOKE PASS")
	quit(0)

func _count_type(node: Node, class_name_text: String) -> int:
	var total := 0
	if node.is_class(class_name_text):
		total += 1
	for child in node.get_children():
		total += _count_type(child, class_name_text)
	return total

func _label_has_width(node: Node, prefix: String, minimum_width: float) -> bool:
	if node is Label:
		var label := node as Label
		if label.text.begins_with(prefix):
			print("UI_SMOKE label '%s' width=%.1f" % [prefix, label.size.x])
			return label.size.x >= minimum_width
	for child in node.get_children():
		if _label_has_width(child, prefix, minimum_width):
			return true
	return false

func _fail(message: String) -> void:
	push_error("UI_SMOKE_FAIL: %s" % message)
	quit(1)
