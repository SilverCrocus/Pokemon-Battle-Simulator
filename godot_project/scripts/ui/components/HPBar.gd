extends ProgressBar

## HP Bar Component with Smooth Animation (Gen 5 Style)
##
## Displays Pokemon HP with color-coded bar that smoothly animates on changes.
## Colors: Green (>50%), Yellow (20-50%), Red (<20%)
##
## Usage:
## ```gdscript
## $HPBar.initialize(200)  # Set max HP
## $HPBar.animate_to(150)  # Animate to 150 HP
## ```

# ==================== Constants ====================

const ANIMATION_DURATION := 0.3  # Seconds for HP animation

# ==================== State ====================

var current_value: float = 0.0
var tween: Tween = null

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the HP bar."""
	_setup_styling()


# ==================== Public Methods ====================

func initialize(max_hp_value: int, current_hp_value: int = -1) -> void:
	"""
	Initialize the HP bar with max and current HP.

	@param max_hp_value: Maximum HP value
	@param current_hp_value: Current HP value (defaults to max if not provided)
	"""
	max_value = max_hp_value

	if current_hp_value < 0:
		current_hp_value = max_hp_value

	current_value = current_hp_value
	value = current_hp_value

	_update_color()


func animate_to(new_hp: int, duration: float = ANIMATION_DURATION) -> void:
	"""
	Animate HP bar to new value.

	@param new_hp: Target HP value
	@param duration: Animation duration in seconds
	"""
	# Cancel any existing tween
	if tween:
		tween.kill()

	# Create new tween
	tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Animate the value
	tween.tween_property(self, "value", new_hp, duration)

	# Update target value
	current_value = new_hp

	# Update color immediately based on target percentage
	_update_color()


func set_instant(new_hp: int) -> void:
	"""
	Set HP instantly without animation.

	@param new_hp: New HP value
	"""
	# Cancel any existing tween
	if tween:
		tween.kill()

	current_value = new_hp
	value = new_hp
	_update_color()


func get_hp_percentage() -> float:
	"""Get current HP as a percentage (0.0 to 1.0)."""
	return value / max_value if max_value > 0 else 0.0


# ==================== Private Methods ====================

func _setup_styling() -> void:
	"""Apply Gen 5 HP bar styling."""
	# Set bar height
	custom_minimum_size = Vector2(0, 8)

	# Configure progress bar
	show_percentage = false

	# Create background style (empty HP area)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = BattleTheme.HP_BG
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = BattleTheme.HP_BORDER
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.corner_radius_bottom_right = 2
	add_theme_stylebox_override("background", bg_style)

	# Create fill style (current HP area) - color will be updated dynamically
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = BattleTheme.HP_GREEN
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_left = 2
	fill_style.corner_radius_bottom_right = 2
	add_theme_stylebox_override("fill", fill_style)


func _update_color() -> void:
	"""Update HP bar color based on current percentage."""
	var hp_percentage = get_hp_percentage()
	var hp_color = BattleTheme.get_hp_color(hp_percentage)

	# Update the fill style color
	var fill_style = get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		fill_style = fill_style.duplicate()
		fill_style.bg_color = hp_color
		add_theme_stylebox_override("fill", fill_style)


func _process(_delta: float) -> void:
	"""Update color during animation."""
	# Update color continuously during animation
	# This ensures smooth color transitions when HP crosses thresholds
	_update_color()
