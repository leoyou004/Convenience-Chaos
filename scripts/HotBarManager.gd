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
	item.global_position = player.global_position + Vector3(0, 1, 0)

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
	var camera_mount = player.get_node("%CameraMount")
	item.global_position = player.global_position + Vector3(0, 1, 0)
	item.apply_impulse(-camera_mount.global_transform.basis.z * throw_force)
