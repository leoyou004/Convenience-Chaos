extends Node
 
signal hotbar_updated(slots: Array, active_slot: int)
signal active_slot_changed(active_slot: int)
 
const SLOT_COUNT := 3
 
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
 
	# Instance the item's real visual + pickup scene (e.g. item_pickup.tscn with BeerBottle_SM)
	var pickup_scene: PackedScene = item.get("pickup_scene") if item.has_method("get") else null
	var visual_root: Node3D = null
 
	if pickup_scene:
		visual_root = pickup_scene.instantiate()
		rigid_body.add_child(visual_root)
		# The instanced scene's own Area3D (pickup trigger) needs to know which body it's attached to
		if visual_root.has_meta("linked_body") or visual_root.has_method("set_meta"):
			visual_root.set_meta("linked_body", rigid_body)
		rigid_body.set_meta("linked_pickup", visual_root)
	else:
		# Fallback if no scene assigned: keep a small visible marker so it's not invisible,
		# but warn so it's obvious the resource needs a pickup_scene assigned.
		push_warning("ItemResource '%s' has no pickup_scene assigned — using fallback box." % str(item.get("name")))
		var mesh_instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.2, 0.2, 0.2)
		mesh_instance.mesh = box
		rigid_body.add_child(mesh_instance)
 
	# Build a collision shape sized to the actual visual, instead of a hardcoded sphere
	var collision_shape := CollisionShape3D.new()
	var aabb := _get_visual_aabb(visual_root) if visual_root else AABB(Vector3.ZERO, Vector3(0.2, 0.2, 0.2))
	var shape := BoxShape3D.new()
	# Use the real mesh size (with a tiny margin) so physics matches the model, not a generic sphere
	shape.size = aabb.size if aabb.size.length() > 0.01 else Vector3(0.2, 0.2, 0.2)
	collision_shape.shape = shape
	# Center the collision shape on the visual's bounding box center, since meshes aren't always centered on origin
	collision_shape.position = aabb.get_center()
	rigid_body.add_child(collision_shape)
 
	get_tree().current_scene.add_child(rigid_body)
	rigid_body.global_position = spawn_position
	rigid_body.linear_velocity = velocity
 
	return rigid_body
 
func _get_visual_aabb(node: Node3D) -> AABB:
	# Recursively combine AABBs of all MeshInstance3D children to get the real visual bounds
	var combined := AABB()
	var first := true
	for child in _get_all_mesh_instances(node):
		var mesh_aabb: AABB = child.get_aabb()
		# Transform into the parent's local space
		mesh_aabb = child.transform * mesh_aabb
		if first:
			combined = mesh_aabb
			first = false
		else:
			combined = combined.merge(mesh_aabb)
	return combined
 
func _get_all_mesh_instances(node: Node) -> Array:
	var result: Array = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result += _get_all_mesh_instances(child)
	return result
 
