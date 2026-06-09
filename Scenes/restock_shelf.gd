extends Area3D

@export var objective_id: String = "restock_shelves"
@export var hold_time: float = 10.0
@export var prompt_text: String = "Hold E to restock"
@export var food_item: NodePath

var _progress: float = 0.0
var _player_inside: bool = false

func _ready() -> void:
	set_process(true)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if not _player_inside:
		return
	if Input.is_action_pressed("interact"):
		_progress += delta
		var ratio: float = _progress / hold_time
		SignalBus.interact_progress.emit(ratio)
		SignalBus.restock_progress.emit(ratio)
		if _progress >= hold_time:
			_complete()
	else:
		_progress = 0.0
		SignalBus.interact_progress.emit(0.0)
		SignalBus.restock_progress.emit(0.0)

func _complete() -> void:
	set_process(false)
	SignalBus.interactable_unfocused.emit()
	SignalBus.restock_progress.emit(1.0)
	ObjectiveManager.complete_objective(objective_id)
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		SignalBus.interactable_focused.emit(objective_id, hold_time)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		_progress = 0.0
		SignalBus.interact_progress.emit(0.0)
		SignalBus.restock_progress.emit(0.0)
		SignalBus.interactable_unfocused.emit()
