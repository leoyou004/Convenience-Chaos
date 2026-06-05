extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		$"Door Bell".play()
		SignalBus.distraction_thrown.emit(global_position)
