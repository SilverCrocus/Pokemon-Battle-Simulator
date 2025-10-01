extends Button

## Move Button Component (Gen 5 Style)
##
## Displays a single move with name, PP, and type-colored background.
## Used in the 2x2 move selection grid.

# ==================== Signals ====================

signal move_button_pressed(move_index: int)

# ==================== Node References ====================

@onready var move_name_label: Label = $MarginContainer/VBoxContainer/MoveNameLabel
@onready var pp_label: Label = $MarginContainer/VBoxContainer/PPLabel

# ==================== State ====================

var move_data = null
var move_index: int = -1
var current_pp: int = 0
var max_pp: int = 0

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the move button."""
	pressed.connect(_on_pressed)


# ==================== Public Methods ====================

func setup(move, index: int, pp: int) -> void:
	"""
	Configure the button for a move.

	@param move: The MoveData to display
	@param index: Move index (0-3)
	@param pp: Current PP for the move
	"""
	move_data = move
	move_index = index
	current_pp = pp
	max_pp = move.pp

	# Set move name (uppercase for Gen 5 style)
	move_name_label.text = move.name.to_upper()

	# Set PP text
	pp_label.text = "PP %d / %d" % [current_pp, max_pp]

	# Apply type-based styling
	_apply_type_styling()


func update_pp(new_pp: int) -> void:
	"""
	Update the PP display.

	@param new_pp: New current PP value
	"""
	current_pp = new_pp
	pp_label.text = "PP %d / %d" % [current_pp, max_pp]

	# Disable if out of PP
	disabled = (current_pp <= 0)


func set_enabled(enabled: bool) -> void:
	"""Enable or disable the button."""
	disabled = not enabled


# ==================== Private Methods ====================

func _apply_type_styling() -> void:
	"""Apply type-based color to the button."""
	if not move_data:
		return

	var type_color = BattleTheme.get_type_color(move_data.type)

	# Create normal state style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = type_color
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = BattleTheme.BORDER_LIGHT
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("normal", normal_style)

	# Create hover state style (slightly brighter)
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = type_color.lightened(0.2)
	add_theme_stylebox_override("hover", hover_style)

	# Create pressed state style (slightly darker)
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = type_color.darkened(0.2)
	add_theme_stylebox_override("pressed", pressed_style)

	# Create disabled state style (grayed out)
	var disabled_style = normal_style.duplicate()
	disabled_style.bg_color = BattleTheme.BTN_DISABLED
	add_theme_stylebox_override("disabled", disabled_style)

	# Style the labels
	move_name_label.add_theme_color_override("font_color", BattleTheme.TEXT_WHITE)
	move_name_label.add_theme_font_size_override("font_size", 16)

	pp_label.add_theme_color_override("font_color", BattleTheme.TEXT_GRAY)
	pp_label.add_theme_font_size_override("font_size", 12)


func _on_pressed() -> void:
	"""Handle button press."""
	if move_index >= 0:
		move_button_pressed.emit(move_index)
