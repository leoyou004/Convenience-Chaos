extends Area3D

@export var item_resource: Resource
@export var player_layer_bit: int = 0
const DEFAULT_ITEM_RESOURCE_PATH := "res://items/test_item.tres"
var _picked_up: bool = false
var _has_landed: bool = false

func _ready() -> void:
	monitoring = false
	monitorable = false
	if item_resource == null and ResourceLoader.exists(DEFAULT_ITEM_RESOURCE_PATH):
		item_resource = load(DEFAULT_ITEM_RESOURCE_PATH)
	collision_layer = 1 << 1
	collision_mask = 1 << 0
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_update_label()
	await get_tree().create_timer(0.5).timeout
	monitoring = true
	monitorable = true
	print("SPAWNED PICKUP READY - layer: ", collision_layer, " mask: ", collision_mask, " monitoring: ", monitoring, " item: ", item_resource)

func _process(_delta: float) -> void:
	if has_meta("linked_body"):
		var body = get_meta("linked_body")
		if is_instance_valid(body):
			var was_moving = not _has_landed
			global_position = body.global_position
			# Detect when the thrown item has landed by checking if body stopped
			if was_moving and body is RigidBody3D:
				if body.linear_velocity.length() < 0.5:
					_has_landed = true
					SignalBus.distraction_thrown.emit(global_position)

func _on_body_entered(body: Node) -> void:
	print("PICKUP TRIGGERED: ", body.name)
	if _picked_up:
		print("already picked up")
		return
	if body == null or not body.is_in_group("player"):
		print("not player, groups: ", body.get_groups())
		return
	if item_resource == null:
		print("item_resource null")
		return
	print("adding to hotbar...")
	if HotBarManager.add_item_to_first_empty(item_resource):
		print("success")
		_picked_up = true
		_free_pickup_root()
	else:
		print("hotbar full")

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
	if has_meta("linked_body"):
		var body = get_meta("linked_body")
		if is_instance_valid(body):
			body.queue_free()
	queue_free()
