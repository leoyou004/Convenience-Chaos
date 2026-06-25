extends Node3D

@export var buried_offset: float = -0.1
@export var raised_position: Vector3 = Vector3.ZERO

var _start_position: Vector3
var _current_progress: float = 0.0
var _locked: bool = false

func _ready() -> void:
	raised_position = global_position
	_start_position = global_position + Vector3(0, buried_offset, 0)
	global_position = _start_position
	SignalBus.restock_progress.connect(_on_restock_progress)

func _on_restock_progress(amount: float) -> void:
	if _locked:
		return
	_current_progress = amount
	global_position = _start_position.lerp(raised_position, _current_progress)
	if amount <= 0.0:
		global_position = _start_position
	if amount >= 1.0:
		global_position = raised_position
		_locked = true
		SignalBus.restock_progress.disconnect(_on_restock_progress)
