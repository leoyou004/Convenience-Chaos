extends Area3D

@export var objective_id: String = "mop_floor"
@export var prompt_text: String = "Move mouse in circles to mop"
@export var circles_required: int = 3
@export var circle_radius_threshold: float = 40.0

var _player_inside: bool = false
var _is_mopping: bool = false
var _progress: float = 0.0

# Circle detection
var _mouse_positions: Array = []
var _sample_count: int = 40
var _last_angle: float = 0.0
var _total_rotation: float = 0.0
var _circles_completed: float = 0.0

func _ready() -> void:
	set_process(true)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if not _player_inside:
		return
	if Input.is_action_pressed("interact"):
		if not _is_mopping:
			_start_mopping()
		_track_circle()
	else:
		if _is_mopping:
			_stop_mopping()

func _start_mopping() -> void:
	_is_mopping = true
	_mouse_positions.clear()
	_total_rotation = 0.0
	_circles_completed = 0.0
	_progress = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	SignalBus.mop_started.emit()

func _stop_mopping() -> void:
	_is_mopping = false
	_progress = 0.0
	_circles_completed = 0.0
	_total_rotation = 0.0
	_mouse_positions.clear()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SignalBus.mop_progress.emit(0.0)

func _track_circle() -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	_mouse_positions.append(mouse_pos)

	# Keep only recent samples
	if _mouse_positions.size() > _sample_count:
		_mouse_positions.pop_front()

	if _mouse_positions.size() < _sample_count:
		return

	# Find center of the mouse path
	var center: Vector2 = Vector2.ZERO
	for pos in _mouse_positions:
		center += pos
	center /= _mouse_positions.size()

	# Check radius is big enough to count as a circle
	var avg_radius: float = 0.0
	for pos in _mouse_positions:
		avg_radius += pos.distance_to(center)
	avg_radius /= _mouse_positions.size()

	if avg_radius < circle_radius_threshold:
		return

	# Measure total angular movement
	var new_angle: float = (mouse_pos - center).angle()
	var angle_diff: float = new_angle - _last_angle

	# Wrap angle difference to [-PI, PI]
	while angle_diff > PI:
		angle_diff -= TAU
	while angle_diff < -PI:
		angle_diff += TAU

	_total_rotation += angle_diff
	_last_angle = new_angle

	# Each full circle = TAU radians
	_circles_completed = abs(_total_rotation) / TAU
	_progress = _circles_completed / circles_required

	SignalBus.mop_progress.emit(_progress)

	if _circles_completed >= circles_required:
		_complete()

func _complete() -> void:
	set_process(false)
	_is_mopping = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SignalBus.mop_finished.emit()
	ObjectiveManager.complete_objective(objective_id)
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		SignalBus.interactable_focused.emit(objective_id, 0.0)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		if _is_mopping:
			_stop_mopping()
		SignalBus.interactable_unfocused.emit()
