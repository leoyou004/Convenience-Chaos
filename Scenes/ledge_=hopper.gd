extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.velocity.y = 3.5
	elif body.has_method("apply_ledge_boost"):
		body.apply_ledge_boost()
