extends PanelContainer

## Pokemon Information Panel Component (Gen 5 Style)
##
## Displays Pokemon name, level, gender, HP bar, and status.
## Used for both player and opponent Pokemon info displays.
##
## Usage:
## ```gdscript
## $PokemonInfoPanel.setup(pokemon, true)  # true = show HP text (player)
## $PokemonInfoPanel.update_hp(current_hp, max_hp)
## $PokemonInfoPanel.set_status("burn")
## ```

# ==================== Node References ====================

@onready var name_label: Label = $MarginContainer/VBoxContainer/TopRow/NameLabel
@onready var gender_label: Label = $MarginContainer/VBoxContainer/TopRow/GenderLabel
@onready var level_label: Label = $MarginContainer/VBoxContainer/TopRow/LevelLabel
@onready var status_label: Label = $MarginContainer/VBoxContainer/TopRow/StatusLabel

@onready var hp_bar_container: Control = $MarginContainer/VBoxContainer/HPBarContainer
@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPBarContainer/HPBar
@onready var hp_text_label: Label = $MarginContainer/VBoxContainer/HPTextLabel

# ==================== State ====================

var show_hp_text: bool = false
var current_pokemon = null

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the info panel."""
	_setup_styling()


# ==================== Public Methods ====================

func setup(pokemon, show_hp_numbers: bool = false) -> void:
	"""
	Configure the panel for a Pokemon.

	@param pokemon: The BattlePokemon to display
	@param show_hp_numbers: Whether to show "123 / 200" text (player only)
	"""
	current_pokemon = pokemon
	show_hp_text = show_hp_numbers

	# Set name (uppercase for Gen 5 style)
	name_label.text = pokemon.species.name.to_upper()

	# Set gender
	if pokemon.gender == "male":
		gender_label.text = "♂"
		gender_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))  # Blue
	elif pokemon.gender == "female":
		gender_label.text = "♀"
		gender_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.6))  # Pink
	else:
		gender_label.text = ""

	# Set level
	level_label.text = "Lv.%d" % pokemon.level

	# Show/hide HP text
	hp_text_label.visible = show_hp_numbers
	if show_hp_numbers:
		hp_text_label.text = "%d / %d" % [pokemon.current_hp, pokemon.max_hp]

	# Clear status initially
	status_label.text = ""

	# Setup HP bar (will be implemented when HPBar component is ready)
	_setup_hp_bar(pokemon.current_hp, pokemon.max_hp)


func update_hp(new_hp: int, max_hp: int) -> void:
	"""
	Update the HP display.

	@param new_hp: New current HP value
	@param max_hp: Maximum HP value
	"""
	# Update HP text if visible
	if show_hp_text:
		hp_text_label.text = "%d / %d" % [new_hp, max_hp]

	# Update HP bar with smooth animation
	_update_hp_bar(new_hp)


func set_status(status_name: String) -> void:
	"""
	Display a status condition.

	@param status_name: Status condition name (burn, poison, paralysis, sleep, freeze, badly_poison)
	"""
	if status_name.is_empty():
		status_label.text = ""
		status_label.visible = false
	else:
		# Use abbreviated status names (Gen 5 style)
		var status_text = ""
		match status_name.to_lower():
			"burn": status_text = "BRN"
			"poison": status_text = "PSN"
			"badly_poison": status_text = "PSN"
			"paralysis": status_text = "PAR"
			"sleep": status_text = "SLP"
			"freeze": status_text = "FRZ"

		status_label.text = status_text
		status_label.add_theme_color_override("font_color", BattleTheme.get_status_color(status_name))
		status_label.visible = true


func clear_status() -> void:
	"""Remove status condition display."""
	status_label.text = ""
	status_label.visible = false


# ==================== Private Methods ====================

func _setup_styling() -> void:
	"""Apply Gen 5 visual styling."""
	# Panel background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = BattleTheme.BG_MEDIUM
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

	# Name label styling
	name_label.add_theme_color_override("font_color", BattleTheme.TEXT_WHITE)
	name_label.add_theme_font_size_override("font_size", 18)

	# Level label styling
	level_label.add_theme_color_override("font_color", BattleTheme.TEXT_GRAY)
	level_label.add_theme_font_size_override("font_size", 14)

	# HP text styling
	hp_text_label.add_theme_color_override("font_color", BattleTheme.TEXT_WHITE)
	hp_text_label.add_theme_font_size_override("font_size", 16)
	hp_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Status label styling
	status_label.add_theme_font_size_override("font_size", 12)


func _setup_hp_bar(current_hp: int, max_hp: int) -> void:
	"""Initialize HP bar display."""
	hp_bar.initialize(max_hp, current_hp)


func _update_hp_bar(new_hp: int) -> void:
	"""Update HP bar visual with animation."""
	hp_bar.animate_to(new_hp)
