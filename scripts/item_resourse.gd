extends Resource
class_name ItemResource
 
@export var name: String = "Item"
@export var icon: Texture2D
@export var pickup_scene: PackedScene  # The actual 3D scene to spawn when dropped/thrown (e.g. item_pickup.tscn)
@export var throw_radius: float = 0.3  # Approximate collision radius for the thrown physics body
 
