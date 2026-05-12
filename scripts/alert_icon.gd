extends TextureRect

func _ready() -> void:
	visible = false
	SignalBus.connect("player_caught", _on_player_caught)

func _process(_delta: float) -> void:
	pass

func show_alert() -> void:
	visible = true

func hide_alert() -> void:
	visible = false

func _on_player_caught() -> void:
	visible = true
