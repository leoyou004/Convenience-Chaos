extends CharacterBody3D

@onready var camera_mount = %CameraMount
@onready var camera = %CameraMount/Camera3D
@onready var collision_shape = $CollisionShape3D

var speed = 5.0
var sprint_speed = 8.0
var crouch_speed = 2.5
var prone_speed = 1.0
var current_speed = speed
var mouse_sensitivity = 0.002
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var hand_display: Node3D = null

const STANDING_HEIGHT := 0.7
const CROUCH_HEIGHT := 0.3
const PRONE_HEIGHT := 0.001
const STANDING_CAMERA_HEIGHT := 1
const CROUCH_CAMERA_HEIGHT := 0.2
const PRONE_CAMERA_HEIGHT := 0.001
const SPRINT_MAX_SECONDS := 7.0
const SPRINT_RECHARGE_SECONDS := 10.0
const JUMP_VELOCITY := 3.0
const BHOP_MULTIPLIER := 1.08
const BHOP_MAX := 14.0
const STEP_HEIGHT := 0.4
const STEP_CHECK_DISTANCE := 0.3

var is_crouching = false
var is_prone = false
var is_exhausted = false
var bhop_speed: float = 0.0

var base_collision_position_y: float
var base_collision_half_height: float = 0.0
var base_capsule_height: float = 1.0
var base_capsule_radius: float = 0.0
var base_camera_height: float = 0.9
var crouch_camera_height: float = 0.5
var prone_camera_height: float = 0.15
var sprint_stamina: float = SPRINT_MAX_SECONDS

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	collision_shape.scale = Vector3.ONE

	if collision_shape.shape is CapsuleShape3D:
		collision_shape.shape = collision_shape.shape.duplicate()
		var capsule := collision_shape.shape as CapsuleShape3D
		base_capsule_height = capsule.height
		base_capsule_radius = capsule.radius
		base_collision_half_height = (base_capsule_height / 2.0) + base_capsule_radius

	base_collision_position_y = collision_shape.position.y
	base_camera_height = camera_mount.position.y

	_apply_posture_height(STANDING_HEIGHT)
	_setup_hand_display()
	HotBarManager.hotbar_updated.connect(_on_hotbar_updated)

