extends Node

signal hotbar_updated(slots, active_slot)

const MAX_SLOTS = 3

var slots: Array = [null, null, null]
var active_slot: int = 0
var throw_force: float = 12.0

func _ready() -> void:
	hotbar_updated.emit(slots.duplicate(), active_slot)

func pick_up_item(item: Node) -> bool:
	if item == null:
		print("PICKUP FAILED: item is null")
		return false

	for i in MAX_SLOTS:
		if slots[i] == null:
			slots[i] = {
				"name": item.get("item_name") if "item_name" in item else "Item",
				"icon": item.get("icon"),
				"scene_file": item.get("scene_file")
			}

			item.queue_free()
			print("Slot ", i, " filled with ", slots[i]["name"])
			hotbar_updated.emit(slots.duplicate(), active_slot)
			return true

	print("All slots full")
	return false

func add_item_to_first_empty(item_data: Variant) -> bool:
	if item_data is Node:
		return pick_up_item(item_data)
	return false

func clear_inventory() -> void:
	slots = [null, null, null]
	active_slot = 0
	hotbar_updated.emit(slots.duplicate(), active_slot)

func set_active_slot(index: int) -> void:
	if index >= 0 and index < MAX_SLOTS:
		active_slot = index
		hotbar_updated.emit(slots.duplicate(), active_slot)

func cycle_slot(direction: int) -> void:
	active_slot = wrapi(active_slot + direction, 0, MAX_SLOTS)
	hotbar_updated.emit(slots.duplicate(), active_slot)

func drop_active_item(player: Node3D) -> void:
	if slots[active_slot] == null:
		print("DROP FAILED: No item in active slot")
		return

	var item_data = slots[active_slot]
	slots[active_slot] = null
	hotbar_updated.emit(slots.duplicate(), active_slot)

	var scene_file = item_data["scene_file"]
	if scene_file == null:
		print("DROP FAILED: scene_file is NULL")
		return

	if scene_file is String:
		scene_file = load(scene_file)

	if not scene_file is PackedScene:
		print("DROP FAILED: scene_file is not a PackedScene")
		return

	var item = scene_file.instantiate()
	if item == null:
		print("DROP FAILED: Could not instantiate item")
		return

	player.get_tree().current_scene.add_child(item)
	var forward_drop = -player.global_transform.basis.z.normalized()

	if item is Node3D:
		item.global_position = (
			player.global_position
			+ Vector3(0, 1, 0)
			+ forward_drop
		)

	print("ITEM DROPPED: ", item.name)

func throw_active_item(player: Node3D) -> void:
	if slots[active_slot] == null:
		print("THROW FAILED: No item in active slot")
		return

	var item_data = slots[active_slot]
	var scene_file = item_data["scene_file"]

	if scene_file == null:
		print("THROW FAILED: scene_file is NULL")
		return

	if scene_file is String:
		scene_file = load(scene_file)

	if not scene_file is PackedScene:
		print("THROW FAILED: scene_file is not a PackedScene")
		print("scene_file is: ", scene_file)
		return

	slots[active_slot] = null
	hotbar_updated.emit(slots.duplicate(), active_slot)

	var item = scene_file.instantiate()
	if item == null:
		print("THROW FAILED: Could not instantiate item")
		return

	player.get_tree().current_scene.add_child(item)
	print("ITEM SPAWNED: ", item.name)

	var camera = player.camera
	var throw_direction = -camera.global_transform.basis.z.normalized()
	var spawn_position = camera.global_position + throw_direction * 2.0

	if item is Node3D:
		item.global_position = spawn_position
		SignalBus.distraction_thrown.emit(item.global_position)
		print("ITEM POSITION: ", item.global_position)

	if item is RigidBody3D:
		item.add_collision_exception_with(player)
		item.linear_velocity = throw_direction * throw_force
		print("ITEM THROWN!")
	else:
		print("WARNING: Item is NOT a RigidBody3D")
