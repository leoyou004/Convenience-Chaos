extends VBoxContainer

var _focused_id: String = ""
var _progress: float = 0.0
var _active_key: String = "E"

func _ready() -> void:
	SignalBus.objective_completed.connect(_on_objective_completed)
	SignalBus.all_objectives_completed.connect(_on_all_completed)
	SignalBus.interactable_focused.connect(_on_interactable_focused)
	SignalBus.interactable_unfocused.connect(_on_interactable_unfocused)
	SignalBus.interact_progress.connect(_on_interact_progress)
	_update_ui()

func _update_ui() -> void:
	var labels = get_children()
	var keys = ObjectiveManager.objectives.keys()
	for i in range(labels.size()):
		if i < keys.size():
			var key = keys[i]
			var obj = ObjectiveManager.objectives[key]
			var label = labels[i] as Label
			if label == null:
				continue
			var pct = int((obj["progress"] / float(obj["target"])) * 100)
			if obj["complete"]:
				label.text = "✓ " + obj["label"] + " (Done)"
				label.modulate = Color(0, 1, 0)
			elif key == _focused_id:
				label.text = "⟳ " + obj["label"] + " [Hold " + obj["key"] + "] " + str(pct) + "%"
				label.modulate = Color(1, 1, 0)
			else:
				label.text = "• " + obj["label"] + " " + str(int(obj["progress"])) + "/" + str(obj["target"])
				label.modulate = Color(1, 1, 1)

func _on_interactable_focused(objective_id: String, _hold_time: float) -> void:
	_focused_id = objective_id
	_active_key = ObjectiveManager.objectives[objective_id]["key"]
	_update_ui()

func _on_interactable_unfocused() -> void:
	_focused_id = ""
	_progress = 0.0
	_update_ui()

func _on_interact_progress(progress: float) -> void:
	_progress = progress
	_update_ui()

func _on_objective_completed(_id: String) -> void:
	_focused_id = ""
	_progress = 0.0
	_update_ui()

func _on_all_completed() -> void:
	_update_ui()
