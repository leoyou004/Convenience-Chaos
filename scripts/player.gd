extends CharacterBody3D

@onready var camera_mount = %CameraMount
@onready var camera = %CameraMount/Camera3D
@onready var collision_shape = $CollisionShape3D
@onready var footsteps = $"CollisionShape3D/Footsteps"
@onready var pickup_area: Area3D = $PickupArea

var speed = 5.0
var sprint_speed = 8.0
var crouch_speed = 2.5
var current_speed = speed
var mouse_sensitivity = 0.002
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var max_stamina: float = 1.0
var stamina: float = max_stamina

var is_crouching = false
var is_dead = false
var step_timer = 0.0
var nearby_item: Node = null

const STEP_INTERVAL_WALK := 0.45
const STEP_INTERVAL_SPRINT := 0.28
const STEP_INTERVAL_CROUCH := 0.6
const JUMP_VELOCITY := 3.0
const STAMINA_DRAIN := 0.35
const STAMINA_REGEN := 0.22

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	add_to_group("Player")
	SignalBus.player_caught.connect(_on_player_caught)
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)
	SignalBus.sprint_stamina_changed.emit(stamina, max_stamina)
	print("PickupArea mask: ", pickup_area.collision_mask)
	# Ensure mouse stays locked during gameplay
	get_window().gui_focus_changed.connect(_on_gui_focus_changed)

func _input(event):
	if is_dead:
		return
	if event is InputEventMouseMotion:
		camera_mount.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)

func _process(_delta):
	# Ensure mouse stays locked during active gameplay
	if not is_dead and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if is_dead:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			HotBarManager.cycle_slot(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			HotBarManager.cycle_slot(-1)

	if event.is_action_pressed("interact"):
		if nearby_item:
			print("picking up: ", nearby_item.name)
			HotBarManager.pick_up_item(nearby_item)
			nearby_item = null
		else:
			print("interact pressed but no nearby_item")

	if event.is_action_pressed("drop_item"):
		HotBarManager.drop_active_item(self)

	if event.is_action_pressed("throw_item"):
		HotBarManager.throw_active_item(self)

	if event.is_action_pressed("slot_1"):
		HotBarManager.set_active_slot(0)
	if event.is_action_pressed("slot_2"):
		HotBarManager.set_active_slot(1)
	if event.is_action_pressed("slot_3"):
		HotBarManager.set_active_slot(2)

func _physics_process(delta):
	if is_dead:
		return

	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction = (camera_mount.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY

	var is_moving = input_dir.length_squared() > 0.01
	var wants_to_sprint = Input.is_action_pressed("sprint") and not is_crouching and is_moving
	if wants_to_sprint and stamina > 0.0:
		current_speed = sprint_speed
		stamina = max(0.0, stamina - delta * STAMINA_DRAIN)
	elif is_crouching:
		current_speed = crouch_speed
		stamina = min(max_stamina, stamina + delta * STAMINA_REGEN)
	else:
		current_speed = speed
		stamina = min(max_stamina, stamina + delta * STAMINA_REGEN)

	if Input.is_action_just_pressed("crouch"):
		is_crouching = not is_crouching

	SignalBus.sprint_stamina_changed.emit(stamina, max_stamina)
	move_and_slide()
	_handle_footsteps(wants_to_sprint and stamina > 0.0, delta)

func _handle_footsteps(sprinting: bool, delta: float) -> void:
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.5
	if is_moving and is_on_floor():
		var interval = STEP_INTERVAL_WALK
		if sprinting:
			interval = STEP_INTERVAL_SPRINT
		elif is_crouching:
			interval = STEP_INTERVAL_CROUCH
		step_timer -= delta
		if step_timer <= 0.0:
			step_timer = interval
			footsteps.play()
	else:
		step_timer = 0.0
		footsteps.stop()

func _on_pickup_area_body_entered(body: Node) -> void:
	print("body entered pickup area: ", body.name)
	if body.is_in_group("item"):
		nearby_item = body
		print("nearby_item set: ", body.name)
	else:
		print("body not in item group: ", body.get_groups())

func _on_pickup_area_body_exited(body: Node) -> void:
	if body == nearby_item:
		nearby_item = null

func _on_player_caught() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	if HotBarManager != null:
		HotBarManager.clear_inventory()
	SignalBus.sprint_stamina_changed.emit(0.0, max_stamina)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var tween = create_tween()
	tween.set_parallel(false)
	tween.tween_property(camera, "rotation:z", PI / 2, 0.5)
	tween.tween_property(camera_mount, "rotation:x", PI / 4, 0.3)
	tween.tween_callback(func(): SignalBus.player_died.emit())

func _on_gui_focus_changed(_new_focus: Control) -> void:
	# Maintain mouse lock even when GUI focus changes
	if not is_dead:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
