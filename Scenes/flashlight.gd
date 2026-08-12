extends SpotLight3D

# --- Inspector Variables ---
@export_category("Flashlight Settings")
@export var base_energy: float = 5.0
@export var flicker_min_energy: float = 0.5

@export_category("Glitch Timings")
## Minimum time (in seconds) the flashlight works perfectly before glitching
@export var min_time_between_glitches: float = 4.0
## Maximum time (in seconds) the flashlight works perfectly before glitching
@export var max_time_between_glitches: float = 12.0
## How long a flickering/blackout episode lasts at maximum
@export var max_glitch_duration: float = 1.5

@export_category("Glitch Probabilities")
## Chance (0.0 to 1.0) that a glitch will completely turn the light off instead of flickering
@export var chance_to_turn_off: float = 0.25 

# --- Internal Variables ---
var _next_glitch_timer: float = 0.0
var _current_glitch_timer: float = 0.0
var _is_glitching: bool = false
var _is_completely_off: bool = false

func _ready() -> void:
	light_energy = base_energy
	_reset_glitch_timer()

func _process(delta: float) -> void:
	if not _is_glitching:
		# Count down to the next glitch
		_next_glitch_timer -= delta
		if _next_glitch_timer <= 0.0:
			_start_glitch()
	else:
		# Count down to end the current glitch
		_current_glitch_timer -= delta
		if _current_glitch_timer <= 0.0:
			_end_glitch()
		elif not _is_completely_off:
			# Apply the flickering effect by rapidly randomizing the energy
			# Using randf() > 0.3 means it will be at base energy 30% of the time during a flicker
			if randf() > 0.3:
				light_energy = randf_range(flicker_min_energy, base_energy * 0.8)
			else:
				light_energy = base_energy

func _start_glitch() -> void:
	_is_glitching = true
	# Randomize how long this specific glitch will last
	_current_glitch_timer = randf_range(0.2, max_glitch_duration)
	
	# Decide if this glitch is a flicker or a complete blackout
	if randf() <= chance_to_turn_off:
		_is_completely_off = true
		light_energy = 0.0
	else:
		_is_completely_off = false

func _end_glitch() -> void:
	# Restore the flashlight to working condition
	_is_glitching = false
	_is_completely_off = false
	light_energy = base_energy
	_reset_glitch_timer()

func _reset_glitch_timer() -> void:
	# Pick a random time for the next event to occur
	_next_glitch_timer = randf_range(min_time_between_glitches, max_time_between_glitches)
