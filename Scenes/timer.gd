extends Label

var time_elapsed: float = 0.0
var running: bool = false

func _ready() -> void:
	text = "00:00:000"
	SignalBus.connect("all_objectives_completed", _on_all_completed)

func _process(delta: float) -> void:
	if not running:
		return
	time_elapsed += delta
	var minutes = int(time_elapsed) / 60
	var seconds = int(time_elapsed) % 60
	var milliseconds = int(fmod(time_elapsed, 1.0) * 1000)
	text = "%02d:%02d:%03d" % [minutes, seconds, milliseconds]

func _input(event: InputEvent) -> void:
	if not running:
		if event is InputEventMouseMotion or event is InputEventKey:
			running = true

func _on_all_completed() -> void:
	running = false
