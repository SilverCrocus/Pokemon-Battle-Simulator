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

	print("[MainMenu] Ready")


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
	print("[MainMenu] Opening Team Builder")
	get_tree().change_scene_to_file("res://scenes/team_builder/TeamBuilderScene.tscn")


func _on_quick_battle_pressed() -> void:
	"""Start a quick battle vs AI."""
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
	print("[MainMenu] Multiplayer not yet implemented")


func _on_settings_pressed() -> void:
	"""Open settings menu."""
	print("[MainMenu] Settings menu coming soon")
	# TODO: Implement settings menu


func _on_exit_pressed() -> void:
	"""Exit the game."""
	print("[MainMenu] Exiting game")
	get_tree().quit()


# ==================== Helper Methods ====================

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

	# Store team data in BattleController for battle scene
	if BattleController:
		BattleController.player_team_data = team_data
		BattleController.is_vs_ai = true

		# Switch to battle scene
		get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")
	else:
		print("[MainMenu] Error: BattleController not found")
