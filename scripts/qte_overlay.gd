extends Control

var key_text: String = "E"
var timer_ratio: float = 1.0
var is_active: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(140, 140)
	anchors_preset = Control.PRESET_CENTER
	offset_left = -70
	offset_top = -70
	offset_right = 70
	offset_bottom = 70
	pivot_offset = size / 2.0
	modulate.a = 0.95

func set_state(active: bool, key: String, ratio: float) -> void:
	is_active = active
	key_text = key.to_upper()
	timer_ratio = clamp(ratio, 0.0, 1.0)
	queue_redraw()
	visible = active

func _draw() -> void:
	if not is_active:
		return

	var center: Vector2 = size / 2.0
	var radius: float = min(size.x, size.y) * 0.35
	var outline_color: Color = Color(1.0, 1.0, 1.0, 0.95)
	var fill_color: Color = Color(0.0, 0.0, 0.0, 0.35)
	var timer_color: Color = Color(1.0, 0.75, 0.1, 1.0)

	draw_circle(center, radius, fill_color)
	draw_arc(center, radius, 0.0, TAU, 48, outline_color, 3.0, true)
	draw_arc(center, radius, -PI / 2.0, -PI / 2.0 + TAU * timer_ratio, 48, timer_color, 6.0, true)

	var font: Font = get_theme_default_font()
	var text_size: Vector2 = font.get_string_size(key_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 36)
	draw_string(font, center - text_size / 2.0, key_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 36, Color.WHITE)
