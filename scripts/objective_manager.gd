extends Node

signal objective_completed(index: int)
signal all_objectives_completed

var objectives: Array = [
	{"name": "Take out trash", "completed": false},
	{"name": "Stock shelves", "completed": false},
	{"name": "Mop floor", "completed": false},
	{"name": "Clean windows", "completed": false},
	{"name": "Restock fridge", "completed": false},
	{"name": "Sort mail", "completed": false},
]

func complete_objective(index: int) -> void:
	if index < 0 or index >= objectives.size():
		return
	if objectives[index]["completed"]:
		return
	objectives[index]["completed"] = true
	objective_completed.emit(index)
	if objectives.all(func(o): return o["completed"]):
		all_objectives_completed.emit()
