extends PanelContainer

## Action Menu Component (Gen 5 Style)
##
## Displays the main battle actions in a 2x2 grid:
## - Fight (select a move)
## - Pokemon (switch Pokemon)
## - Bag (use item)
## - Run (flee from battle)

# ==================== Signals ====================

signal action_selected(action_type: String)

# ==================== Node References ====================

@onready var fight_button: Button = $MarginContainer/GridContainer/FightButton
@onready var pokemon_button: Button = $MarginContainer/GridContainer/PokemonButton
@onready var bag_button: Button = $MarginContainer/GridContainer/BagButton
@onready var run_button: Button = $MarginContainer/GridContainer/RunButton

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the action menu."""
	_setup_styling()
	_connect_buttons()


# ==================== Public Methods ====================

func set_enabled(enabled: bool) -> void:
	"""Enable or disable all buttons."""
	fight_button.disabled = not enabled
	pokemon_button.disabled = not enabled
	bag_button.disabled = not enabled
	run_button.disabled = not enabled


func enable_fight(enabled: bool) -> void:
	"""Enable or disable the Fight button."""
	fight_button.disabled = not enabled


func enable_pokemon(enabled: bool) -> void:
	"""Enable or disable the Pokemon button."""
	pokemon_button.disabled = not enabled


func enable_bag(enabled: bool) -> void:
	"""Enable or disable the Bag button."""
	bag_button.disabled = not enabled


func enable_run(enabled: bool) -> void:
	"""Enable or disable the Run button."""
	run_button.disabled = not enabled


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

	# Style each button
	_style_button(fight_button)
	_style_button(pokemon_button)
	_style_button(bag_button)
	_style_button(run_button)


func _style_button(button: Button) -> void:
	"""Apply consistent styling to a button."""
	# Normal state
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = BattleTheme.BTN_NORMAL
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = BattleTheme.BORDER_LIGHT
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("normal", normal_style)

	# Hover state
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = BattleTheme.BTN_HOVER
	button.add_theme_stylebox_override("hover", hover_style)

	# Pressed state
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = BattleTheme.BTN_PRESSED
	button.add_theme_stylebox_override("pressed", pressed_style)

	# Disabled state
	var disabled_style = normal_style.duplicate()
	disabled_style.bg_color = BattleTheme.BTN_DISABLED
	button.add_theme_stylebox_override("disabled", disabled_style)

	# Text styling
	button.add_theme_color_override("font_color", BattleTheme.BTN_TEXT)
	button.add_theme_color_override("font_disabled_color", BattleTheme.BTN_TEXT_DISABLED)
	button.add_theme_font_size_override("font_size", 18)


func _connect_buttons() -> void:
	"""Connect button signals."""
	fight_button.pressed.connect(func(): action_selected.emit("fight"))
	pokemon_button.pressed.connect(func(): action_selected.emit("pokemon"))
	bag_button.pressed.connect(func(): action_selected.emit("bag"))
	run_button.pressed.connect(func(): action_selected.emit("run"))
