extends RayCast3D

@export var interact_distance: float = 10.0

func _ready():
	# Ensure raycast is enabled
	enabled = true
	
	# Set the target position to point forward from camera
	target_position = Vector3(0, 0, -interact_distance)
	
	# Set collision mask to detect Items layer only (layer 4 = 1 << 3)
	collision_mask = 1 << 3
	
	print("InteractRay ready - enabled: ", enabled, ", mask: ", collision_mask, ", target_pos: ", target_position)


func _attempt_pickup() -> void:
	print("=== PICKUP ATTEMPT ===")
	print("Is enabled: ", enabled)
	print("Is colliding: ", is_colliding())
	
	if not is_colliding():
		print("InteractRay: Not colliding with anything")
		return
	
	var collider = get_collider()
	if collider == null:
		print("InteractRay: Collider is null")
		return
	
	print("InteractRay: Colliding with '", collider.name, "' (Type: ", collider.get_class(), ")")
	
	# Try to get item resource from the collider
	var item_resource = null
	
	# Direct property access (GDScript dynamic properties)
	if "item_resource" in collider:
		item_resource = collider.item_resource
		print("InteractRay: Found item_resource via direct property: ", item_resource)
	
	# If we found an item, add it to inventory and remove it
	if item_resource != null:
		print("InteractRay: Attempting to add item to hotbar")
		if HotBarManager.add_item_to_first_empty(item_resource):
			print("InteractRay: Item added successfully, removing pickup")
			collider.queue_free()
		else:
			print("InteractRay: Failed to add item to hotbar (inventory full?)")
	else:
		print("InteractRay: No item_resource found on collider")
