extends CharacterBody3D

const SPEED := 5.0
const CATCH_DISTANCE := 1.2
const GRAVITY := 9.8

# Adjusted path to safely fallback if the model node name differs
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else $EnemyModel/AnimationPlayer
@onready var scream_audio: AudioStreamPlayer3D = $CollisionShape3D/Scream if has_node("CollisionShape3D/Scream") else null

var player: Node3D
var can_see_player := false
var has_screamed := false
var current_anim_state := ""

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_tree().get_first_node_in_group("Player")

	nav_agent.path_desired_distance = 0.8
	nav_agent.target_desired_distance = 0.8
	nav_agent.avoidance_enabled = false

	# Connect vision signals safely
	if has_node("VisionCone"):
		$VisionCone.body_entered.connect(_on_vision_entered)
		$VisionCone.body_exited.connect(_on_vision_exited)

	_play_animation_state("idle")

func _play_animation_state(state: String) -> void:
	if anim_player == null:
		return
		
	if state == current_anim_state:
		return

	current_anim_state = state

	if state == "idle":
		if anim_player.has_animation("local/Zombie_Idle"):
			anim_player.play("local/Zombie_Idle")
	elif state == "run":
		if anim_player.has_animation("local/Zombie_Walk_Fwd"):
			anim_player.play("local/Zombie_Walk_Fwd")

func _on_vision_entered(body: Node3D) -> void:
	if not body.is_in_group("player") and not body.is_in_group("Player"):
		return
	
	can_see_player = true
	if not has_screamed and scream_audio:
		has_screamed = true
		scream_audio.play()

func _on_vision_exited(body: Node3D) -> void:
	if not body.is_in_group("player") and not body.is_in_group("Player"):
		return
	can_see_player = false
	has_screamed = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	if player:
		nav_agent.target_position = player.global_position

	var next_position = nav_agent.get_next_path_position()
	if next_position != Vector3.ZERO:
		var direction = (next_position - global_position).normalized()
		direction.y = 0.0
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		if direction.length_squared() > 0.001:
			look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * delta)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * delta)

	move_and_slide()

	var should_run := velocity.length_squared() > 0.25
	_play_animation_state("run" if should_run else "idle")

	if player and global_position.distance_to(player.global_position) <= CATCH_DISTANCE:
		SignalBus.player_caught.emit()
