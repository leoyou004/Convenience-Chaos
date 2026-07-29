extends CanvasLayer

var qte_overlay: Control

func _ready() -> void:
	qte_overlay = Control.new()
	qte_overlay.name = "QTEOverlay"
	qte_overlay.set_script(load("res://scripts/qte_overlay.gd"))
	add_child(qte_overlay)
	qte_overlay.visible = false
	SignalBus.interactable_focused.connect(_on_interactable_focused)
	SignalBus.interactable_unfocused.connect(_on_interactable_unfocused)
	SignalBus.interact_progress.connect(_on_interact_progress)

func _on_interactable_focused(objective_id: String, _hold_time: float) -> void:
	var key = "E"
	if ObjectiveManager.objectives.has(objective_id):
		key = ObjectiveManager.objectives[objective_id]["key"]
	qte_overlay.set_state(true, key, 1.0)

func _on_interactable_unfocused() -> void:
	qte_overlay.set_state(false, "E", 0.0)

func _on_interact_progress(progress: float) -> void:
	qte_overlay.set_state(true, qte_overlay.key_text, progress)
