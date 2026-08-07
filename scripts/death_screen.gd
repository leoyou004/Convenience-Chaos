extends CanvasLayer

func _ready() -> void:
	visible = false
	SignalBus.player_died.connect(_show_death_screen)

func _show_death_screen() -> void:
	visible = true
