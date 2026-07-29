extends ProgressBar

func _ready() -> void:
	min_value = 0.0
	max_value = 1.0
	value = 1.0
	modulate.a = 0.7
	SignalBus.sprint_stamina_changed.connect(_on_sprint_stamina_changed)
	_on_sprint_stamina_changed(1.0, 1.0)

func _on_sprint_stamina_changed(current_stamina: float, max_stamina: float) -> void:
	var normalized_stamina = clamp(current_stamina / max_stamina if max_stamina > 0 else 0.0, 0.0, 1.0)
	value = normalized_stamina
	if normalized_stamina <= 0.2:
		modulate = Color.RED
	elif normalized_stamina <= 0.5:
		modulate = Color.YELLOW
	else:
		modulate = Color.GREEN