func _input(event):
	if event is InputEventMouseMotion:
		camera_mount.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			HotBarManager.cycle_slot(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			HotBarManager.cycle_slot(-1)

func _physics_process(delta):
	if Input.is_action_just_pressed("slot_1"):
		HotBarManager.set_active_slot(0)
	if Input.is_action_just_pressed("slot_2"):
		HotBarManager.set_active_slot(1)
	if Input.is_action_just_pressed("slot_3"):
		HotBarManager.set_active_slot(2)

	if Input.is_action_just_pressed("drop_item"):
		HotBarManager.drop_active_item(self)
	if Input.is_action_just_pressed("throw_item"):
		HotBarManager.throw_active_item(self)

	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction = (camera_mount.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
			if bhop_speed < BHOP_MAX:
				bhop_speed = minf(bhop_speed * BHOP_MULTIPLIER, BHOP_MAX)
			else:
				bhop_speed = BHOP_MAX
		else:
			bhop_speed = move_toward(bhop_speed, 0.0, 2.0 * delta)

	if direction:
		var effective_speed = current_speed + bhop_speed
		velocity.x = direction.x * effective_speed
		velocity.z = direction.z * effective_speed
	else:
		bhop_speed = move_toward(bhop_speed, 0.0, 5.0 * delta)
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	var is_standing := not is_crouching and not is_prone
	var wants_to_sprint := Input.is_action_pressed("sprint") and is_standing

	if wants_to_sprint and sprint_stamina > 0.0 and not is_exhausted:
		sprint_stamina = maxf(0.0, sprint_stamina - delta)
		current_speed = sprint_speed
	else:
		sprint_stamina = minf(SPRINT_MAX_SECONDS, sprint_stamina + (SPRINT_MAX_SECONDS / SPRINT_RECHARGE_SECONDS) * delta)
		if is_prone:
			current_speed = prone_speed
		elif is_crouching:
			current_speed = crouch_speed
		else:
			current_speed = speed

	if sprint_stamina <= 0.0:
		is_exhausted = true
	elif sprint_stamina >= SPRINT_MAX_SECONDS:
		is_exhausted = false

	SignalBus.sprint_stamina_changed.emit(sprint_stamina, SPRINT_MAX_SECONDS)

	if Input.is_action_just_pressed("crouch"):
		if is_prone:
			is_prone = false
			is_crouching = true
			_apply_posture_height(CROUCH_HEIGHT)
		elif is_crouching:
			is_crouching = false
			_apply_posture_height(STANDING_HEIGHT)
		else:
			is_crouching = true
			_apply_posture_height(CROUCH_HEIGHT)

	if Input.is_action_just_pressed("prone"):
		if is_crouching:
			is_crouching = false
			is_prone = true
			_apply_posture_height(PRONE_HEIGHT)
		elif is_prone:
			is_prone = false
			_apply_posture_height(STANDING_HEIGHT)
		else:
			is_prone = true
			_apply_posture_height(PRONE_HEIGHT)

	_handle_step_up()
	move_and_slide()

func _handle_step_up() -> void:
	if is_on_floor() and velocity.length() > 0.1:
		var space = get_world_3d().direct_space_state
		var forward = Vector3(velocity.x, 0, velocity.z).normalized()

		var foot_origin = global_position
		var foot_query = PhysicsRayQueryParameters3D.create(
			foot_origin,
			foot_origin + forward * STEP_CHECK_DISTANCE,
			collision_mask
		)
		foot_query.exclude = [self]
		var foot_hit = space.intersect_ray(foot_query)

		if foot_hit:
			var step_origin = global_position + Vector3(0, STEP_HEIGHT, 0)
			var step_query = PhysicsRayQueryParameters3D.create(
				step_origin,
				step_origin + forward * STEP_CHECK_DISTANCE,
				collision_mask
			)
			step_query.exclude = [self]
			var step_hit = space.intersect_ray(step_query)

			if not step_hit:
				global_position.y += STEP_HEIGHT
				velocity.y = 0.0

func _apply_posture_height(height: float) -> void:
	var multiplier = height / base_capsule_height

	if collision_shape.shape is CapsuleShape3D:
		var capsule := collision_shape.shape as CapsuleShape3D
		capsule.height = base_capsule_height * multiplier
		capsule.radius = base_capsule_radius
		var new_half_height := (capsule.height / 2.0) + base_capsule_radius
		var height_delta := base_collision_half_height - new_half_height
		collision_shape.position.y = base_collision_position_y - height_delta

	if is_prone:
		camera_mount.position.y = PRONE_CAMERA_HEIGHT
	elif is_crouching:
		camera_mount.position.y = CROUCH_CAMERA_HEIGHT
	else:
		camera_mount.position.y = STANDING_CAMERA_HEIGHT

func _setup_hand_display() -> void:
	hand_display = Node3D.new()
	hand_display.name = "HandDisplay"
	camera_mount.add_child(hand_display)
	hand_display.position = Vector3(0.15, -0.1, -0.3)

func _on_hotbar_updated(slots: Array, active_slot: int) -> void:
	if hand_display == null:
		return

	for child in hand_display.get_children():
		child.queue_free()

	var active_item = slots[active_slot]
	if active_item == null:
		return

	var icon = null
	if typeof(active_item) == TYPE_OBJECT:
		icon = active_item.get("icon") if active_item.has_method("get") else null

	if icon and icon is Texture2D:
		var sprite = Sprite3D.new()
		sprite.texture = icon
		sprite.pixel_size = 0.002
		sprite.scale = Vector3(0.3, 0.3, 1)
		hand_display.add_child(sprite)
