extends Area3D

@export var objective_id: String = "count_register"
@export var prompt_text: String = "Press the shown key"
@export var key_to_press: String = "E"
@export var progress_per_press: float = 1.0
@export var required_progress: int = 8

var _player_inside: bool = false
var _player: Node3D = null
var _pressed_this_cycle: bool = false
var _last_press_time: float = 0.0

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("Player")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_process(true)

func _process(delta: float) -> void:
	if not _player_inside:
		return
	if Input.is_action_just_pressed("interact"):
		_last_press_time = Time.get_ticks_msec() / 1000.0
		_pressed_this_cycle = true
		if ObjectiveManager.objectives.has(objective_id):
			ObjectiveManager.add_progress(objective_id, progress_per_press)
			SignalBus.interact_progress.emit(ObjectiveManager.get_progress(objective_id) / float(ObjectiveManager.objectives[objective_id]["target"]))
			if ObjectiveManager.objectives[objective_id]["complete"]:
				_complete()
	elif _pressed_this_cycle:
		_pressed_this_cycle = false

func _complete() -> void:
	set_process(false)
	SignalBus.interactable_unfocused.emit()
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body == _player:
		_player_inside = true
		SignalBus.interactable_focused.emit(objective_id, 0.0)

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player_inside = false
		SignalBus.interactable_unfocused.emit()
		SignalBus.interact_progress.emit(0.0)
