extends PanelContainer

## Move Selection UI Component (Gen 5 Style)
##
## Displays 4 moves in a 2x2 grid layout.
## Emits signal when a move is selected.

# ==================== Signals ====================

signal move_selected(move_index: int)

# ==================== Node References ====================

@onready var move_button_1: Button = $MarginContainer/GridContainer/MoveButton1
@onready var move_button_2: Button = $MarginContainer/GridContainer/MoveButton2
@onready var move_button_3: Button = $MarginContainer/GridContainer/MoveButton3
@onready var move_button_4: Button = $MarginContainer/GridContainer/MoveButton4

# ==================== State ====================

var current_moves: Array = []
var current_pp: Array[int] = [0, 0, 0, 0]

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the move selection UI."""
	_setup_styling()
	_connect_buttons()


# ==================== Public Methods ====================

func setup_moves(pokemon) -> void:
	"""
	Configure the UI with a Pokemon's moves.

	@param pokemon: The BattlePokemon whose moves to display
	"""
	current_moves = pokemon.moves.duplicate()

	# Get current PP for each move
	for i in range(4):
		if i < pokemon.moves.size():
			current_pp[i] = pokemon.current_pp[i]
		else:
			current_pp[i] = 0

	_update_buttons()


func update_move_pp(move_index: int, new_pp: int) -> void:
	"""
	Update PP for a specific move.

	@param move_index: Index of the move (0-3)
	@param new_pp: New PP value
	"""
	if move_index < 0 or move_index >= 4:
		return

	current_pp[move_index] = new_pp

	# Update the corresponding button
	var button = _get_button_by_index(move_index)
	if button:
		button.update_pp(new_pp)


# ==================== Private Methods ====================

func _setup_styling() -> void:
	"""Apply Gen 5 visual styling."""
	# Panel background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = BattleTheme.BG_DARK
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = BattleTheme.BORDER_LIGHT
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", style_box)


func _connect_buttons() -> void:
	"""Connect button signals."""
	if move_button_1:
		move_button_1.move_button_pressed.connect(_on_move_button_pressed)

	if move_button_2:
		move_button_2.move_button_pressed.connect(_on_move_button_pressed)

	if move_button_3:
		move_button_3.move_button_pressed.connect(_on_move_button_pressed)

	if move_button_4:
		move_button_4.move_button_pressed.connect(_on_move_button_pressed)


func _update_buttons() -> void:
	"""Update all move buttons with current move data."""
	var buttons = [move_button_1, move_button_2, move_button_3, move_button_4]

	for i in range(4):
		var button = buttons[i]
		if not button:
			continue

		if i < current_moves.size():
			# Setup button with move data
			button.setup(current_moves[i], i, current_pp[i])
			button.visible = true
		else:
			# Hide unused button slots
			button.visible = false


func _get_button_by_index(index: int) -> Button:
	"""Get button by move index."""
	match index:
		0: return move_button_1
		1: return move_button_2
		2: return move_button_3
		3: return move_button_4
		_: return null


func _on_move_button_pressed(move_index: int) -> void:
	"""Handle move button press."""
	move_selected.emit(move_index)
