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

	var drop_position := player.global_transform.origin + (-player.global_transform.basis.z * 1.5)
	drop_position.y += 0.5

	if not _spawn_item_scene_from_resource(item, drop_position):
		_spawn_fallback_pickup(item, drop_position)

	return true

func throw_active_item(player: Node3D) -> bool:
	if player == null:
		return false

	var item := slots[active_slot]
	if item == null:
		return false

	slots[active_slot] = null
	emit_hotbar_updated()

	var throw_position := player.global_transform.origin + (-player.global_transform.basis.z * 0.5)
	throw_position.y += 0.3

	# Emit noise when throwing
	if player.has_node("NoiseEmitter"):
		var noise_emitter = player.get_node("NoiseEmitter")
		noise_emitter.global_position = throw_position
		noise_emitter.show()
		var timer = get_tree().create_timer(0.1)
		await timer.timeout
		noise_emitter.hide()

	# Throw with velocity
	if not _spawn_item_scene_from_resource(item, throw_position):
		_spawn_fallback_pickup_with_velocity(item, throw_position, player.global_transform.basis.z * -15.0)

	return true

func emit_hotbar_updated() -> void:
	hotbar_updated.emit(slots.duplicate(), active_slot)

func _spawn_item_scene_from_resource(item: Resource, drop_position: Vector3) -> bool:
	if item == null:
		return false

	# Supports custom item resources that expose a drop or pickup scene.
	var scene_candidates := ["drop_scene", "pickup_scene", "world_scene"]
	for property_name in scene_candidates:
		if item.get(property_name) is PackedScene:
			var scene: PackedScene = item.get(property_name)
			var instance := scene.instantiate()
			if instance is Node3D:
				instance.global_position = drop_position
				get_tree().current_scene.add_child(instance)
				return true

	return false

func _spawn_fallback_pickup(item: Resource, drop_position: Vector3) -> void:
	var pickup := Area3D.new()
	pickup.name = "ItemPickup"
	pickup.monitoring = true
	pickup.monitorable = true
	pickup.collision_layer = 1 << 3
	pickup.collision_mask = 1 << 0
	pickup.set_script(ITEM_PICKUP_SCRIPT)
	pickup.item_resource = item

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.35
	shape.shape = sphere
	pickup.add_child(shape)

	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.25
	mesh.height = 0.5
	mesh_instance.mesh = mesh
	pickup.add_child(mesh_instance)

	get_tree().current_scene.add_child(pickup)
	pickup.global_position = drop_position

func _spawn_fallback_pickup_with_velocity(item: Resource, spawn_position: Vector3, velocity: Vector3) -> void:
	var pickup := Area3D.new()
	pickup.name = "ItemPickup"
	pickup.monitoring = true
	pickup.monitorable = true
	pickup.collision_layer = 1 << 3
	pickup.collision_mask = 1 << 0
	pickup.set_script(ITEM_PICKUP_SCRIPT)
	pickup.item_resource = item

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.35
	shape.shape = sphere
	pickup.add_child(shape)

	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.25
	mesh.height = 0.5
	mesh_instance.mesh = mesh
	pickup.add_child(mesh_instance)

	get_tree().current_scene.add_child(pickup)
	pickup.global_position = spawn_position

	# Add RigidBody physics to the thrown item
	var rigid_body := RigidBody3D.new()
	rigid_body.name = "ThrownItem"
	var rigid_shape := CollisionShape3D.new()
	var rigid_sphere := SphereShape3D.new()
	rigid_sphere.radius = 0.35
	rigid_shape.shape = rigid_sphere
	rigid_body.add_child(rigid_shape)
	
	var rigid_mesh := MeshInstance3D.new()
	var rigid_mesh_inst := SphereMesh.new()
	rigid_mesh_inst.radius = 0.25
	rigid_mesh_inst.height = 0.5
	rigid_mesh.mesh = rigid_mesh_inst
	rigid_body.add_child(rigid_mesh)
	
	rigid_body.global_position = spawn_position
	rigid_body.linear_velocity = velocity
	get_tree().current_scene.add_child(rigid_body)
	
	# Remove after 2 seconds
	var timer = get_tree().create_timer(2.0)
	await timer.timeout
	if rigid_body and not rigid_body.is_queued_for_deletion():
		rigid_body.queue_free()
