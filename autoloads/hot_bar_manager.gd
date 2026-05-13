extends Node

signal hotbar_updated(slots: Array, active_slot: int)
signal active_slot_changed(active_slot: int)

const SLOT_COUNT := 3
const ITEM_PICKUP_SCRIPT := preload("res://scripts/item_pickup.gd")

var slots: Array[Resource] = [null, null, null]
var active_slot: int = 0

func _ready() -> void:
	emit_hotbar_updated()

func set_active_slot(slot_index: int) -> void:
	print("set_active_slot called: ", slot_index)
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return
	active_slot = slot_index
	active_slot_changed.emit(active_slot)
	emit_hotbar_updated()

func select_slot(slot_index: int) -> void:
	set_active_slot(slot_index)

func cycle_slot(direction: int) -> void:
	if direction == 0:
		return
	active_slot = posmod(active_slot + direction, SLOT_COUNT)
	active_slot_changed.emit(active_slot)
	emit_hotbar_updated()

func add_item_to_first_empty(item: Resource) -> bool:
	if item == null:
		return false
	for i in range(SLOT_COUNT):
		if slots[i] == null:
			slots[i] = item
			emit_hotbar_updated()
			return true
	return false

func get_active_item() -> Resource:
	return slots[active_slot]

func drop_active_item(player: Node3D) -> bool:
	if player == null:
		return false
	var item := slots[active_slot]
	if item == null:
		return false
	slots[active_slot] = null
	emit_hotbar_updated()

	var camera := player.get_node("CameraMount/Camera3D") as Camera3D
	var forward := -camera.global_transform.basis.z
	var drop_position := player.global_transform.origin + forward * 1.5
	drop_position.y += 0.5

	_spawn_physics_pickup(item, drop_position, Vector3.ZERO)
	return true

func throw_active_item(player: Node3D) -> bool:
	if player == null:
		return false
	var item := slots[active_slot]
	if item == null:
		return false
	slots[active_slot] = null
	emit_hotbar_updated()

	var camera := player.get_node("CameraMount/Camera3D") as Camera3D
	var forward := -camera.global_transform.basis.z
	var throw_position := player.global_transform.origin + forward * 0.5
	throw_position.y += 0.3

	if player.has_node("NoiseEmitter"):
		var noise_emitter = player.get_node("NoiseEmitter")
		noise_emitter.global_position = throw_position
		noise_emitter.show()
		var timer = get_tree().create_timer(0.1)
		await timer.timeout
		noise_emitter.hide()

	var rigid_body = _spawn_physics_pickup(item, throw_position, forward * 15.0)
	_wait_for_landing(rigid_body)
	return true

func emit_hotbar_updated() -> void:
	hotbar_updated.emit(slots.duplicate(), active_slot)

func _wait_for_landing(rigid_body: RigidBody3D) -> void:
	while is_instance_valid(rigid_body) and not rigid_body.is_queued_for_deletion():
		await get_tree().physics_frame
		if not is_instance_valid(rigid_body):
			return
		if rigid_body.linear_velocity.length() < 0.5:
			SignalBus.distraction_thrown.emit(rigid_body.global_position)
			return

func _spawn_physics_pickup(item: Resource, spawn_position: Vector3, velocity: Vector3) -> RigidBody3D:
	var rigid_body := RigidBody3D.new()
	rigid_body.name = "ThrownItem"

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.35
	shape.shape = sphere
	rigid_body.add_child(shape)

	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.25
	mesh.height = 0.5
	mesh_instance.mesh = mesh
	rigid_body.add_child(mesh_instance)

	var pickup := Area3D.new()
	pickup.set_script(ITEM_PICKUP_SCRIPT)
	pickup.name = "PickupArea"
	pickup.collision_layer = 1 << 1
	pickup.collision_mask = 1 << 0

	var pickup_shape := CollisionShape3D.new()
	var pickup_sphere := SphereShape3D.new()
	pickup_sphere.radius = 0.5
	pickup_shape.shape = pickup_sphere
	pickup.add_child(pickup_shape)

	pickup.set_meta("linked_body", rigid_body)
	rigid_body.set_meta("linked_pickup", pickup)

	get_tree().current_scene.add_child(rigid_body)
	rigid_body.global_position = spawn_position
	rigid_body.linear_velocity = velocity

	get_tree().current_scene.add_child(pickup)
	pickup.global_position = spawn_position
	pickup.item_resource = item

	return rigid_body
