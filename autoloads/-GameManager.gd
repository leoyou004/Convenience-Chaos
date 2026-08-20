extends Node

enum State { MENU, PLAYING, PAUSED, GAME_OVER, WIN }

var current_state: int = State.MENU
var night_timer: float = 0.0
var night_duration: float = 360.0

# --- Objective Tracking Variables ---
var total_objectives: int = 3
var completed_objectives: int = 0

# The active win flow changes to Scenes/end_scene.tscn from ObjectiveManager.
var win_screen: CanvasItem

func _ready():
	win_screen = get_node_or_null("CanvasLayer/WinScreen") as CanvasItem
	if win_screen:
		win_screen.hide()

func _process(delta):
	if current_state == State.PLAYING:
		night_timer += delta
		if night_timer >= night_duration:
			set_state(State.GAME_OVER)

func set_state(new_state: int):
	current_state = new_state
	
	# Handle what happens when entering specific states
	match current_state:
		State.WIN:
			trigger_win_screen()
		State.GAME_OVER:
			# You can handle your game over UI here too
			pass

func start_game():
	night_timer = 0.0
	completed_objectives = 0 # Reset objectives on game start
	if win_screen:
		win_screen.hide()
	set_state(State.PLAYING)

# --- Objective Logic ---

# Call this function from your objective scripts whenever one is finished
func complete_objective():
	if current_state != State.PLAYING:
		return
		
	completed_objectives += 1
	
	# Check if all objectives are done
	if completed_objectives >= total_objectives:
		set_state(State.WIN)

func trigger_win_screen():
	if win_screen:
		win_screen.show()
	# Optional: Pause the game scene tree so things stop moving
	get_tree().paused = true 

func get_time_remaining() -> float:
	return max(0.0, night_duration - night_timer)
	
