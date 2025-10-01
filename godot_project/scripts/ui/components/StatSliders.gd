extends VBoxContainer

## Stat Sliders Component
##
## Provides EV and IV sliders for all 6 stats with validation and presets.
## Shows real-time stat calculations based on base stats, IVs, EVs, nature, and level.

# ==================== Signals ====================

signal stats_changed(evs: Dictionary, ivs: Dictionary)

# ==================== Constants ====================

const STAT_NAMES := ["HP", "Atk", "Def", "SpA", "SpD", "Spe"]
const STAT_KEYS := ["hp", "atk", "def", "spa", "spd", "spe"]
const MAX_EV_PER_STAT := 252
const MAX_EV_TOTAL := 508
const MAX_IV := 31

# EV Presets for common competitive spreads
const EV_PRESETS := {
	"Offensive": {"hp": 4, "atk": 252, "def": 0, "spa": 0, "spd": 0, "spe": 252},
	"Special Attacker": {"hp": 4, "atk": 0, "def": 0, "spa": 252, "spd": 0, "spe": 252},
	"Physical Wall": {"hp": 252, "atk": 0, "def": 252, "spa": 0, "spd": 4, "spe": 0},
	"Special Wall": {"hp": 252, "atk": 0, "def": 4, "spa": 0, "spd": 252, "spe": 0},
	"Balanced": {"hp": 252, "atk": 0, "def": 128, "spa": 0, "spd": 128, "spe": 0},
	"Max Speed": {"hp": 4, "atk": 0, "def": 0, "spa": 0, "spd": 0, "spe": 252}
}

# ==================== State ====================

