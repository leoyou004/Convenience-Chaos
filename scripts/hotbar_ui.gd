extends HBoxContainer

# Updates the Hotbar UI when HotBarManager changes
@onready var slots_nodes := []

func _ready() -> void:
	# Cache TextureRect children
	for child in get_children():
		if child is TextureRect:
			slots_nodes.append(child)

	# Connect to hotbar manager signal
	if HotBarManager:
		HotBarManager.hotbar_updated.connect(_on_hotbar_updated)
		# Initialize UI from current state
		_on_hotbar_updated(HotBarManager.slots, HotBarManager.active_slot)

func _on_hotbar_updated(slots: Array, active_slot: int) -> void:
	for i in range(slots_nodes.size()):
		var node = slots_nodes[i]
		var item = null
		if i < slots.size():
			item = slots[i]
		# Clear default
		node.texture = null
		# If item has an `icon` Texture2D property, use it
		if item != null:
			var icon = null
			# Try to get an `icon` property safely
			if typeof(item) == TYPE_OBJECT:
				icon = item.get("icon") if item.has_method("get") else null
			if icon and icon is Texture2D:
				node.texture = icon
		# Highlight active slot
		if i == active_slot:
			node.modulate = Color(1, 1, 1, 1)
		else:
			node.modulate = Color(1, 1, 1, 0.6)
