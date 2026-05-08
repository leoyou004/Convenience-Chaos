extends Node

var signal_bus: Node
var objectives: Dictionary = {
	"mop_floor":      { "label": "Mop the floor",         "complete": false },
	"restock_shelves":{ "label": "Restock shelves",        "complete": false },
	"take_out_trash": { "label": "Take out the trash",     "complete": false },
	"count_register": { "label": "Count the register",     "complete": false },
	"turn_off_lights":{ "label": "Turn off aisle lights",  "complete": false },
	"clean_windows":  { "label": "Clean the windows",      "complete": false },
}

func _ready():
	signal_bus = get_node("/root/SignalBus")

func complete_objective(id: String):
	if objectives.has(id) and not objectives[id]["complete"]:
		objectives[id]["complete"] = true
		signal_bus.objective_completed.emit(id)
		if all_complete():
			signal_bus.all_objectives_completed.emit()

func all_complete() -> bool:
	for key in objectives:
		if not objectives[key]["complete"]:
			return false
	return true

func reset():
	for key in objectives:
		objectives[key]["complete"] = false
