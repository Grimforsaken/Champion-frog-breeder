extends Node

signal state_changed
signal notice(text: String)

const TIME_NAMES := ["Day", "Evening", "Night"]
const CASE_CAPACITY := 6

var day := 1
var cash := 40
var feeder_food := 6
var current_screen := "home"
var current_habitat := ""
var time_index := 0
var captures_this_period := 0
var at_habitat := false
var shop_locked_for_day := false
var blacklight_on := false

var unlocked_habitats: Array[String] = ["backyard_puddle"]
var upgrades := {
	"basic_net": false,
	"blacklight": false,
	"larger_bug_jar": false
}

var bug_inventory := {
	"worm": 0,
	"cricket": 0,
	"mosquito": 0,
	"water_beetle": 0
}

var frogs: Array[Dictionary] = []
var nursery: Array[Dictionary] = []
var tanks: Array[Dictionary] = [
	{
		"id": "tank_1",
		"name": "Starter Tank",
		"capacity": 2,
		"frog_ids": [],
		"background": "rock_moss",
		"items": ["water_dish", "fern", "bark_hide", "leaf_litter", "rock_cluster"]
	}
]
var selected_tank := 0

var stats := {
	"frogs_caught": 0,
	"bugs_caught": 0,
	"frogs_sold": 0,
	"frogs_bred": 0,
	"contests_entered": 0
}

var _next_frog_id := 1

func _ready() -> void:
	randomize()

func time_name() -> String:
	return TIME_NAMES[time_index]

func current_tank() -> Dictionary:
	return tanks[selected_tank]

func upkeep_complete() -> bool:
	for frog in frogs:
		if frog.get("stage", "adult") != "egg" and not frog.get("fed_today", false):
			return false
	return true

func case_count() -> int:
	var count := 0
	for frog in frogs:
		if frog.get("tank_id", "") == "":
			count += 1
	return count

func feed_frog(frog_id: int) -> bool:
	var frog := get_frog(frog_id)
	if frog.is_empty() or frog.get("fed_today", false):
		return false
	if feeder_food > 0:
		feeder_food -= 1
		frog["fed_today"] = true
		state_changed.emit()
		return true
	for bug_name in bug_inventory.keys():
		if bug_inventory[bug_name] > 0:
			bug_inventory[bug_name] -= 1
			frog["fed_today"] = true
			frog["last_food"] = bug_name
			state_changed.emit()
			return true
	notice.emit("No food available. Visit the pet shop for basic feeder bugs.")
	return false

func feed_all() -> void:
	for frog in frogs:
		if not frog.get("fed_today", false):
			if not feed_frog(frog["id"]):
				break

func get_frog(frog_id: int) -> Dictionary:
	for frog in frogs:
		if frog["id"] == frog_id:
			return frog
	return {}

func travel_home() -> void:
	if at_habitat:
		end_day()
		return
	current_screen = "home"
	state_changed.emit()

func travel_shop() -> bool:
	if at_habitat or shop_locked_for_day:
		notice.emit("The pet shop is no longer available after leaving for a habitat.")
		return false
	current_screen = "shop"
	state_changed.emit()
	return true

func travel_habitat(habitat_id: String) -> bool:
	if habitat_id not in unlocked_habitats:
		return false
	if not upkeep_complete():
		notice.emit("Finish today's frog upkeep before leaving for the habitat.")
		return false
	current_habitat = habitat_id
	current_screen = "habitat"
	at_habitat = true
	shop_locked_for_day = true
	time_index = 0
	captures_this_period = 0
	blacklight_on = false
	state_changed.emit()
	return true

func record_bug_capture(bug_name: String, fluorescent := false) -> void:
	bug_inventory[bug_name] = bug_inventory.get(bug_name, 0) + 1
	stats["bugs_caught"] += 1
	if fluorescent:
		notice.emit("Rare fluorescent %s captured." % bug_name.replace("_", " ").capitalize())
	_capture_succeeded()

