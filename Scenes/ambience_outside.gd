extends AudioStreamPlayer3D

func _ready() -> void:
	play()

func stop_ambience() -> void:
	stop()

func resume_ambience() -> void:
	if not playing:
		play()
