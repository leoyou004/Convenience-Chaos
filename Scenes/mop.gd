extends Area3D

@export var objective_id: String = "mop_floor"
@export var prompt_text: String = "Hold the shown key"
@export var key_to_press: String = "E"
@export var progress_per_press: float = 1.0
@export var required_progress: int = 15

var _player_inside: bool = false
var _player: Node3D = null

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("Player")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_process(true)

func _process(delta: float) -> void:
	if not _player_inside:
		return
	if Input.is_action_pressed("interact") and ObjectiveManager.objectives.has(objective_id):
		ObjectiveManager.add_progress(objective_id, progress_per_press * delta)
		var ratio: float = ObjectiveManager.get_progress(objective_id) / float(ObjectiveManager.objectives[objective_id]["target"])
		SignalBus.interact_progress.emit(ratio)
		SignalBus.mop_progress.emit(ratio)
		if ObjectiveManager.objectives[objective_id]["complete"]:
			_complete()

func _complete() -> void:
	set_process(false)
	SignalBus.interactable_unfocused.emit()
	SignalBus.mop_finished.emit()
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body == _player:
		_player_inside = true
		SignalBus.interactable_focused.emit(objective_id, 0.0)

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player_inside = false
		SignalBus.interactable_unfocused.emit()
