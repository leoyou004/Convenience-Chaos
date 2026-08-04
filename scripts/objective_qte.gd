extends CanvasLayer

var qte_overlay: Control

func _ready() -> void:
	# QTE overlay disabled - removed annoying circle display
	SignalBus.interactable_focused.connect(_on_interactable_focused)
	SignalBus.interactable_unfocused.connect(_on_interactable_unfocused)
	SignalBus.interact_progress.connect(_on_interact_progress)

func _on_interactable_focused(objective_id: String, _hold_time: float) -> void:
	# QTE overlay display disabled
	pass

func _on_interactable_unfocused() -> void:
	# QTE overlay display disabled
	pass

func _on_interact_progress(progress: float) -> void:
	# QTE overlay display disabled
	pass
