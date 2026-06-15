extends CharacterBody3D

const SPEED         := 7.0
const CATCH_DISTANCE := 1.2
const GRAVITY       := 9.8
const PATH_UPDATE   := 0.1

var nav_agent : NavigationAgent3D
var player    : Node3D
var path_timer := 0.0

@onready var anim_player = $"Running (2)/AnimationPlayer"
@onready var audio       = $CollisionShape3D/Scream

# Path drawing
var path_mesh_instance : MeshInstance3D
var path_mesh          : ImmediateMesh

func _ready() -> void:
	nav_agent = $NavigationAgent3D
	player    = get_tree().get_first_node_in_group("Player")

	# Set up path visualizer
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

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if player:
		# Throttle nav target updates
		path_timer -= delta
		if path_timer <= 0.0:
			path_timer = PATH_UPDATE
			nav_agent.target_position = player.global_position
			_draw_path()

		var next      = nav_agent.get_next_path_position()
		var direction = (next - global_position).normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		move_and_slide()

		var flat = Vector3(direction.x, 0, direction.z)
		if flat.length_squared() > 0.01:
			look_at(global_position + flat.normalized(), Vector3.UP)

	# Catch check
	if player and global_position.distance_to(player.global_position) <= CATCH_DISTANCE:
		SignalBus.player_caught.emit()

func _draw_path() -> void:
	path_mesh.clear_surfaces()
	var points = nav_agent.get_current_navigation_path()
	if points.size() < 2:
		return

	path_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		path_mesh.surface_add_vertex(p + Vector3(0, 0.1, 0))  # slight Y offset to avoid z-fighting
	path_mesh.surface_end()
