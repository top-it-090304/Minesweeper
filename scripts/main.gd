extends Control

const CellScene = preload("res://scenes/cell.tscn")

var face_normal_tex: Texture2D = preload("res://assets/sprites/face_normal.png")
var face_dead_tex: Texture2D = preload("res://assets/sprites/face_dead.png")
var face_cool_tex: Texture2D = preload("res://assets/sprites/face_cool.png")

# --- Настройки поля ---
var rows: int = 9
var cols: int = 9
var mine_count: int = 10

# --- Состояние игры ---
var field: Array = []        # 2D: -1 = мина, 0..8 = число соседних мин
var revealed: Array = []     # 2D: bool
var flagged: Array = []      # 2D: bool
var game_started: bool = false
var game_over: bool = false
var elapsed_time: int = 0
var flags_placed: int = 0
var cells_revealed: int = 0

# --- Тач ---
var long_press_time: float = 0.4
var chord_press_time: float = 1.2
var press_start_time: float = -1.0
var press_cell: Vector2i = Vector2i(-1, -1)
var press_handled: bool = false

# --- Узлы ---
@onready var grid: GridContainer = $FieldContainer/Field
@onready var mine_counter: LCDDisplay = $TopPanel/MineCounter
@onready var timer_label: LCDDisplay = $TopPanel/TimerLabel
@onready var face_button: Button = $TopPanel/FaceButton
@onready var game_timer: Timer = $GameTimer
@onready var difficulty_panel: VBoxContainer = $DifficultyPanel
@onready var top_panel: HBoxContainer = $TopPanel
@onready var easy_btn: Button = $DifficultyPanel/EasyBtn
@onready var medium_btn: Button = $DifficultyPanel/MediumBtn
@onready var hard_btn: Button = $DifficultyPanel/HardBtn

# --- Размеры клеток ---
var cell_size: int = 40

# --- Цвета цифр (как в XP) ---
var number_colors = {
	1: Color(0, 0, 1),        # синий
	2: Color(0, 0.5, 0),      # зелёный
	3: Color(1, 0, 0),        # красный
	4: Color(0, 0, 0.5),      # тёмно-синий
	5: Color(0.5, 0, 0),      # тёмно-красный
	6: Color(0, 0.5, 0.5),    # бирюзовый
	7: Color(0, 0, 0),        # чёрный
	8: Color(0.5, 0.5, 0.5),  # серый
}

func _ready():
	Engine.max_fps = 60
	process_mode = Node.PROCESS_MODE_PAUSABLE
	face_button.pressed.connect(_on_face_pressed)
	game_timer.timeout.connect(_on_timer_timeout)
	easy_btn.pressed.connect(func(): _start_game(9, 9, 10))
	medium_btn.pressed.connect(func(): _start_game(16, 16, 40))
	hard_btn.pressed.connect(func(): _start_game(16, 30, 99))
	_show_difficulty_menu()

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Engine.max_fps = 1
		if game_started and !game_over:
			game_timer.paused = true
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		Engine.max_fps = 60
		if game_started and !game_over:
			game_timer.paused = false

func _show_difficulty_menu():
	difficulty_panel.visible = true
	grid.visible = false
	top_panel.visible = false

func _start_game(c: int, r: int, m: int):
	cols = c
	rows = r
	mine_count = m
	difficulty_panel.visible = false
	grid.visible = true
	top_panel.visible = true
	_new_game()

func _new_game():
	game_started = false
	game_over = false
	elapsed_time = 0
	flags_placed = 0
	cells_revealed = 0
	press_start_time = -1.0
	game_timer.stop()
	
	_update_mine_counter()
	_update_timer()
	face_button.text = ""
	face_button.icon = face_normal_tex
	
	# Расчёт размера клетки по размеру экрана
	var screen_size = get_viewport().get_visible_rect().size
	var available_width = screen_size.x - 20  # отступы
	var available_height = screen_size.y - 130  # верхняя панель + отступы
	var cw = available_width / cols
	var ch = available_height / rows
	cell_size = int(min(cw, ch))
	if cell_size < 24:
		cell_size = 24
	
	# Инициализация массивов
	field.clear()
	revealed.clear()
	flagged.clear()
	for r in rows:
		field.append([])
		revealed.append([])
		flagged.append([])
		for c in cols:
			field[r].append(0)
			revealed[r].append(false)
			flagged[r].append(false)
	
	_build_grid()

