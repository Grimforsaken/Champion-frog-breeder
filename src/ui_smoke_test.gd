extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
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
	var home_buttons := _count_type(main, "Button")
	print("UI_SMOKE home_buttons=%d" % home_buttons)
	if home_buttons < 4:
		_fail("Home UI did not create enough interactive buttons")
		return

	gs.travel_shop()
	await process_frame
	await process_frame
	var shop_buttons := _count_type(main, "Button")
	print("UI_SMOKE shop_buttons=%d" % shop_buttons)
	if shop_buttons < 7:
		_fail("Shop inventory UI is missing")
		return

	gs.travel_home()
	await process_frame
	gs.travel_habitat("backyard_puddle")
	await process_frame
	await process_frame
	var habitat_buttons := _count_type(main, "Button")
	print("UI_SMOKE habitat_buttons=%d" % habitat_buttons)
	if habitat_buttons < 6:
		_fail("Habitat capture targets are missing")
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

func _fail(message: String) -> void:
	push_error("UI_SMOKE_FAIL: %s" % message)
	quit(1)
