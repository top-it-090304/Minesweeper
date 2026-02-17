extends Node
class_name XPTheme

## Цвета и стили в духе Windows XP Minesweeper

# Цвет фона
const BG_COLOR = Color(0.75, 0.75, 0.75)

# Рельефная рамка (вдавленная)
static func sunken_panel() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.75, 0.75, 0.75)
	s.border_width_top = 2
	s.border_width_left = 2
	s.border_width_bottom = 2
	s.border_width_right = 2
	s.set_border_color(Color(0.5, 0.5, 0.5))
	return s

# Рельефная рамка (выпуклая) — закрытая клетка
static func raised_cell(size: int) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.75, 0.75, 0.75)
	s.border_width_top = 2
	s.border_width_left = 2
	s.border_color = Color(1, 1, 1)
	return s

# Плоская клетка — открытая
static func flat_cell() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.78, 0.78, 0.78)
	s.border_width_top = 1
	s.border_width_left = 1
	s.border_color = Color(0.62, 0.62, 0.62)
	return s

# Красная клетка — мина, на которую наступили
static func red_cell() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(1, 0, 0)
	return s
