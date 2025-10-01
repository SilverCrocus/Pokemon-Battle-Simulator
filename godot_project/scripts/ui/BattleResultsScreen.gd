extends Control

## Battle Results Screen
##
## Displays battle outcome, statistics, and navigation options.
## Shown when battle ends with a winner.

# ==================== Signals ====================

signal return_to_menu_pressed()
signal rematch_pressed()

# ==================== Node References ====================

@onready var results_panel: PanelContainer = $CenterContainer/ResultsPanel
@onready var result_label: Label = $CenterContainer/ResultsPanel/MarginContainer/VBoxContainer/ResultLabel
@onready var subtitle_label: Label = $CenterContainer/ResultsPanel/MarginContainer/VBoxContainer/SubtitleLabel
@onready var stats_container: VBoxContainer = $CenterContainer/ResultsPanel/MarginContainer/VBoxContainer/StatsContainer
@onready var button_container: HBoxContainer = $CenterContainer/ResultsPanel/MarginContainer/VBoxContainer/ButtonContainer
@onready var menu_button: Button = $CenterContainer/ResultsPanel/MarginContainer/VBoxContainer/ButtonContainer/MenuButton
@onready var rematch_button: Button = $CenterContainer/ResultsPanel/MarginContainer/VBoxContainer/ButtonContainer/RematchButton

# ==================== State ====================

var winner_side: int = 0  # 0 = player, 1 = opponent
var turns_count: int = 0
var damage_dealt: int = 0
var damage_taken: int = 0

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the results screen."""
	_setup_styling()
	_connect_signals()
	hide()  # Hidden by default


# ==================== Public Methods ====================

func show_results(winner: int, stats: Dictionary = {}) -> void:
	"""
	Display battle results.

	@param winner: Winner side (0 = player, 1 = opponent)
	@param stats: Optional dictionary with battle statistics
	"""
	winner_side = winner

	# Extract stats if provided
	turns_count = stats.get("turns", 0)
	damage_dealt = stats.get("damage_dealt", 0)
	damage_taken = stats.get("damage_taken", 0)

	# Update UI
	_update_result_display()
	_update_stats_display()

	# Show screen with fade-in animation
	show()
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func hide_results() -> void:
	"""Hide the results screen."""
	hide()


# ==================== Private Methods - Setup ====================

func _setup_styling() -> void:
	"""Apply Gen 5 visual styling to results screen."""
	# Panel background
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
	results_panel.add_theme_stylebox_override("panel", style_box)

	# Result label (large text)
	result_label.add_theme_font_size_override("font_size", 48)
	result_label.add_theme_color_override("font_color", BattleTheme.TEXT_WHITE)

	# Subtitle
	subtitle_label.add_theme_font_size_override("font_size", 20)
	subtitle_label.add_theme_color_override("font_color", BattleTheme.TEXT_GRAY)

	# Style buttons
	_style_button(menu_button)
	_style_button(rematch_button)


func _style_button(button: Button) -> void:
	"""Apply styling to a button."""
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


func _connect_signals() -> void:
	"""Connect button signals."""
	menu_button.pressed.connect(_on_menu_pressed)
	rematch_button.pressed.connect(_on_rematch_pressed)


# ==================== Private Methods - Display ====================

func _update_result_display() -> void:
	"""Update the main result text based on winner."""
	if winner_side == 0:
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))  # Green
		subtitle_label.text = "You defeated your opponent!"
	else:
		result_label.text = "DEFEAT"
		result_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))  # Red
		subtitle_label.text = "You were defeated..."


func _update_stats_display() -> void:
	"""Update battle statistics display."""
	# Clear existing stats
	for child in stats_container.get_children():
		child.queue_free()

	# Add turn count
	if turns_count > 0:
		_add_stat_label("Turns: %d" % turns_count)

	# Add damage stats
	if damage_dealt > 0:
		_add_stat_label("Damage Dealt: %d" % damage_dealt)

	if damage_taken > 0:
		_add_stat_label("Damage Taken: %d" % damage_taken)

	# If no stats, show placeholder
	if stats_container.get_child_count() == 0:
		_add_stat_label("Battle complete!")


func _add_stat_label(text: String) -> void:
	"""Add a stat label to the stats container."""
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", BattleTheme.TEXT_WHITE)
	stats_container.add_child(label)


# ==================== Event Handlers ====================

func _on_menu_pressed() -> void:
	"""Return to main menu."""
	# Play button sound
	# TODO: Uncomment when audio files are added
	# AudioManager.play_sfx("button_press")

	print("[BattleResults] Returning to main menu")
	return_to_menu_pressed.emit()
	get_tree().change_scene_to_file("res://scenes/menu/MainMenuScene.tscn")


func _on_rematch_pressed() -> void:
	"""Start a rematch."""
	# Play button sound
	# TODO: Uncomment when audio files are added
	# AudioManager.play_sfx("button_press")

	print("[BattleResults] Starting rematch")
	rematch_pressed.emit()
	# Reload the battle scene for a fresh match
	get_tree().reload_current_scene()
