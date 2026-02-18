extends Panel
class_name MineCell

@onready var label: Label = $Label
@onready var shadow: Panel = $Shadow
@onready var sprite: TextureRect = $Sprite

static var bomb_tex: Texture2D = preload("res://assets/sprites/bomb.png")
static var flag_tex: Texture2D = preload("res://assets/sprites/flag.png")

static var style_closed: StyleBoxFlat = preload("res://resources/styles/closed_cell.tres")
static var style_closed_shadow: StyleBoxFlat = preload("res://resources/styles/closed_cell_shadow.tres")
static var style_opened: StyleBoxFlat = preload("res://resources/styles/opened_cell.tres")
static var style_opened_shadow: StyleBoxFlat = preload("res://resources/styles/opened_cell_shadow.tres")
static var style_red: StyleBoxFlat = preload("res://resources/styles/red_cell.tres")

var row: int = 0
var col: int = 0

func setup(r: int, c: int, size: int) -> void:
	row = r
	col = c
	custom_minimum_size = Vector2(size, size)
	label.add_theme_font_size_override("font_size", int(size * 0.6))
	add_theme_stylebox_override("panel", style_closed)
	shadow.add_theme_stylebox_override("panel", style_closed_shadow)

func _clear_display() -> void:
	label.text = ""
	sprite.texture = null

func show_closed() -> void:
	_clear_display()

func show_flag() -> void:
	_clear_display()
	sprite.texture = flag_tex

func show_mine() -> void:
	_clear_display()
	sprite.texture = bomb_tex

func show_number(val: int, color: Color) -> void:
	_clear_display()
	label.text = str(val)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", int(custom_minimum_size.x * 0.6))

func show_empty() -> void:
	_clear_display()

func set_revealed_style() -> void:
	add_theme_stylebox_override("panel", style_opened)
	shadow.add_theme_stylebox_override("panel", style_opened_shadow)

func set_hit_style() -> void:
	add_theme_stylebox_override("panel", style_red)
