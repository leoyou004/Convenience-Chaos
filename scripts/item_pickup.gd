extends Area3D

@export var item_resource: Resource

func _ready() -> void:
	# Store item resource as metadata for raycast interaction
	if item_resource:
		set_meta("item_resource", item_resource)
