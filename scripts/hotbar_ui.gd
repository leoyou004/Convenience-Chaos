extends HBoxContainer

@export var bottle_texture: Texture2D

func _ready() -> void:
	for child in get_children():
		if child is TextureRect:
			child.texture = bottle_texture
			child.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			child.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	print("TEXTURE SET: ", bottle_texture)
