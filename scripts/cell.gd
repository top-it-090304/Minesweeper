extends Panel
class_name MineCell

@onready var label: Label = $Label
@onready var shadow: Panel = $Shadow

var row: int = 0
var col: int = 0

func setup(r: int, c: int, size: int) -> void:
	row = r
	col = c
	custom_minimum_size = Vector2(size, size)
	label.add_theme_font_size_override("font_size", int(size * 0.6))

func show_closed() -> void:
	label.text = ""

func show_flag(font_size_mult: float = 0.5) -> void:
	label.text = "🚩"
	label.add_theme_font_size_override("font_size", int(custom_minimum_size.x * font_size_mult))

func show_mine(font_size_mult: float = 0.5) -> void:
	label.text = "💣"
	label.add_theme_font_size_override("font_size", int(custom_minimum_size.x * font_size_mult))

func show_number(val: int, color: Color) -> void:
	label.text = str(val)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", int(custom_minimum_size.x * 0.6))

func show_empty() -> void:
	label.text = ""

func set_revealed_style(style: StyleBox, shadow_style: StyleBox) -> void:
	add_theme_stylebox_override("panel", style)
	shadow.add_theme_stylebox_override("panel", shadow_style)

func set_hit_style(style: StyleBox) -> void:
	add_theme_stylebox_override("panel", style)
