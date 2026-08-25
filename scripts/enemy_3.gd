extends CharacterBody3D

@export var speed: float = 15
@export var patrol_points: Array[Node3D]

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var current_point_index: int = 0

func _ready() -> void:
	# Ensure we have points to patrol before starting
	if patrol_points.size() > 0:
		_update_target_location()
	else:
		push_warning("Enemy has no patrol points assigned!")

func _physics_process(_delta: float) -> void:
	if patrol_points.is_empty():
		return
		
	# Check if we have reached the current patrol point
	if nav_agent.is_navigation_finished():
		_go_to_next_point()
		return

	# Calculate the direction to the next step in the navigation path
	var current_location = global_position
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * speed
	
	# Apply velocity and move
	velocity = new_velocity
	move_and_slide()

func _update_target_location() -> void:
	# Tell the NavigationAgent where it needs to go
	var target_position = patrol_points[current_point_index].global_position
	nav_agent.target_position = target_position

func _go_to_next_point() -> void:
	# Loop back to the first point if we reach the end of the array
	current_point_index = (current_point_index + 1) % patrol_points.size()
	_update_target_location()