var current_evs := {"hp": 0, "atk": 0, "def": 0, "spa": 0, "spd": 0, "spe": 0}
var current_ivs := {"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31}
var base_stats := {"hp": 0, "atk": 0, "def": 0, "spa": 0, "spd": 0, "spe": 0}
var current_level := 50
var current_nature := "Hardy"

# Node references
var ev_sliders: Array[HSlider] = []
var iv_sliders: Array[HSlider] = []
var ev_labels: Array[Label] = []
var iv_labels: Array[Label] = []
var stat_labels: Array[Label] = []
var ev_total_label: Label

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the stat sliders component."""
	_create_ui()


# ==================== Public Methods ====================

func setup(pokemon_base_stats: Dictionary, level: int = 50, nature: String = "Hardy") -> void:
	"""
	Setup the sliders for a specific Pokemon.

	@param pokemon_base_stats: Dictionary with base stats
	@param level: Pokemon level (default 50)
	@param nature: Pokemon nature (default Hardy)
	"""
	base_stats = pokemon_base_stats
	current_level = level
	current_nature = nature

	# Reset to defaults
	current_evs = {"hp": 0, "atk": 0, "def": 0, "spa": 0, "spd": 0, "spe": 0}
	current_ivs = {"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31}

	_update_all_sliders()
	_update_stat_display()


func get_evs() -> Dictionary:
	"""Get current EV spread."""
	return current_evs.duplicate()


func get_ivs() -> Dictionary:
	"""Get current IV spread."""
	return current_ivs.duplicate()


func set_ev_preset(preset_name: String) -> void:
	"""Apply an EV preset."""
	if preset_name in EV_PRESETS:
		current_evs = EV_PRESETS[preset_name].duplicate()
		_update_all_sliders()
		_update_stat_display()
		stats_changed.emit(current_evs, current_ivs)


func set_all_ivs(value: int) -> void:
	"""Set all IVs to the same value."""
	for key in STAT_KEYS:
		current_ivs[key] = clampi(value, 0, MAX_IV)

	_update_all_sliders()
	_update_stat_display()
	stats_changed.emit(current_evs, current_ivs)


# ==================== UI Creation ====================

func _create_ui() -> void:
	"""Create the slider UI."""
	# Title
	var title = Label.new()
	title.text = "STAT CUSTOMIZATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# EV Presets
	_create_ev_presets()

	# EV Section
	var ev_section = Label.new()
	ev_section.text = "EVs (Effort Values)"
	add_child(ev_section)

	# EV Total Counter
	var ev_total_container = HBoxContainer.new()
	var ev_total_title = Label.new()
	ev_total_title.text = "Total EVs:"
	ev_total_container.add_child(ev_total_title)

	ev_total_label = Label.new()
	ev_total_label.text = "0 / 508"
	ev_total_container.add_child(ev_total_label)
	add_child(ev_total_container)

	# EV Sliders
	for i in range(6):
		var slider_container = _create_stat_slider("EV", STAT_NAMES[i], STAT_KEYS[i], MAX_EV_PER_STAT)
		add_child(slider_container)
		ev_sliders.append(slider_container.get_node("Slider"))
		ev_labels.append(slider_container.get_node("Value"))

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	add_child(spacer)

	# IV Section
	var iv_section = Label.new()
	iv_section.text = "IVs (Individual Values)"
	add_child(iv_section)

	# IV Quick Actions
	_create_iv_quick_actions()

	# IV Sliders
	for i in range(6):
		var slider_container = _create_stat_slider("IV", STAT_NAMES[i], STAT_KEYS[i], MAX_IV)
		add_child(slider_container)
		iv_sliders.append(slider_container.get_node("Slider"))
		iv_labels.append(slider_container.get_node("Value"))

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 16)
	add_child(spacer2)

	# Calculated Stats Section
	var stats_section = Label.new()
	stats_section.text = "Calculated Stats"
	add_child(stats_section)

	# Stat Display
	for i in range(6):
		var stat_container = HBoxContainer.new()

		var stat_name = Label.new()
		stat_name.text = STAT_NAMES[i] + ":"
		stat_name.custom_minimum_size = Vector2(60, 0)
		stat_container.add_child(stat_name)

		var stat_value = Label.new()
		stat_value.text = "0"
		stat_labels.append(stat_value)
		stat_container.add_child(stat_value)

		add_child(stat_container)


func _create_ev_presets() -> void:
	"""Create EV preset buttons."""
	var preset_container = VBoxContainer.new()

	var preset_label = Label.new()
	preset_label.text = "EV Presets:"
	preset_container.add_child(preset_label)

	var button_grid = GridContainer.new()
	button_grid.columns = 2
	button_grid.add_theme_constant_override("h_separation", 4)
	button_grid.add_theme_constant_override("v_separation", 4)

	for preset_name in EV_PRESETS.keys():
		var preset_button = Button.new()
		preset_button.text = preset_name
		preset_button.pressed.connect(_on_preset_selected.bind(preset_name))
		button_grid.add_child(preset_button)

	preset_container.add_child(button_grid)
	add_child(preset_container)


func _create_iv_quick_actions() -> void:
	"""Create IV quick action buttons."""
	var iv_actions = HBoxContainer.new()
	iv_actions.add_theme_constant_override("separation", 8)

	var all_31_button = Button.new()
	all_31_button.text = "All 31 (Perfect)"
	all_31_button.pressed.connect(_on_all_31_pressed)
	iv_actions.add_child(all_31_button)

	var all_0_button = Button.new()
	all_0_button.text = "All 0 (Trick Room)"
	all_0_button.pressed.connect(_on_all_0_pressed)
	iv_actions.add_child(all_0_button)

	add_child(iv_actions)


func _create_stat_slider(slider_type: String, stat_name: String, stat_key: String, max_value: int) -> HBoxContainer:
	"""Create a stat slider with label."""
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)

	# Stat name
	var name_label = Label.new()
	name_label.text = stat_name + ":"
	name_label.custom_minimum_size = Vector2(60, 0)
	container.add_child(name_label)

	# Slider
	var slider = HSlider.new()
	slider.name = "Slider"
	slider.min_value = 0
	slider.max_value = max_value
	slider.step = 1
	slider.value = 31 if slider_type == "IV" else 0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(200, 0)

	if slider_type == "EV":
		slider.value_changed.connect(_on_ev_changed.bind(stat_key))
	else:
		slider.value_changed.connect(_on_iv_changed.bind(stat_key))

	container.add_child(slider)

	# Value label
	var value_label = Label.new()
	value_label.name = "Value"
	value_label.text = str(slider.value)
	value_label.custom_minimum_size = Vector2(40, 0)
	container.add_child(value_label)

	return container


# ==================== Event Handlers ====================

func _on_ev_changed(value: float, stat_key: String) -> void:
	"""Handle EV slider change."""
	var new_value = int(value)

	# Calculate total EVs
	var total = 0
	for key in STAT_KEYS:
		if key == stat_key:
			total += new_value
		else:
			total += current_evs[key]

	# Enforce total limit
	if total > MAX_EV_TOTAL:
		new_value = MAX_EV_TOTAL - (total - new_value)
		var slider_index = STAT_KEYS.find(stat_key)
		ev_sliders[slider_index].value = new_value
		return

	current_evs[stat_key] = new_value

	# Update labels
	var slider_index = STAT_KEYS.find(stat_key)
	ev_labels[slider_index].text = str(new_value)

	# Update total
	ev_total_label.text = "%d / %d" % [total, MAX_EV_TOTAL]

	# Update calculated stats
	_update_stat_display()

	stats_changed.emit(current_evs, current_ivs)


func _on_iv_changed(value: float, stat_key: String) -> void:
	"""Handle IV slider change."""
	current_ivs[stat_key] = int(value)

	# Update label
	var slider_index = STAT_KEYS.find(stat_key)
	iv_labels[slider_index].text = str(int(value))

	# Update calculated stats
	_update_stat_display()

	stats_changed.emit(current_evs, current_ivs)


func _on_preset_selected(preset_name: String) -> void:
	"""Handle preset button press."""
	set_ev_preset(preset_name)


func _on_all_31_pressed() -> void:
	"""Set all IVs to 31."""
	set_all_ivs(31)


func _on_all_0_pressed() -> void:
	"""Set all IVs to 0."""
	set_all_ivs(0)


# ==================== Stat Calculation ====================

func _update_all_sliders() -> void:
	"""Update all slider values from current data."""
	for i in range(6):
		var stat_key = STAT_KEYS[i]
		ev_sliders[i].value = current_evs[stat_key]
		iv_sliders[i].value = current_ivs[stat_key]
		ev_labels[i].text = str(current_evs[stat_key])
		iv_labels[i].text = str(current_ivs[stat_key])

	# Update EV total
	var total_evs = 0
	for value in current_evs.values():
		total_evs += value
	ev_total_label.text = "%d / %d" % [total_evs, MAX_EV_TOTAL]


func _update_stat_display() -> void:
	"""Calculate and display final stats."""
	for i in range(6):
		var stat_key = STAT_KEYS[i]
		var calculated_stat = _calculate_stat(stat_key)
		stat_labels[i].text = str(calculated_stat)


func _calculate_stat(stat_key: String) -> int:
	"""
	Calculate final stat value.
	Uses Pokemon stat formula:
	HP = floor(((2 * Base + IV + floor(EV/4)) * Level) / 100) + Level + 10
	Other = floor((floor(((2 * Base + IV + floor(EV/4)) * Level) / 100) + 5) * Nature)
	"""
	var base = base_stats.get(stat_key, 0)
	var iv = current_ivs.get(stat_key, 31)
	var ev = current_evs.get(stat_key, 0)
	var level = current_level

	if stat_key == "hp":
		# HP formula
		return int(((2 * base + iv + int(ev / 4)) * level) / 100.0) + level + 10
	else:
		# Other stats formula
		var stat = int(((2 * base + iv + int(ev / 4)) * level) / 100.0) + 5

		# Apply nature modifier
		var nature_mod = _get_nature_modifier(stat_key)
		return int(stat * nature_mod)


func _get_nature_modifier(stat_key: String) -> float:
	"""Get nature modifier for a stat (0.9, 1.0, or 1.1)."""
	# Nature modifiers (simplified - would need full nature data)
	# For now, return 1.0 (neutral)
	# TODO: Implement full nature system
	return 1.0
