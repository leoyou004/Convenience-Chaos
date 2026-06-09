extends CanvasLayer

@onready var overlay = $ColorRect
@onready var label = $ColorRect/Label
@onready var button = $ColorRect/Button

func _ready() -> void:
	overlay.visible = false
	overlay.color = Color(0, 0, 0, 0)
	SignalBus.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	overlay.visible = true
	# Fade in the black screen
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0.549, 0.0, 0.0, 1.0), 1.5)
	tween.tween_callback(_show_text)


func _show_text() -> void:
	label.visible = true
	button.visible = true

func _on_button_pressed() -> void:
	# Restart the current scene
	get_tree().reload_current_scene()
