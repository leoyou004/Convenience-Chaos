extends Node

signal objectives_reset
var signal_bus: Node
var has_won: bool = false
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
	reset()
	signal_bus.player_died.connect(_on_player_died)
	signal_bus.all_objectives_completed.connect(_on_all_objectives_completed)

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
	has_won = false
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists("objective_progress.save"):
		dir.remove("objective_progress.save")
	objectives_reset.emit()

func _on_player_died() -> void:
	reset()

func _on_all_objectives_completed() -> void:
	if has_won:
		return
	has_won = true
	reset()
	call_deferred("_show_end_scene")

func _show_end_scene() -> void:
	get_tree().change_scene_to_file("res://end_scene.tscn")
