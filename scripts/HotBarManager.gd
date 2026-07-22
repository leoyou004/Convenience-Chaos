extends Node

signal hotbar_updated(slots, active_slot)

const MAX_SLOTS = 3

var slots: Array = [null, null, null]
var active_slot: int = 0
var throw_force: float = 12.0


func pick_up_item(item: Node) -> void:
	for i in MAX_SLOTS:
		if slots[i] == null:
			slots[i] = {
				"name": item.item_name,
				"icon": item.icon,
				"scene_file": item.scene_file
			}

			item.queue_free()

			print("Slot ", i, " filled with ", slots[i]["name"])

			hotbar_updated.emit(slots, active_slot)
			return

	print("All slots full")


func set_active_slot(index: int) -> void:
	if index >= 0 and index < MAX_SLOTS:
		active_slot = index
		hotbar_updated.emit(slots, active_slot)


func cycle_slot(direction: int) -> void:
	active_slot = wrapi(active_slot + direction, 0, MAX_SLOTS)
	hotbar_updated.emit(slots, active_slot)


func drop_active_item(player: Node3D) -> void:
	if slots[active_slot] == null:
		print("DROP FAILED: No item in active slot")
		return

	var item_data = slots[active_slot]

	# Remove item from hotbar
	slots[active_slot] = null
	hotbar_updated.emit(slots, active_slot)

	# Get scene file
	var scene_file = item_data["scene_file"]

	if scene_file == null:
		print("DROP FAILED: scene_file is NULL")
		return

	# If scene_file is a String, load it
	if scene_file is String:
		scene_file = load(scene_file)

	# Check if it is a PackedScene
	if not scene_file is PackedScene:
		print("DROP FAILED: scene_file is not a PackedScene")
		return

	# Spawn item
	var item = scene_file.instantiate()

	if item == null:
		print("DROP FAILED: Could not instantiate item")
		return

	player.get_tree().current_scene.add_child(item)

	# Drop item in front of player
	var forward_drop = -player.global_transform.basis.z.normalized()

	if item is Node3D:
		item.global_position = (
			player.global_position
			+ Vector3(0, 1, 0)
			+ forward_drop
		)

	print("ITEM DROPPED: ", item.name)


func throw_active_item(player: Node3D) -> void:
	# Check if there is an item in the active slot
	if slots[active_slot] == null:
		print("THROW FAILED: No item in active slot")
		return

	var item_data = slots[active_slot]

	# Get the scene from the dictionary
	var scene_file = item_data["scene_file"]

	if scene_file == null:
		print("THROW FAILED: scene_file is NULL")
		return

	# If scene_file is a file path, load it
	if scene_file is String:
		scene_file = load(scene_file)

	# Make sure we have a PackedScene
	if not scene_file is PackedScene:
		print("THROW FAILED: scene_file is not a PackedScene")
		print("scene_file is: ", scene_file)
		return

	# Remove item from hotbar
	slots[active_slot] = null
	hotbar_updated.emit(slots, active_slot)

	# CREATE THE ITEM
	var item = scene_file.instantiate()

	if item == null:
		print("THROW FAILED: Could not instantiate item")
		return

	# ADD ITEM TO THE WORLD
	player.get_tree().current_scene.add_child(item)

	print("ITEM SPAWNED: ", item.name)

	# Get camera
	var camera = player.camera

	# Get the direction the camera is looking
	var throw_direction = -camera.global_transform.basis.z.normalized()

	# Spawn 2 meters in front of camera
	var spawn_position = (
		camera.global_position
		+ throw_direction * 2.0
	)

	# Set item position
	if item is Node3D:
		item.global_position = spawn_position

		print("ITEM POSITION: ", item.global_position)

	# Throw item
	if item is RigidBody3D:
		# Prevent item from immediately colliding with player
		item.add_collision_exception_with(player)

		# Apply throw velocity
		item.linear_velocity = throw_direction * throw_force

		print("ITEM THROWN!")

	else:
		print("WARNING: Item is NOT a RigidBody3D")
