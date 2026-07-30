extends CanvasLayer

@onready var overlay = $ColorRect
@onready var button = $ColorRect/Button
@onready var deathAudio = $ColorRect/AudioStreamPlayer2D

func _ready() -> void:
	overlay.visible = false
	overlay.color = Color(0, 0, 0, 0)
	button.visible = false
	SignalBus.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	deathAudio.play()
	get_tree().get_root().find_child("GameUI", true, false).visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	overlay.visible = true
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0.604, 0.0, 0.0, 1.0), 1.5)
	tween.tween_callback(_show_text)

func _show_text() -> void:
	button.visible = true

func _on_button_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()
