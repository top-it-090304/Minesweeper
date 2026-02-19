extends HBoxContainer
class_name LCDDisplay

## LCD-дисплей в стиле Windows XP Сапёра (красные цифры на чёрном фоне)

@export var digits: int = 3

static var lcd_bg: StyleBoxFlat = preload("res://resources/styles/lcd_background.tres")

var _labels: Array[Label] = []

func _ready():
	add_theme_stylebox_override("panel", lcd_bg)
	
	for i in digits:
		var lbl = Label.new()
		lbl.text = "0"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(20, 40)
		lbl.add_theme_color_override("font_color", Color(1, 0, 0))
		lbl.add_theme_font_size_override("font_size", 28)
		_labels.append(lbl)
		add_child(lbl)

func set_value(val: int):
	var s = "%0*d" % [digits, clampi(val, -99, 999)]
	for i in min(s.length(), _labels.size()):
		_labels[i].text = s[i]

func update_scale(scale_factor: float):
	for lbl in _labels:
		lbl.custom_minimum_size = Vector2(20 * scale_factor, 40 * scale_factor)
		lbl.add_theme_font_size_override("font_size", int(28 * scale_factor))
