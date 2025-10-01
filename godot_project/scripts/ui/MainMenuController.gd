extends Control

## Main Menu Controller
##
## Handles main menu navigation and transitions to different game modes.

# ==================== Node References ====================

@onready var team_builder_button: Button = $CenterContainer/MenuPanel/MarginContainer/VBoxContainer/MenuButtons/TeamBuilderButton
@onready var quick_battle_button: Button = $CenterContainer/MenuPanel/MarginContainer/VBoxContainer/MenuButtons/QuickBattleButton
@onready var multiplayer_button: Button = $CenterContainer/MenuPanel/MarginContainer/VBoxContainer/MenuButtons/MultiplayerButton
@onready var settings_button: Button = $CenterContainer/MenuPanel/MarginContainer/VBoxContainer/MenuButtons/SettingsButton
@onready var exit_button: Button = $CenterContainer/MenuPanel/MarginContainer/VBoxContainer/MenuButtons/ExitButton

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the main menu."""
	_setup_styling()
	_connect_signals()
	_play_menu_music()

	print("[MainMenu] Ready")


func _play_menu_music() -> void:
	"""Start main menu background music."""
	# TODO: Uncomment when audio files are added
	# AudioManager.play_music("main_menu", true, true)


# ==================== Setup Methods ====================

func _setup_styling() -> void:
	"""Apply Gen 5 visual styling to menu."""
	# Panel background
	var panel = $CenterContainer/MenuPanel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = BattleTheme.BG_MEDIUM
	style_box.border_width_left = 3
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.border_color = BattleTheme.BORDER_LIGHT
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style_box)

	# Title styling
	var title = $CenterContainer/MenuPanel/MarginContainer/VBoxContainer/Title
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", BattleTheme.TEXT_WHITE)

	# Subtitle
	var subtitle = $CenterContainer/MenuPanel/MarginContainer/VBoxContainer/Subtitle
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", BattleTheme.TEXT_GRAY)

	# Version label
	var version = $CenterContainer/MenuPanel/MarginContainer/VBoxContainer/VersionLabel
	version.add_theme_font_size_override("font_size", 12)
	version.add_theme_color_override("font_color", BattleTheme.TEXT_GRAY)

	# Credit label
	var credit = $CenterContainer/MenuPanel/MarginContainer/VBoxContainer/CreditLabel
	credit.add_theme_font_size_override("font_size", 12)
	credit.add_theme_color_override("font_color", BattleTheme.TEXT_GRAY)

	# Style buttons
	_style_menu_buttons()


func _style_menu_buttons() -> void:
	"""Apply styling to menu buttons."""
	var buttons = [
		team_builder_button,
		quick_battle_button,
		multiplayer_button,
		settings_button,
		exit_button
	]

	for button in buttons:
		button.add_theme_font_size_override("font_size", 18)

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
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = BattleTheme.BTN_HOVER
		hover_style.border_width_left = 2
		hover_style.border_width_top = 2
		hover_style.border_width_right = 2
		hover_style.border_width_bottom = 2
		hover_style.border_color = BattleTheme.BORDER_LIGHT
		hover_style.corner_radius_top_left = 4
		hover_style.corner_radius_top_right = 4
		hover_style.corner_radius_bottom_left = 4
		hover_style.corner_radius_bottom_right = 4
		button.add_theme_stylebox_override("hover", hover_style)

		# Pressed state
		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = BattleTheme.BTN_PRESSED
		pressed_style.border_width_left = 2
		pressed_style.border_width_top = 2
		pressed_style.border_width_right = 2
		pressed_style.border_width_bottom = 2
		pressed_style.border_color = BattleTheme.BORDER_DARK
		pressed_style.corner_radius_top_left = 4
		pressed_style.corner_radius_top_right = 4
		pressed_style.corner_radius_bottom_left = 4
		pressed_style.corner_radius_bottom_right = 4
		button.add_theme_stylebox_override("pressed", pressed_style)

		# Disabled state
		if button.disabled:
			var disabled_style = StyleBoxFlat.new()
			disabled_style.bg_color = BattleTheme.BG_DARK
			disabled_style.border_width_left = 2
			disabled_style.border_width_top = 2
			disabled_style.border_width_right = 2
			disabled_style.border_width_bottom = 2
			disabled_style.border_color = BattleTheme.BORDER_DARK
			disabled_style.corner_radius_top_left = 4
			disabled_style.corner_radius_top_right = 4
			disabled_style.corner_radius_bottom_left = 4
			disabled_style.corner_radius_bottom_right = 4
			button.add_theme_stylebox_override("disabled", disabled_style)
			button.add_theme_color_override("font_disabled_color", BattleTheme.TEXT_GRAY)


func _connect_signals() -> void:
	"""Connect button signals."""
	team_builder_button.pressed.connect(_on_team_builder_pressed)
	quick_battle_button.pressed.connect(_on_quick_battle_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


# ==================== Event Handlers ====================

func _on_team_builder_pressed() -> void:
	"""Navigate to team builder."""
	_play_button_sound()
	print("[MainMenu] Opening Team Builder")
	get_tree().change_scene_to_file("res://scenes/team_builder/TeamBuilderScene.tscn")


func _on_quick_battle_pressed() -> void:
	"""Start a quick battle vs AI."""
	_play_button_sound()
	print("[MainMenu] Starting Quick Battle")

	# Check if user has a saved team
	if _has_saved_team():
		# Load team and start battle
		_start_battle_with_saved_team()
	else:
		# Prompt to create a team first
		print("[MainMenu] No saved team found. Please create a team first.")
		# TODO: Show dialog prompting to create team
		get_tree().change_scene_to_file("res://scenes/team_builder/TeamBuilderScene.tscn")


func _on_multiplayer_pressed() -> void:
	"""Navigate to multiplayer (not implemented yet)."""
	_play_button_sound()
	print("[MainMenu] Multiplayer not yet implemented")


func _on_settings_pressed() -> void:
	"""Open settings menu."""
	_play_button_sound()
	print("[MainMenu] Settings menu coming soon")
	# TODO: Implement settings menu


func _on_exit_pressed() -> void:
	"""Exit the game."""
	_play_button_sound()
	print("[MainMenu] Exiting game")
	get_tree().quit()


# ==================== Helper Methods ====================

func _play_button_sound() -> void:
	"""Play button click sound effect."""
	# TODO: Uncomment when audio files are added
	# AudioManager.play_sfx("button_press")
	pass


func _has_saved_team() -> bool:
	"""Check if user has a saved team."""
	return FileAccess.file_exists("user://team.json")


func _start_battle_with_saved_team() -> void:
	"""Load saved team and start battle."""
	# Load team
	var file = FileAccess.open("user://team.json", FileAccess.READ)
	if not file:
		print("[MainMenu] Error: Could not load team")
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		print("[MainMenu] Error: Invalid team JSON")
		return

	var team_data = json.data

	# Create player team from JSON
	var player_team = _create_team_from_json(team_data)
	if not player_team or player_team.is_empty():
		print("[MainMenu] Error: Could not create player team")
		return

	# Create simple AI opponent team
	var ai_team = _create_simple_ai_team()
	if not ai_team or ai_team.is_empty():
		print("[MainMenu] Error: Could not create AI team")
		return

	# Start battle with AI
	if BattleController:
		# Use BattleAI.Difficulty.RANDOM (0) for now
		BattleController.start_battle(player_team, ai_team, -1, true, 0)

		# Switch to battle scene
		get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")
	else:
		print("[MainMenu] Error: BattleController not found")


func _create_team_from_json(team_data: Dictionary) -> Array:
	"""
	Create array of BattlePokemon from team JSON data.

	@param team_data: Team JSON structure
	@return: Array of BattlePokemon instances
	"""
	var team = []

	const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")

	for pokemon_data in team_data.pokemon:
		var species = DataManager.get_pokemon(pokemon_data.species_id)
		if not species:
			continue

		# Load moves
		var moves = []
		for move_id in pokemon_data.moves:
			var move = DataManager.get_move(move_id)
			if move:
				moves.append(move)

		# Create BattlePokemon
		var battle_pokemon = BattlePokemonScript.new(
			species,
			pokemon_data.level,
			pokemon_data.ivs,
			pokemon_data.evs,
			pokemon_data.nature,
			moves,
			pokemon_data.ability,
			pokemon_data.item,
			pokemon_data.nickname
		)

		team.append(battle_pokemon)

	return team


func _create_simple_ai_team() -> Array:
	"""
	Create a simple AI team for testing.
	Uses a few Gen 1 Pokemon with random moves.

	@return: Array of BattlePokemon instances
	"""
	var team = []

	const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")

	# Create 3 Pokemon for AI (Charizard, Blastoise, Venusaur)
	var pokemon_ids = [6, 9, 3]  # Charizard, Blastoise, Venusaur

	for pokemon_id in pokemon_ids:
		var species = DataManager.get_pokemon(pokemon_id)
		if not species:
			continue

		# Simple moveset
		var moves = [
			DataManager.get_move(33),   # Tackle
			DataManager.get_move(52),   # Ember
			DataManager.get_move(55),   # Water Gun
			DataManager.get_move(22)    # Vine Whip
		]

		# Default competitive stats
		var evs = {"hp": 4, "atk": 252, "def": 0, "spa": 0, "spd": 0, "spe": 252}
		var ivs = {"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31}

		# Create BattlePokemon
		var battle_pokemon = BattlePokemonScript.new(
			species,
			50,  # Level 50
			ivs,
			evs,
			"Serious",  # Neutral nature
			moves,
			species.abilities[0] if species.abilities.size() > 0 else "No Ability",
			"",  # No item
			""   # No nickname
		)

		team.append(battle_pokemon)

	return team
