extends Area3D

const ITEM_RESOURCE_PATH := "res://items/test_item.tres"
const ITEM_PICKUP_SCRIPT := preload("res://scripts/item_pickup.gd")
const SPAWN_COUNT := 3

func _ready() -> void:
	print("SPAWNER READY")
	_spawn_batch()

func _spawn_batch() -> void:
	for i in range(SPAWN_COUNT):
		_spawn_item()

func _spawn_item() -> void:
	var item = load(ITEM_RESOURCE_PATH)
	var spawn_position = _random_position_in_zone()
	print("SPAWNING ITEM AT: ", spawn_position)

	var rigid_body := RigidBody3D.new()
	rigid_body.name = "StockItem"
	rigid_body.collision_layer = 1
	rigid_body.collision_mask = 1

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.2
	shape.shape = sphere
	rigid_body.add_child(shape)

	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.2
	mesh.height = 0.4
	mesh_instance.mesh = mesh
	rigid_body.add_child(mesh_instance)

	var pickup := Area3D.new()
	pickup.set_script(ITEM_PICKUP_SCRIPT)
	pickup.name = "PickupArea"
	pickup.collision_layer = 1 << 1
	pickup.collision_mask = 1 << 0

	var pickup_shape := CollisionShape3D.new()
	var pickup_sphere := SphereShape3D.new()
	pickup_sphere.radius = 0.3
	pickup_shape.shape = pickup_sphere
	pickup.add_child(pickup_shape)

	pickup.set_meta("linked_body", rigid_body)
	rigid_body.set_meta("linked_pickup", pickup)

	get_tree().current_scene.add_child(rigid_body)
	rigid_body.global_position = spawn_position
	rigid_body.global_position.y += 1.0

	get_tree().current_scene.add_child(pickup)
	pickup.global_position = rigid_body.global_position
	pickup.item_resource = item

func _random_position_in_zone() -> Vector3:
	var shape = $CollisionShape3D.shape as BoxShape3D
	var extents = shape.size / 2.0
	var local_pos = Vector3(
		randf_range(-extents.x, extents.x),
		0,
		randf_range(-extents.z, extents.z)
	)
	return global_transform * local_pos

func spawn_one_more() -> void:
	_spawn_item()
