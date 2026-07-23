extends CharacterBody3D

const SPEED          := 7.0
const CATCH_DISTANCE := 1.2
const GRAVITY        := 9.8
const PATH_UPDATE    := 0.1
const PATROL_INTERVAL := 3.0

var nav_agent      : NavigationAgent3D
var player         : Node3D
var path_timer     := 0.0
var patrol_timer   := 0.0
var can_see_player := false
var has_screamed   := false   # so it only plays once per spot
var item_target_position : Vector3 = Vector3.ZERO
var has_item_target := false

@onready var anim_player = $"Running (2)/AnimationPlayer"
@onready var audio       = $CollisionShape3D/Scream

var path_mesh_instance : MeshInstance3D
var path_mesh          : ImmediateMesh

func _ready() -> void:
	nav_agent = $NavigationAgent3D
	player    = get_tree().get_first_node_in_group("Player")

	$VisionCone.body_entered.connect(_on_vision_entered)
	$VisionCone.body_exited.connect(_on_vision_exited)
	SignalBus.item_landed.connect(_on_item_landed)

	path_mesh = ImmediateMesh.new()
	path_mesh_instance = MeshInstance3D.new()
	path_mesh_instance.mesh = path_mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	path_mesh_instance.material_override = mat
	get_parent().add_child(path_mesh_instance)

	await get_tree().physics_frame
	await get_tree().physics_frame

	if anim_player.has_animation("mixamo_com"):
		anim_player.get_animation("mixamo_com").loop_mode = Animation.LOOP_LINEAR
		anim_player.play("mixamo_com")

	_pick_patrol_point()

func _on_vision_entered(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	can_see_player = true
	if not has_screamed:
		has_screamed = true
		audio.play()

func _on_vision_exited(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	can_see_player = false
	has_screamed = false   # reset so it screams again next time it spots the player

func _on_item_landed(position: Vector3) -> void:
	item_target_position = position
	has_item_target = true
	print("Enemy detected item at: ", position)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	path_timer -= delta
	if path_timer <= 0.0:
		path_timer = PATH_UPDATE
		if can_see_player and player:
			nav_agent.target_position = player.global_position
		elif has_item_target:
			nav_agent.target_position = item_target_position
		_draw_path()

	if not can_see_player and not has_item_target:
		patrol_timer -= delta
		if patrol_timer <= 0.0 or nav_agent.is_navigation_finished():
			_pick_patrol_point()
	elif has_item_target and global_position.distance_to(item_target_position) < 1.0:
		# Reached the item
		has_item_target = false
		_pick_patrol_point()

	var next      = nav_agent.get_next_path_position()
	var direction = (next - global_position).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()

	var flat = Vector3(direction.x, 0, direction.z)
	if flat.length_squared() > 0.01:
		look_at(global_position + flat.normalized(), Vector3.UP)

	if player and global_position.distance_to(player.global_position) <= CATCH_DISTANCE:
		SignalBus.player_caught.emit()

func _pick_patrol_point() -> void:
	patrol_timer = PATROL_INTERVAL
	var map   = NavigationServer3D.get_maps()[0]
	var point = NavigationServer3D.map_get_random_point(map, 1, false)
	nav_agent.target_position = point

func _draw_path() -> void:
	path_mesh.clear_surfaces()
	var points = nav_agent.get_current_navigation_path()
	if points.size() < 2:
		return
	path_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		path_mesh.surface_add_vertex(p + Vector3(0, 0.1, 0))
	path_mesh.surface_end()