func _build_grid():
	# Очистка
	for child in grid.get_children():
		child.queue_free()
	
	grid.columns = cols
	
	for r in rows:
		for c in cols:
			var cell = CellScene.instantiate() as MineCell
			cell.setup(r, c, cell_size)
			grid.add_child(cell)

func _place_mines(first_r: int, first_c: int):
	# Расставляем мины, избегая первого клика и его соседей
	var safe = []
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			safe.append(Vector2i(first_c + dc, first_r + dr))
	
	var placed = 0
	while placed < mine_count:
		var r = randi() % rows
		var c = randi() % cols
		if Vector2i(c, r) in safe:
			continue
		if field[r][c] == -1:
			continue
		field[r][c] = -1
		placed += 1
	
	# Считаем числа
	for r in rows:
		for c in cols:
			if field[r][c] == -1:
				continue
			var count = 0
			for dr in range(-1, 2):
				for dc in range(-1, 2):
					var nr = r + dr
					var nc = c + dc
					if nr >= 0 and nr < rows and nc >= 0 and nc < cols:
						if field[nr][nc] == -1:
							count += 1
			field[r][c] = count

func _input(event):
	if game_over:
		return
	
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var is_press = false
		var is_release = false
		var is_double = false
		var pos = Vector2.ZERO
		
		if event is InputEventScreenTouch:
			is_press = event.pressed
			is_release = !event.pressed
			is_double = event.double_tap if event is InputEventScreenTouch else false
			pos = event.position
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			is_press = event.pressed
			is_release = !event.pressed
			is_double = event.double_click
			pos = event.position
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				var rc = _get_cell_at(event.position)
				if rc.x >= 0:
					_toggle_flag(rc.y, rc.x)
			return
		else:
			return
		
		var cell_info = _get_cell_at(pos)
		if cell_info.x < 0:
			return
		
		# Двойной клик/тап — chord reveal (открыть соседние клетки)
		if is_press and is_double:
			_chord_reveal(cell_info.y, cell_info.x)
			press_handled = true
			return
		
		if is_press:
			press_start_time = Time.get_ticks_msec() / 1000.0
			press_cell = cell_info
			press_handled = false
		elif is_release and !press_handled:
			if cell_info == press_cell:
				var hold_time = Time.get_ticks_msec() / 1000.0 - press_start_time
				if hold_time >= long_press_time:
					_toggle_flag(cell_info.y, cell_info.x)
					if OS.has_feature("mobile"):
						Input.vibrate_handheld(50)
				else:
					_reveal_cell(cell_info.y, cell_info.x)
			press_start_time = -1.0

func _process(delta):
	if press_start_time > 0 and !press_handled and !game_over:
		var hold_time = Time.get_ticks_msec() / 1000.0 - press_start_time
		if hold_time >= long_press_time:
			# Долгий тап — флаг
			if press_cell.x >= 0:
				_toggle_flag(press_cell.y, press_cell.x)
				press_handled = true
				if OS.has_feature("mobile"):
					Input.vibrate_handheld(50)

func _get_cell_at(pos: Vector2) -> Vector2i:
	var grid_rect = grid.get_global_rect()
	if !grid_rect.has_point(pos):
		return Vector2i(-1, -1)
	var local_pos = pos - grid_rect.position
	var col = int(local_pos.x / cell_size)
	var row = int(local_pos.y / cell_size)
	if row >= 0 and row < rows and col >= 0 and col < cols:
		return Vector2i(col, row)
	return Vector2i(-1, -1)

func _reveal_cell(r: int, c: int):
	if r < 0 or r >= rows or c < 0 or c >= cols:
		return
	if revealed[r][c] or flagged[r][c]:
		return
	
	if !game_started:
		game_started = true
		_place_mines(r, c)
		game_timer.start()
	
	revealed[r][c] = true
	cells_revealed += 1
	
	if field[r][c] == -1:
		# Мина — проигрыш
		_game_lost(r, c)
		return
	
	_update_cell_visual(r, c)
	
	# Если пустая — раскрываем соседей
	if field[r][c] == 0:
		for dr in range(-1, 2):
			for dc in range(-1, 2):
				if dr == 0 and dc == 0:
					continue
				_reveal_cell(r + dr, c + dc)
	
	# Проверяем победу
	if cells_revealed == rows * cols - mine_count:
		_game_won()

