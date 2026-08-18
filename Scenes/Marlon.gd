extends Sprite2D

@export_category("Blink Settings")
@export var min_time_hidden: float = 1.5
@export var max_time_hidden: float = 4.0
@export var min_time_visible: float = 0.05
@export var max_time_visible: float = 0.15

@export_category("Rapid Flash Settings")
@export var flash_chance: float = 0.3        # 30% chance to trigger a rapid flash sequence
@export var min_flash_duration: float = 0.5  # How long the rapid flashing lasts
@export var max_flash_duration: float = 1.5

var timer: float = 0.0
var target_time: float = 0.0
var is_flashing_sequence: bool = false

func _ready() -> void:
	visible = false
	_reset_normal_timer()

func _process(delta: float) -> void:
	timer += delta
	
	if timer >= target_time:
		timer = 0.0
		
		if is_flashing_sequence:
			# During a rapid flash sequence, just rapidly toggle visibility
			visible = !visible
			
			# Check if the flash sequence duration is up
			if not visible and randf() < 0.2: # Randomly exit the flash loop
				is_flashing_sequence = false
				_reset_normal_timer()
		else:
			visible = !visible
			
			if visible:
				# Check if we should start a rapid flashing sequence instead of staying normally visible
				if randf() < flash_chance:
					is_flashing_sequence = true
					target_time = randf_range(min_flash_duration, max_flash_duration)
				else:
					target_time = randf_range(min_time_visible, max_time_visible)
			else:
				_reset_normal_timer()

func _reset_normal_timer() -> void:
	is_flashing_sequence = false
	visible = false
	target_time = randf_range(min_time_hidden, max_time_hidden)
