extends HBoxContainer

@export var bottle_texture: Texture2D

func _ready() -> void:
	HotBarManager.hotbar_updated.connect(_on_hotbar_updated)
	_on_hotbar_updated(HotBarManager.slots, HotBarManager.active_slot)


func _on_hotbar_updated(slots: Array, active_slot: int) -> void:
	var slot_index := 0
	for child in get_children():
		if child is TextureRect:
			var item = slots[slot_index] if slot_index < slots.size() else null
			child.texture = item.get("icon") if item is Dictionary else null
			child.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			child.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			slot_index += 1
