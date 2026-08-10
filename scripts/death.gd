extends CanvasLayer

func _ready():
	SignalBus.player_died.connect(player_dead)
	
func player_dead():
	show()
