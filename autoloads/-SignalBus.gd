extends Node

signal game_state_changed(new_state)
signal objective_completed(objective_id)
signal all_objectives_completed
signal player_caught
signal distraction_thrown(position)
signal noise_level_changed(level)
signal sprint_stamina_changed(current_stamina, max_stamina)
signal interactable_focused(objective_id: String, hold_time: float)
signal interactable_unfocused
signal interact_progress(progress: float)
signal enemy_alerted
signal enemy_calm