func record_frog_capture(species: String, fluorescent := false) -> bool:
	if case_count() >= CASE_CAPACITY:
		notice.emit("The 6-frog carrying case is full.")
		return false
	var frog := _make_adult_frog(species, fluorescent)
	frogs.append(frog)
	stats["frogs_caught"] += 1
	_capture_succeeded()
	return true

func _capture_succeeded() -> void:
	captures_this_period += 1
	if captures_this_period >= 3:
		advance_time()
	else:
		state_changed.emit()

func advance_time() -> void:
	captures_this_period = 0
	blacklight_on = false
	if time_index < TIME_NAMES.size() - 1:
		time_index += 1
		state_changed.emit()
	else:
		end_day()

func skip_time() -> void:
	advance_time()

func end_day() -> void:
	# Growth happens once per completed field day.
	for frog in frogs:
		if not frog.get("fed_today", false):
			frog["condition"] = max(0, frog.get("condition", 100) - 5)
		frog["fed_today"] = false
	_grow_nursery()
	day += 1
	current_screen = "home"
	current_habitat = ""
	at_habitat = false
	shop_locked_for_day = false
	time_index = 0
	captures_this_period = 0
	blacklight_on = false
	check_unlocks()
	notice.emit("Day %d begins. Frog upkeep comes first." % day)
	state_changed.emit()

func buy(item_id: String) -> bool:
	var catalog := {
		"feeder_pack": 5,
		"basic_net": 30,
		"blacklight": 40,
		"second_tank": 65,
		"larger_bug_jar": 35
	}
	if not catalog.has(item_id):
		return false
	var price: int = catalog[item_id]
	if cash < price:
		notice.emit("Not enough money.")
		return false
	if item_id in upgrades and upgrades[item_id]:
		return false
	cash -= price
	match item_id:
		"feeder_pack":
			feeder_food += 10
		"basic_net", "blacklight", "larger_bug_jar":
			upgrades[item_id] = true
		"second_tank":
			var id := "tank_%d" % (tanks.size() + 1)
			tanks.append({"id": id, "name": "Breeding Tank %d" % tanks.size(), "capacity": 2, "frog_ids": [], "background": "rock_moss", "items": ["water_dish"]})
	state_changed.emit()
	return true

func sell_frog(frog_id: int) -> bool:
	for i in range(frogs.size()):
		if frogs[i]["id"] != frog_id:
			continue
		if frogs[i].get("tank_id", "") != "":
			notice.emit("Move the frog out of its tank before selling it.")
			return false
		var value := frog_sale_value(frogs[i])
		cash += value
		frogs.remove_at(i)
		stats["frogs_sold"] += 1
		check_unlocks()
		state_changed.emit()
		return true
	return false

func frog_sale_value(frog: Dictionary) -> int:
	var value := 12 if frog.get("species") == "regular_frog" else 24
	if frog.get("fluorescent", false):
		value += 20
	value += int(frog.get("condition", 100) / 25)
	return value

func move_frog_to_tank(frog_id: int, tank_index: int) -> bool:
	if tank_index < 0 or tank_index >= tanks.size():
		return false
	var frog := get_frog(frog_id)
	if frog.is_empty():
		return false
	var destination: Dictionary = tanks[tank_index]
	if destination["frog_ids"].size() >= destination["capacity"]:
		notice.emit("That tank is full.")
		return false
	var old_tank_id: String = frog.get("tank_id", "")
	if old_tank_id != "":
		for tank in tanks:
			if tank["id"] == old_tank_id:
				tank["frog_ids"].erase(frog_id)
	destination["frog_ids"].append(frog_id)
	frog["tank_id"] = destination["id"]
	state_changed.emit()
	return true

