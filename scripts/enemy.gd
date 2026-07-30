extends CharacterBody3D

const SPEED := 6.5
const CATCH_DISTANCE := 1.2
const GRAVITY := 9.8
const DISTRACTION_DURATION := 5.0
const STUN_DURATION := 3.0

var nav_agent: NavigationAgent3D
var player: Node3D
var can_see_player := false
var has_screamed := false
var item_target_position: Vector3 = Vector3.ZERO
var has_item_target := false
var distraction_timer := 0.0
var is_stunned := false
var stun_timer := 0.0

var run_model: Node3D
var idle_model: Node3D
var sweep_model: Node3D
var run_anim_player: AnimationPlayer
var idle_anim_player: AnimationPlayer
var sweep_anim_player: AnimationPlayer
var current_anim_state := "idle"

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

	_setup_animation_models()
	_play_animation_state("idle")

func _setup_animation_models() -> void:
	run_model = $"Running (2)"
	run_anim_player = _get_animation_player(run_model)

	idle_model = _create_animation_model("IdleModel", "res://Scenes/Idle.fbx")
	idle_anim_player = _get_animation_player(idle_model)

	sweep_model = _create_animation_model("SweepModel", "res://Scenes/Sweep Fall.fbx")
	sweep_anim_player = _get_animation_player(sweep_model)

	_configure_animation_player(run_anim_player, true)
	_configure_animation_player(idle_anim_player, true)
	_configure_animation_player(sweep_anim_player, false)

func _create_animation_model(name: String, scene_path: String) -> Node3D:
	if scene_path == "":
		return null

	var resource: Resource = load(scene_path)
	if resource == null:
		return null

	var packed_scene := resource as PackedScene
	if packed_scene == null:
		return null

	var instance = packed_scene.instantiate()
	if instance is Node3D:
		var model := instance as Node3D
		model.name = name
		model.transform = $"Running (2)".transform
		add_child(model)
		model.owner = self
		model.visible = false
		return model
	return null

func _get_animation_player(model: Node3D) -> AnimationPlayer:
	if model == null:
		return null
	return model.get_node_or_null("AnimationPlayer") as AnimationPlayer

func _configure_animation_player(player: AnimationPlayer, loop: bool) -> void:
	if player == null:
		return
	var animation_name: StringName = "mixamo_com"
	if not player.has_animation(animation_name):
		var list = player.get_animation_list()
		if list.size() > 0:
			animation_name = StringName(list[0])
	if player.has_animation(animation_name):
		var animation: Animation = player.get_animation(animation_name)
		animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE

func _set_model_visibility(active_model: Node3D) -> void:
	for model in [run_model, idle_model, sweep_model]:
		if model != null:
			model.visible = model == active_model

func _play_animation_state(state: String) -> void:
	if state == current_anim_state and state != "stunned":
		return

	current_anim_state = state

	if state == "idle":
		_set_model_visibility(idle_model)
		_play_animation_player(idle_anim_player)
	elif state == "run":
		_set_model_visibility(run_model)
		_play_animation_player(run_anim_player)
	elif state == "stunned":
		_set_model_visibility(sweep_model)
		_play_animation_player(sweep_anim_player)

func _play_animation_player(player: AnimationPlayer) -> void:
	if player == null:
		return
	var animation_name: StringName = "mixamo_com"
	if not player.has_animation(animation_name):
		var list = player.get_animation_list()
		if list.size() > 0:
			animation_name = StringName(list[0])
	if player.has_animation(animation_name):
		player.play(animation_name)

func _on_animation_finished(anim_name: StringName) -> void:
	if current_anim_state == "stunned":
		_play_animation_state("idle")

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
		_play_animation_state("stunned" if is_stunned else ("run" if velocity.length_squared() > 0.25 else "idle"))
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

	var should_run := velocity.length_squared() > 0.25
	_play_animation_state("run" if should_run else "idle")

	if player and global_position.distance_to(player.global_position) <= CATCH_DISTANCE:
		SignalBus.player_caught.emit()

func hit_by_item() -> void:
	is_stunned = true
	stun_timer = STUN_DURATION
	velocity.x = 0.0
	velocity.z = 0.0
	_play_animation_state("stunned")
