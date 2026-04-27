extends ProgressBar

func _ready() -> void:
	# Initialize progress bar
	min_value = 0.0
	max_value = 1.0
	value = 1.0  # Start fully charged
	modulate.a = 0.7  # Semi-transparent
	
	# Connect to sprint stamina signal
	SignalBus.sprint_stamina_changed.connect(_on_sprint_stamina_changed)

func _on_sprint_stamina_changed(current_stamina: float, max_stamina: float) -> void:
	# Update progress bar
	var normalized_stamina = current_stamina / max_stamina if max_stamina > 0 else 0.0
	value = normalized_stamina
	
	# Change color based on stamina level
	if normalized_stamina <= 0.2:
		modulate = Color.RED  # Red when low
	elif normalized_stamina <= 0.5:
		modulate = Color.YELLOW  # Yellow when medium
	else:
		modulate = Color.GREEN  # Green when good
