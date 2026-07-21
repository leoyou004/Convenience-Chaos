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
			print("slot ", i, " filled with ", slots[i].name)
			hotbar_updated.emit(slots, active_slot)
			return
	print("all slots full")

func set_active_slot(index: int) -> void:
	if index < MAX_SLOTS:
		active_slot = index
		hotbar_updated.emit(slots, active_slot)

func cycle_slot(direction: int) -> void:
	active_slot = wrapi(active_slot + direction, 0, MAX_SLOTS)
	hotbar_updated.emit(slots, active_slot)

func drop_active_item(player: Node) -> void:
	if slots[active_slot] == null:
		return
		
	var item_data = slots[active_slot]
	slots[active_slot] = null
	hotbar_updated.emit(slots, active_slot)
	
	if item_data.scene_file == null:
		return
		
	var item = item_data.scene_file.instantiate()
	player.get_tree().current_scene.add_child(item)
	
	# Drop the item slightly in front of the player so they don't step on it
	var forward_drop = -player.global_transform.basis.z * 1.0
	item.global_position = player.global_position + Vector3(0, 1, 0) + forward_drop

func throw_active_item(player: Node) -> void:
	if slots[active_slot] == null:
		return
		
	var item_data = slots[active_slot]
	slots[active_slot] = null
	hotbar_updated.emit(slots, active_slot)
	
	if item_data.scene_file == null:
		return
		
	var item = item_data.scene_file.instantiate()
	player.get_tree().current_scene.add_child(item)
	
	# Get the exact direction the camera is looking
	var camera = player.camera
	var look_direction = -camera.global_transform.basis.z.normalized()
	
	# Spawn distance in front of the camera
	var spawn_distance = 1.5
	item.global_position = camera.global_position + (look_direction * spawn_distance)
	
	# Check if it's a physics body, ignore the player's collision, and throw it
	if item is RigidBody3D:
		item.add_collision_exception_with(player)
		# Using apply_central_impulse is usually better for throwing so it doesn't spin wildly
		item.apply_central_impulse(look_direction * throw_force)