func _chord_reveal(r: int, c: int):
	# Если клетка открыта и число совпадает с количеством флагов вокруг — открыть соседей
	# Если клетка закрыта — просто открыть все соседние закрытые клетки
	if revealed[r][c]:
		# Классический chord: считаем флаги вокруг
		var flag_count = 0
		for dr in range(-1, 2):
			for dc in range(-1, 2):
				var nr = r + dr
				var nc = c + dc
				if nr >= 0 and nr < rows and nc >= 0 and nc < cols:
					if flagged[nr][nc]:
						flag_count += 1
		# Если флагов = числу на клетке, открываем все нефлагованные соседние
		if flag_count == field[r][c]:
			for dr in range(-1, 2):
				for dc in range(-1, 2):
					var nr = r + dr
					var nc = c + dc
					if nr >= 0 and nr < rows and nc >= 0 and nc < cols:
						if !revealed[nr][nc] and !flagged[nr][nc]:
							_reveal_cell(nr, nc)
	else:
		# Клетка закрыта — открываем все соседние нефлагованные
		for dr in range(-1, 2):
			for dc in range(-1, 2):
				var nr = r + dr
				var nc = c + dc
				if nr >= 0 and nr < rows and nc >= 0 and nc < cols:
					if !revealed[nr][nc] and !flagged[nr][nc]:
						_reveal_cell(nr, nc)

func _toggle_flag(r: int, c: int):
	if revealed[r][c]:
		return
	
	flagged[r][c] = !flagged[r][c]
	if flagged[r][c]:
		flags_placed += 1
	else:
		flags_placed -= 1
	
	_update_cell_visual(r, c)
	_update_mine_counter()

func _update_cell_visual(r: int, c: int):
	var idx = r * cols + c
	if idx >= grid.get_child_count():
		return
	var cell: MineCell = grid.get_child(idx)
	
	if revealed[r][c]:
		cell.set_revealed_style()
		
		var val = field[r][c]
		if val > 0:
			cell.show_number(val, number_colors.get(val, Color.BLACK))
		elif val == -1:
			cell.show_mine()
		else:
			cell.show_empty()
	elif flagged[r][c]:
		cell.show_flag()
	else:
		cell.show_closed()

func _game_lost(hit_r: int, hit_c: int):
	game_over = true
	game_timer.stop()
	face_button.text = ""
	face_button.icon = face_dead_tex
	
	# Показываем все мины
	for r in rows:
		for c in cols:
			if field[r][c] == -1:
				revealed[r][c] = true
				_update_cell_visual(r, c)
	
	# Подсветить клетку, на которую наступили
	var idx = hit_r * cols + hit_c
	if idx < grid.get_child_count():
		var cell: MineCell = grid.get_child(idx)
		cell.set_hit_style()

func _game_won():
	game_over = true
	game_timer.stop()
	face_button.text = ""
	face_button.icon = face_cool_tex
	
	# Отмечаем оставшиеся мины флагами
	for r in rows:
		for c in cols:
			if field[r][c] == -1 and !flagged[r][c]:
				flagged[r][c] = true
				flags_placed += 1
				_update_cell_visual(r, c)
	_update_mine_counter()

func _on_face_pressed():
	if game_over:
		_new_game()
	elif game_started:
		var dialog = ConfirmationDialog.new()
		dialog.dialog_text = "Начать заново?"
		dialog.ok_button_text = "Да"
		dialog.cancel_button_text = "Нет"
		dialog.confirmed.connect(func():
			_show_difficulty_menu()
			dialog.queue_free()
		)
		dialog.canceled.connect(func():
			dialog.queue_free()
		)
		add_child(dialog)
		dialog.popup_centered()
	else:
		_show_difficulty_menu()

func _on_timer_timeout():
	elapsed_time += 1
	_update_timer()

func _update_mine_counter():
	var remaining = mine_count - flags_placed
	mine_counter.set_value(remaining)

func _update_timer():
	timer_label.set_value(min(elapsed_time, 999))
