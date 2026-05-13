extends CharacterBody3D

enum State { PATROL, INVESTIGATE, CHASE }

var state: State = State.PATROL
var nav_agent: NavigationAgent3D
var player: Node3D = null
var last_noise_position: Vector3 = Vector3.ZERO
var investigate_timer: float = 0.0
var investigate_center: Vector3 = Vector3.ZERO
var investigate_wander_timer: float = 0.0
var _distraction_handled: bool = false
const INVESTIGATE_TIME := 8.0
const WANDER_INTERVAL := 2.0
const WANDER_RADIUS := 5.0
const PATROL_SPEED := 5.0
const CHASE_SPEED := 6.5
const CATCH_DISTANCE := 1.2
const HEARING_RANGE_SPRINT := 12.0

func _ready() -> void:
	nav_agent = $NavigationAgent3D
	player = get_tree().get_first_node_in_group("player")
	SignalBus.noise_level_changed.connect(_on_noise)
	SignalBus.distraction_thrown.connect(_on_distraction_thrown)
	HotBarManager.hotbar_updated.connect(_on_hotbar_updated)
	$HearingRange.body_entered.connect(_on_hearing_body_entered)
	$HearingRange.body_exited.connect(_on_hearing_body_exited)
	$VisionCone.body_entered.connect(_on_vision_body_entered)
	$VisionCone.body_exited.connect(_on_vision_body_exited)
	_pick_random_patrol_point()

func _physics_process(delta: float) -> void:
	match state:
		State.PATROL:
			_patrol(delta)
		State.INVESTIGATE:
			_investigate(delta)
		State.CHASE:
			_chase(delta)
	_check_catch()

func _patrol(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		_pick_random_patrol_point()
	_move_along_path(PATROL_SPEED)

func _investigate(delta: float) -> void:
	if not nav_agent.is_navigation_finished():
		_move_along_path(PATROL_SPEED)

	investigate_timer -= delta
	if investigate_timer <= 0.0:
		_set_state(State.PATROL)
		_pick_random_patrol_point()
		return

	investigate_wander_timer -= delta
	if investigate_wander_timer <= 0.0:
		investigate_wander_timer = WANDER_INTERVAL
		_pick_wander_point()

func _chase(_delta: float) -> void:
	if player == null:
		_set_state(State.PATROL)
		return
	nav_agent.target_position = player.global_position
	_move_along_path(CHASE_SPEED)

func _move_along_path(speed: float) -> void:
	var next = nav_agent.get_next_path_position()
	var direction = (next - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)

func _set_state(new_state: State) -> void:
	state = new_state
	match new_state:
		State.PATROL:
			SignalBus.enemy_calm.emit()
		State.INVESTIGATE:
			SignalBus.enemy_alerted.emit()
		State.CHASE:
			SignalBus.enemy_alerted.emit()

func _start_investigate(position: Vector3) -> void:
	investigate_center = position
	investigate_timer = INVESTIGATE_TIME
	investigate_wander_timer = 0.0
	_set_state(State.INVESTIGATE)
	nav_agent.target_position = position

func _pick_wander_point() -> void:
	var offset = Vector3(
		randf_range(-WANDER_RADIUS, WANDER_RADIUS),
		0,
		randf_range(-WANDER_RADIUS, WANDER_RADIUS)
	)
	var wander_target = investigate_center + offset
	var map_rid = NavigationServer3D.get_maps()[0]
	var nearest = NavigationServer3D.map_get_closest_point(map_rid, wander_target)
	nav_agent.target_position = nearest

func _pick_random_patrol_point() -> void:
	var map_rid = NavigationServer3D.get_maps()[0]
	var random_point = NavigationServer3D.map_get_random_point(map_rid, 1, false)
	nav_agent.target_position = random_point

func _check_catch() -> void:
	if player == null:
		return
	if global_position.distance_to(player.global_position) <= CATCH_DISTANCE:
		SignalBus.player_caught.emit()

func _on_distraction_thrown(position: Vector3) -> void:
	if state == State.CHASE:
		return
	if _distraction_handled:
		return
	_distraction_handled = true
	_start_investigate(position)

func _on_hotbar_updated(slots: Array, _active_slot: int) -> void:
	for slot in slots:
		if slot != null:
			_distraction_handled = false
			return

func _on_noise(level: float) -> void:
	if player == null:
		return
	var dist = global_position.distance_to(player.global_position)
	if level > 0.5 and dist <= HEARING_RANGE_SPRINT:
		if state != State.CHASE:
			_start_investigate(player.global_position)

func _on_hearing_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var is_crouching = body.get("is_crouching") if body.get("is_crouching") != null else false
		var is_prone = body.get("is_prone") if body.get("is_prone") != null else false
		if not is_crouching and not is_prone:
			_set_state(State.CHASE)

func _on_hearing_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		if state == State.CHASE:
			_start_investigate(player.global_position)

func _on_vision_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_set_state(State.CHASE)

func _on_vision_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		if state == State.CHASE:
			_start_investigate(player.global_position)
