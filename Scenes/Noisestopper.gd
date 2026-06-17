extends Area3D

@export var ambience_player: AudioStreamPlayer3D  # drag the ambience node here in the Inspector

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and ambience_player:
		ambience_player.stop_ambience()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and ambience_player:
		ambience_player.resume_ambience()
