extends Node

const SAVE_PATH := "user://objective_progress.save"

var signal_bus: Node
var objectives: Dictionary = {
	"mop_floor":      { "label": "Mop the floor",         "complete": false, "progress": 0.0, "target": 15, "key": "E" },
	"restock_shelves":{ "label": "Restock shelves",        "complete": false, "progress": 0.0, "target": 10, "key": "F" },
	"take_out_trash": { "label": "Take out the trash",     "complete": false, "progress": 0.0, "target": 12, "key": "Q" },
	"count_register": { "label": "Count the register",     "complete": false, "progress": 0.0, "target": 8,  "key": "R" },
	"turn_off_lights":{ "label": "Turn off aisle lights",  "complete": false, "progress": 0.0, "target": 6,  "key": "T" },
	"clean_windows":  { "label": "Clean the windows",      "complete": false, "progress": 0.0, "target": 15, "key": "Y" },
}

func _ready():
	signal_bus = get_node("/root/SignalBus")
	load_progress()
	signal_bus.player_died.connect(_on_player_died)

func add_progress(id: String, amount: float) -> void:
	if not objectives.has(id):
		return
	var objective = objectives[id]
	if objective["complete"]:
		return
	objective["progress"] = clamp(objective["progress"] + amount, 0.0, float(objective["target"]))
	if objective["progress"] >= float(objective["target"]):
		objective["progress"] = float(objective["target"])
		objective["complete"] = true
		signal_bus.objective_completed.emit(id)
		if all_complete():
			signal_bus.all_objectives_completed.emit()
	else:
		signal_bus.interact_progress.emit(objective["progress"] / float(objective["target"]))
	save_progress()

func set_progress(id: String, amount: float) -> void:
	if not objectives.has(id):
		return
	var objective = objectives[id]
	objective["progress"] = clamp(amount, 0.0, float(objective["target"]))
	if objective["progress"] >= float(objective["target"]):
		objective["progress"] = float(objective["target"])
		objective["complete"] = true
		signal_bus.objective_completed.emit(id)
		if all_complete():
			signal_bus.all_objectives_completed.emit()
	else:
		signal_bus.interact_progress.emit(objective["progress"] / float(objective["target"]))
	save_progress()

func get_progress(id: String) -> float:
	if objectives.has(id):
		return objectives[id]["progress"]
	return 0.0

func all_complete() -> bool:
	for key in objectives:
		if not objectives[key]["complete"]:
			return false
	return true

func reset():
	for key in objectives:
		objectives[key]["complete"] = false
		objectives[key]["progress"] = 0.0
	save_progress()

func _on_player_died() -> void:
	reset()

func save_progress() -> void:
	var save_data: Dictionary = {}
	for key in objectives:
		var objective = objectives[key]
		save_data[key] = {
			"progress": objective["progress"],
			"complete": objective["complete"]
		}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_var(save_data)
		file.close()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var save_data = file.get_var()
	file.close()
	if save_data is Dictionary:
		for key in save_data:
			if objectives.has(key):
				var data = save_data[key]
				if data is Dictionary:
					objectives[key]["progress"] = float(data.get("progress", 0.0))
					objectives[key]["complete"] = bool(data.get("complete", false))
