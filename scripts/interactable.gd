extends Area3D

@export var objective_id: String = "count_register"
@export var hold_time: float = 10.0
@export var prompt_text: String = "Hold E to interact"

var _progress: float = 0.0
var _player_inside: bool = false
var _player: Node3D = null

func _ready() -> void:
	set_process(true)
	_player = get_tree().get_first_node_in_group("Player")
	print("INTERACTABLE READY - layer: ", collision_layer, " mask: ", collision_mask, " monitoring: ", monitoring, " id: ", objective_id)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if not _player_inside:
		return
	if Input.is_action_pressed("interact"):
		_progress += delta
		SignalBus.interact_progress.emit(_progress / hold_time)
		if _progress >= hold_time:
			_complete()
	else:
		_progress = 0.0
		SignalBus.interact_progress.emit(0.0)

func _complete() -> void:
	set_process(false)
	SignalBus.interactable_unfocused.emit()
	ObjectiveManager.complete_objective(objective_id)
	queue_free()

func _on_body_entered(body: Node) -> void:
	print("INTERACTABLE BODY ENTERED: ", body.name)
	if body == _player:
		_player_inside = true
		SignalBus.interactable_focused.emit(objective_id, hold_time)

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player_inside = false
		_progress = 0.0
		SignalBus.interactable_unfocused.emit()
		SignalBus.interact_progress.emit(0.0)

func _on_area_entered(_area: Area3D) -> void:
	pass

func _on_area_exited(_area: Area3D) -> void:
	pass
