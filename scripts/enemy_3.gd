extends CharacterBody3D

@export var speed: float = 17
@export var patrol_points: Array[Node3D]
# Added a variable to control how often the enemy turns around (0.3 = 30% chance)
@export var reverse_chance: float = 0.3 

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var touch_area: Area3D = $TouchArea

var current_point_index: int = 0
var patrol_direction: int = 1 # 1 for forwards, -1 for backwards

func _ready() -> void:
	# Ensure we have points to patrol before starting
	if patrol_points.size() > 0:
		_update_target_location()
	else:
		push_warning("Enemy has no patrol points assigned!")
	touch_area.body_entered.connect(_on_touch_area_body_entered)

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
	# Randomly decide if we should flip direction
	if randf() < reverse_chance:
		patrol_direction *= -1 
		
	# Calculate the next index. 
	# We use posmod() instead of % because % can return a negative number 
	# when moving backwards, which would crash the array lookup.
	current_point_index = posmod(current_point_index + patrol_direction, patrol_points.size())
	
	_update_target_location()

func _on_touch_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		SignalBus.player_caught.emit()
