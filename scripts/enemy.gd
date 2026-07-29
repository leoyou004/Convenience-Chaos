extends CharacterBody3D

const SPEED := 5.5
const CATCH_DISTANCE := 1.2
const GRAVITY := 9.8
const DISTRACTION_DURATION := 5.0
const STUN_DURATION := 5.0

var nav_agent: NavigationAgent3D
var player: Node3D
var can_see_player := false
var has_screamed := false
var item_target_position: Vector3 = Vector3.ZERO
var has_item_target := false
var distraction_timer := 0.0
var is_stunned := false
var stun_timer := 0.0

@onready var anim_player = $"Running (2)/AnimationPlayer"
@onready var audio = $CollisionShape3D/Scream

func _ready() -> void:
	nav_agent = $NavigationAgent3D
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_tree().get_first_node_in_group("Player")

	nav_agent.path_desired_distance = 0.8
	nav_agent.target_desired_distance = 0.8
	nav_agent.avoidance_enabled = false

	$VisionCone.body_entered.connect(_on_vision_entered)
	$VisionCone.body_exited.connect(_on_vision_exited)
	SignalBus.distraction_thrown.connect(_on_distraction_thrown)
	SignalBus.item_landed.connect(_on_item_landed)

	if anim_player.has_animation("mixamo_com"):
		anim_player.get_animation("mixamo_com").loop_mode = Animation.LOOP_LINEAR
		anim_player.play("mixamo_com")

func _on_vision_entered(body: Node3D) -> void:
	if body.is_in_group("item"):
		hit_by_item()
		return
	if not body.is_in_group("player") and not body.is_in_group("Player"):
		return
	can_see_player = true
	if not has_screamed:
		has_screamed = true
		audio.play()

func _on_vision_exited(body: Node3D) -> void:
	if not body.is_in_group("player") and not body.is_in_group("Player"):
		return
	can_see_player = false
	has_screamed = false

func _set_item_target(position: Vector3) -> void:
	item_target_position = position
	has_item_target = true
	distraction_timer = DISTRACTION_DURATION

func _on_distraction_thrown(position: Vector3) -> void:
	_set_item_target(position)

func _on_item_landed(position: Vector3) -> void:
	_set_item_target(position)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
			velocity.x = 0.0
			velocity.z = 0.0
		move_and_slide()
		return

	if has_item_target:
		distraction_timer -= delta
		if distraction_timer <= 0.0:
			has_item_target = false

	var target_position: Vector3 = player.global_position if player else global_position
	if has_item_target:
		target_position = item_target_position

	if target_position != Vector3.ZERO:
		nav_agent.target_position = target_position

	var next_position = nav_agent.get_next_path_position()
	if next_position != Vector3.ZERO:
		var direction = (next_position - global_position).normalized()
		direction.y = 0.0
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * delta)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * delta)

	move_and_slide()

	if player and global_position.distance_to(player.global_position) <= CATCH_DISTANCE:
		SignalBus.player_caught.emit()

func hit_by_item() -> void:
	is_stunned = true
	stun_timer = STUN_DURATION
	velocity.x = 0.0
	velocity.z = 0.0
