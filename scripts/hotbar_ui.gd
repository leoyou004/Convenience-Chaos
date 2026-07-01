extends HBoxContainer

@onready var slots_nodes := []

func _ready() -> void:
	for child in get_children():
		if child is TextureRect:
			slots_nodes.append(child)
	print("HotBarUI ready, slots_nodes count: ", slots_nodes.size())
	print("connected to HotBarManager: ", HotBarManager.hotbar_updated.is_connected(_on_hotbar_updated))
	if HotBarManager:
		HotBarManager.hotbar_updated.connect(_on_hotbar_updated)
		_on_hotbar_updated(HotBarManager.slots, HotBarManager.active_slot)

func _on_hotbar_updated(slots: Array, active_slot: int) -> void:
	print("hotbar_updated received")
	for i in range(slots_nodes.size()):
		var node = slots_nodes[i]
		var item = null
		if i < slots.size():
			item = slots[i]
		node.texture = null
		if item != null:
			var icon = item.get("icon")
			if icon and icon is Texture2D:
				node.texture = icon
				node.modulate = Color(1, 1, 1, 1)
			else:
				node.modulate = Color(1, 1, 0, 1)
		else:
			node.modulate = Color(1, 1, 1, 0.6)
		if i == active_slot and item == null:
			node.modulate = Color(1, 1, 1, 1)