func move_frog_to_case(frog_id: int) -> bool:
	if case_count() >= CASE_CAPACITY:
		return false
	var frog := get_frog(frog_id)
	if frog.is_empty():
		return false
	var old_tank_id: String = frog.get("tank_id", "")
	for tank in tanks:
		if tank["id"] == old_tank_id:
			tank["frog_ids"].erase(frog_id)
	frog["tank_id"] = ""
	state_changed.emit()
	return true

func breed_selected_tank() -> bool:
	var tank := current_tank()
	if tank["frog_ids"].size() != 2:
		notice.emit("A breeding tank needs exactly two adult frogs.")
		return false
	var a := get_frog(tank["frog_ids"][0])
	var b := get_frog(tank["frog_ids"][1])
	if a.is_empty() or b.is_empty() or a["stage"] != "adult" or b["stage"] != "adult":
		return false
	if a["sex"] == b["sex"]:
		notice.emit("This pair cannot breed together.")
		return false
	if a.get("last_bred_day", 0) == day or b.get("last_bred_day", 0) == day:
		notice.emit("This pair has already bred today.")
		return false
	var clutch_size := randi_range(3, 6)
	for n in clutch_size:
		nursery.append(_make_offspring(a, b))
	a["last_bred_day"] = day
	b["last_bred_day"] = day
	stats["frogs_bred"] += clutch_size
	notice.emit("A clutch of %d eggs was moved to the nursery." % clutch_size)
	check_unlocks()
	state_changed.emit()
	return true

func _make_adult_frog(species: String, fluorescent: bool) -> Dictionary:
	var id := _next_frog_id
	_next_frog_id += 1
	return {
		"id": id,
		"name": "%s #%d" % [species.replace("_", " ").capitalize(), id],
		"species": species,
		"sex": "Male" if randf() < 0.5 else "Female",
		"hue": randi_range(70, 150) if species == "regular_frog" else randi_range(65, 125),
		"fluorescent": fluorescent,
		"stage": "adult",
		"age_days": 20,
		"fed_today": false,
		"condition": 100,
		"tank_id": ""
	}

func _make_offspring(a: Dictionary, b: Dictionary) -> Dictionary:
	return {
		"species": a["species"] if randf() < 0.5 else b["species"],
		"hue": inherited_hue(a["hue"], b["hue"]),
		"fluorescent": (a.get("fluorescent", false) or b.get("fluorescent", false)) and randf() < 0.35,
		"stage": "egg",
		"age_days": 0
	}

func inherited_hue(a: int, b: int) -> int:
	var delta := ((b - a + 540) % 360) - 180
	var step := randi_range(0, abs(delta))
	if delta < 0:
		step = -step
	return (a + step + 360) % 360

func _grow_nursery() -> void:
	var matured: Array[int] = []
	for i in range(nursery.size()):
		var baby := nursery[i]
		baby["age_days"] += 1
		var age: int = baby["age_days"]
		if age <= 1:
			baby["stage"] = "egg"
		elif age <= 3:
			baby["stage"] = "tadpole"
		elif age <= 5:
			baby["stage"] = "froglet"
		elif age <= 7:
			baby["stage"] = "juvenile"
		else:
			matured.append(i)
	for i in range(matured.size() - 1, -1, -1):
		var baby := nursery[matured[i]]
		var id := _next_frog_id
		_next_frog_id += 1
		frogs.append({
			"id": id,
			"name": "Homebred Frog #%d" % id,
			"species": baby["species"],
			"sex": "Male" if randf() < 0.5 else "Female",
			"hue": baby["hue"],
			"fluorescent": baby.get("fluorescent", false),
			"stage": "adult",
			"age_days": 8,
			"fed_today": false,
			"condition": 100,
			"tank_id": ""
		})
		nursery.remove_at(matured[i])

func check_unlocks() -> void:
	if "pond" not in unlocked_habitats and (stats["frogs_sold"] >= 2 or stats["frogs_bred"] >= 3):
		unlocked_habitats.append("pond")
		notice.emit("The shopkeeper tells you about a nearby pond. Pond habitat unlocked!")
