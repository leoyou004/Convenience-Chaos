extends Area3D

@export var item_resource: Resource
@export var player_layer_bit: int = 0
const DEFAULT_ITEM_RESOURCE_PATH := "res://items/test_item.tres"
var _picked_up: bool = false

func _ready() -> void:
	item_resource = load(DEFAULT_ITEM_RESOURCE_PATH)
	print("item_resource at START of ready: ", item_resource)
	monitoring = true
	monitorable = true
	if collision_layer == 0:
		collision_layer = 1 << player_layer_bit
	if collision_mask == 0:
		collision_mask = 1 << player_layer_bit
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_update_label()
	print("=== PickupArea ready ===")
	print("item_resource: ", item_resource)
	print("collision_layer: ", collision_layer)
	print("collision_mask: ", collision_mask)
	print("monitoring: ", monitoring)
	print("body_entered connected: ", body_entered.is_connected(_on_body_entered))

func _on_body_entered(body: Node) -> void:
	print("BODY ENTERED: ", body.name if body != null else "null")
	if _picked_up:
		return
	if body == null or not body.is_in_group("player"):
		print("FAILED GROUP CHECK - groups: ", body.get_groups())
		return
	if item_resource == null:
		print("item_resource is null, cannot pick up")
		return
	print("Attempting to add to hotbar...")
	if HotBarManager.add_item_to_first_empty(item_resource):
		print("Pickup success!")
		_picked_up = true
		_free_pickup_root()
	else:
		print("HotBarManager returned false - hotbar may be full")

func _update_label() -> void:
	if not has_node("Label3D"):
		return
	var label := get_node("Label3D") as Label3D
	if label == null:
		return
	if item_resource == null:
		label.text = ""
		return
	var item_name_value: Variant = item_resource.get("name") if item_resource.has_method("get") else null
	if item_name_value is String and item_name_value != "":
		label.text = item_name_value
	else:
		label.text = "Item"

func _free_pickup_root() -> void:
	var parent_node: Node = get_parent()
	if parent_node != null and parent_node.name == "ItemPickup" and parent_node is Node3D:
		parent_node.queue_free()
		return
	queue_free()
