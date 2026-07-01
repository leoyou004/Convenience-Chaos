extends RigidBody3D

@export var item_name: String = "Beer Bottle"
@export var icon: Texture2D
@export var scene_file: PackedScene

func _ready():
	add_to_group("item")
	print("Item ready: ", name)
