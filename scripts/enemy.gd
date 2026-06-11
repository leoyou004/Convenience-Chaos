extends CharacterBody3D

enum State { PATROL, INVESTIGATE, CHASE }

const INVESTIGATE_TIME  := 5.0
const WANDER_INTERVAL   := 0.5
const WANDER_RADIUS     := 5.0
const PATROL_SPEED      := 6.5
const CHASE_SPEED       := 7.5
const CATCH_DISTANCE    := 1.2
const HEARING_RANGE     := 12.0
const STEP_HEIGHT       := 0.4
const STEP_DIST         := 0.3
const STUCK_TIME        := 0
const STUCK_DISTANCE    := 0
const GRAVITY           := 9.8

var state               := State.PATROL
var nav_agent           : NavigationAgent3D
var player              : Node3D
var investigate_center  := Vector3.ZERO
var investigate_timer   := 0.0
var wander_timer        := 0.0
var boost_timer         := 0.0
var stuck_timer         := 0.0
var last_position       := Vector3.ZERO
var distraction_used    := false
var chase_update_timer  := 0.0

const CHASE_UPDATE_INTERVAL := 0.1

@onready var anim_player = $"Running (2)/AnimationPlayer"
@onready var audio = $CollisionShape3D/Scream

func _ready() -> void:
	nav_agent = $NavigationAgent3D
	player    = get_tree().get_first_node_in_group("Player")

	SignalBus.noise_level_changed.connect(_on_noise)
	SignalBus.distraction_thrown.connect(_on_distraction_thrown)
	HotBarManager.hotbar_updated.connect(_on_hotbar_updated)
	$HearingRange.body_entered.connect(_on_hearing_body_entered)
	$HearingRange.body_exited.connect(_on_hearing_body_exited)
	$VisionCone.body_entered.connect(_on_vision_body_entered)
	$VisionCone.body_exited.connect(_on_vision_body_exited)

	_pick_patrol_point()

	if anim_player.has_animation("mixamo_com"):
		anim_player.get_animation("mixamo_com").loop_mode = Animation.LOOP_LINEAR
		anim_player.play("mixamo_com")

func _physics_process(delta: float) -> void:
	if boost_timer > 0.0:
		boost_timer -= delta
		velocity.y = 3.5
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	match state:
		State.PATROL:      _patrol(delta)
		State.INVESTIGATE: _investigate(delta)
		State.CHASE:       _chase(delta)

	_handle_step_up()
	_check_catch()

func _patrol(delta: float) -> void:
	stuck_timer += delta
	if stuck_timer >= STUCK_TIME:
		stuck_timer = 0.0
		if global_position.distance_to(last_position) < STUCK_DISTANCE:
			_pick_patrol_point()
		last_position = global_position

	if nav_agent.is_navigation_finished():
		_pick_patrol_point()

	_move(PATROL_SPEED)

func _investigate(delta: float) -> void:
	_move(PATROL_SPEED)

	investigate_timer -= delta
	if investigate_timer <= 0.0:
		_set_state(State.PATROL)
		_pick_patrol_point()
		return

	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = WANDER_INTERVAL
		_pick_wander_point()

func _chase(delta: float) -> void:
	if player == null:
		_set_state(State.PATROL)
		return

	chase_update_timer -= delta
	if chase_update_timer <= 0.0:
		chase_update_timer = CHASE_UPDATE_INTERVAL
		nav_agent.target_position = player.global_position

	_move(CHASE_SPEED)

func _move(speed: float) -> void:
	var next      = nav_agent.get_next_path_position()
	var direction = (next - global_position).normalized()
	velocity.x    = direction.x * speed
	velocity.z    = direction.z * speed
	move_and_slide()

	var flat = Vector3(direction.x, 0, direction.z)
	if flat.length_squared() > 0.01:
		look_at(global_position + flat.normalized(), Vector3.UP)

func _handle_step_up() -> void:
	if not is_on_floor() or velocity.length() < 0.1:
		return

	var space   = get_world_3d().direct_space_state
	var forward = Vector3(velocity.x, 0, velocity.z).normalized()

	var foot_start = global_position + Vector3(0, 0.05, 0)
	var foot_end   = foot_start + forward * STEP_DIST
	if not space.intersect_ray(PhysicsRayQueryParameters3D.create(foot_start, foot_end)):
		return

	var step_start = global_position + Vector3(0, STEP_HEIGHT, 0)
	var step_end   = step_start + forward * STEP_DIST
	if not space.intersect_ray(PhysicsRayQueryParameters3D.create(step_start, step_end)):
		global_position.y += STEP_HEIGHT

func apply_ledge_boost() -> void:
	boost_timer = 0.3
	velocity.y  = 3.5

func _set_state(new_state: State) -> void:
	state = new_state
	if new_state == State.PATROL:
		SignalBus.enemy_calm.emit()
	elif new_state == State.CHASE:
		SignalBus.enemy_alerted.emit()
		if not audio.playing:
			audio.play()
	else:
		SignalBus.enemy_alerted.emit()

func _start_investigate(pos: Vector3) -> void:
	investigate_center        = pos
	investigate_timer         = INVESTIGATE_TIME
	wander_timer              = 0.0
	_set_state(State.INVESTIGATE)
	nav_agent.target_position = pos

func _check_catch() -> void:
	if player and global_position.distance_to(player.global_position) <= CATCH_DISTANCE:
		SignalBus.player_caught.emit()

func _pick_patrol_point() -> void:
	var map   = NavigationServer3D.get_maps()[0]
	var point = NavigationServer3D.map_get_random_point(map, 1, false)
	if NavigationServer3D.map_get_closest_point(map, point).distance_to(point) < 1.0:
		nav_agent.target_position = point
	else:
		await get_tree().create_timer(0.5).timeout
		_pick_patrol_point()

func _pick_wander_point() -> void:
	var offset = Vector3(randf_range(-WANDER_RADIUS, WANDER_RADIUS), 0,
		randf_range(-WANDER_RADIUS, WANDER_RADIUS))
	var map    = NavigationServer3D.get_maps()[0]
	nav_agent.target_position = NavigationServer3D.map_get_closest_point(map, investigate_center + offset)

func _on_noise(level: float) -> void:
	if player and level > 0.5 and state != State.CHASE:
		if global_position.distance_to(player.global_position) <= HEARING_RANGE:
			_start_investigate(player.global_position)
	
	func _on_distraction_thrown(pos: Vector3) -> void:
	# Now triggers ever
