extends RigidBody3D

@export var item_name: String = "Beer Bottle"
@export var icon: Texture2D
@export var scene_file: PackedScene

var has_landed: bool = false
var time_since_thrown: float = 0.0

func _ready():
	add_to_group("item")
	
	# Automatically set scene_file to this scene if not already set
	if scene_file == null:
		scene_file = load(get_scene_file_path())
	
	print("Item ready: ", name)
	print("Scene file: ", scene_file)

func _process(delta: float) -> void:
	time_since_thrown += delta
	
	# Check if item has slowed down significantly (has landed)
	# Give it a moment to settle, then check velocity
	if not has_landed and time_since_thrown > 0.3 and linear_velocity.length() < 0.5:
		has_landed = true
		SignalBus.item_landed.emit(global_position)
		print("Item landed at: ", global_position)
