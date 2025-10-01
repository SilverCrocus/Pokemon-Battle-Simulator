extends AcceptDialog

## Move Selector Dialog
##
## Popup dialog for selecting moves from a Pokemon's learnset.
## Includes filtering by type, category, and search functionality.

# ==================== Signals ====================

signal move_selected(move_data)

# ==================== Constants ====================

const MOVE_CATEGORIES := ["All", "Physical", "Special", "Status"]
const MOVE_TYPES := [
	"All", "normal", "fire", "water", "electric", "grass", "ice",
	"fighting", "poison", "ground", "flying", "psychic", "bug",
	"rock", "ghost", "dragon", "dark", "steel", "fairy"
]

# ==================== Node References ====================

var search_bar: LineEdit
var type_filter: OptionButton
var category_filter: OptionButton
var move_list: VBoxContainer
var move_scroll: ScrollContainer
var details_panel: PanelContainer
var move_name_label: Label
var move_type_label: Label
var move_category_label: Label
var move_power_label: Label
var move_accuracy_label: Label
var move_pp_label: Label
var move_effect_label: Label

# ==================== State ====================

var pokemon_learnset: Array = []  # Array of move IDs the Pokemon can learn
var all_legal_moves: Array = []  # Array of move data objects
var filtered_moves: Array = []
var selected_move = null
var existing_moves: Array = []  # Moves already selected (to prevent duplicates)

# ==================== Lifecycle ====================

func _init() -> void:
	"""Initialize the dialog."""
	title = "Select Move"
	dialog_hide_on_ok = false
	size = Vector2(800, 600)
	add_cancel_button("Cancel")

	confirmed.connect(_on_ok_pressed)
	canceled.connect(_on_cancel_pressed)


func _ready() -> void:
	"""Setup the UI when added to scene tree."""
	_create_ui()


# ==================== Public Methods ====================

func open_for_pokemon(pokemon_data, current_moves: Array) -> void:
	"""
	Open the move selector for a specific Pokemon.

	@param pokemon_data: Pokemon species data
	@param current_moves: Array of already selected moves
	"""
	existing_moves = current_moves.duplicate()

	# Get Pokemon's learnset
	pokemon_learnset = _get_pokemon_learnset(pokemon_data)

	# Load all legal moves
	all_legal_moves.clear()
	for move_id in pokemon_learnset:
		var move_data = DataManager.get_move(move_id)
		if move_data:
			all_legal_moves.append(move_data)

	# Sort by name
	all_legal_moves.sort_custom(func(a, b): return a.name < b.name)

	filtered_moves = all_legal_moves.duplicate()
	_populate_move_list()

	popup_centered()


# ==================== UI Creation ====================

func _create_ui() -> void:
	"""Create the dialog UI."""
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)

	# Search and filters
	var filter_container = HBoxContainer.new()
	filter_container.add_theme_constant_override("separation", 8)

	# Search bar
	search_bar = LineEdit.new()
	search_bar.placeholder_text = "Search moves..."
	search_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_bar.text_changed.connect(_on_search_changed)
	filter_container.add_child(search_bar)

	# Type filter
	type_filter = OptionButton.new()
	for type_name in MOVE_TYPES:
		type_filter.add_item(type_name.capitalize())
	type_filter.item_selected.connect(_on_filter_changed)
	filter_container.add_child(type_filter)

	# Category filter
	category_filter = OptionButton.new()
	for category in MOVE_CATEGORIES:
		category_filter.add_item(category)
	category_filter.item_selected.connect(_on_filter_changed)
	filter_container.add_child(category_filter)

	main_container.add_child(filter_container)

	# Content area (list + details)
	var content_split = HSplitContainer.new()
	content_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_split.split_offset = 400

	# Move list (left side)
	move_scroll = ScrollContainer.new()
	move_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	move_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	move_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	move_list = VBoxContainer.new()
	move_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	move_list.add_theme_constant_override("separation", 4)
	move_scroll.add_child(move_list)

	content_split.add_child(move_scroll)

	# Details panel (right side)
	details_panel = PanelContainer.new()
	details_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var details_margin = MarginContainer.new()
	details_margin.add_theme_constant_override("margin_left", 12)
	details_margin.add_theme_constant_override("margin_top", 12)
	details_margin.add_theme_constant_override("margin_right", 12)
	details_margin.add_theme_constant_override("margin_bottom", 12)
	details_panel.add_child(details_margin)

	var details_vbox = VBoxContainer.new()
	details_vbox.add_theme_constant_override("separation", 8)
	details_margin.add_child(details_vbox)

	# Details labels
	var details_title = Label.new()
	details_title.text = "Move Details"
	details_title.add_theme_font_size_override("font_size", 18)
	details_vbox.add_child(details_title)

	move_name_label = Label.new()
	move_name_label.text = "Select a move"
	move_name_label.add_theme_font_size_override("font_size", 16)
	details_vbox.add_child(move_name_label)

	move_type_label = Label.new()
	move_type_label.text = "Type: -"
	details_vbox.add_child(move_type_label)

	move_category_label = Label.new()
	move_category_label.text = "Category: -"
	details_vbox.add_child(move_category_label)

	move_power_label = Label.new()
	move_power_label.text = "Power: -"
	details_vbox.add_child(move_power_label)

	move_accuracy_label = Label.new()
	move_accuracy_label.text = "Accuracy: -"
	details_vbox.add_child(move_accuracy_label)

	move_pp_label = Label.new()
	move_pp_label.text = "PP: -"
	details_vbox.add_child(move_pp_label)

	var effect_title = Label.new()
	effect_title.text = "Effect:"
	effect_title.add_theme_font_size_override("font_size", 14)
	details_vbox.add_child(effect_title)

	move_effect_label = Label.new()
	move_effect_label.text = "No move selected"
	move_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	move_effect_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_vbox.add_child(move_effect_label)

	content_split.add_child(details_panel)
	main_container.add_child(content_split)


func _populate_move_list() -> void:
	"""Populate the move list with filtered moves."""
	# Clear existing
	for child in move_list.get_children():
		child.queue_free()

	# Add move buttons
	for move_data in filtered_moves:
		var move_button = Button.new()
		move_button.custom_minimum_size = Vector2(0, 40)
		move_button.text = move_data.name.capitalize()
		move_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		move_button.pressed.connect(_on_move_button_pressed.bind(move_data))

		# Check if already selected
		var is_duplicate = false
		for existing_move in existing_moves:
			if existing_move and existing_move.id == move_data.id:
				is_duplicate = true
				move_button.disabled = true
				move_button.text += " (Already Selected)"
				break

		# Style by type
		if not is_duplicate:
			var type_color = BattleTheme.get_type_color(move_data.type)
			var style = StyleBoxFlat.new()
			style.bg_color = type_color.darkened(0.4)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = type_color
			move_button.add_theme_stylebox_override("normal", style)

		move_list.add_child(move_button)


# ==================== Event Handlers ====================

func _on_search_changed(_new_text: String) -> void:
	"""Handle search text change."""
	_apply_filters()


func _on_filter_changed(_index: int) -> void:
	"""Handle filter selection change."""
	_apply_filters()


func _apply_filters() -> void:
	"""Apply all active filters."""
	filtered_moves.clear()

	var search_text = search_bar.text.to_lower()
	var type_idx = type_filter.selected
	var category_idx = category_filter.selected

	for move_data in all_legal_moves:
		# Search filter
		if not search_text.is_empty():
			if not move_data.name.to_lower().contains(search_text):
				continue

		# Type filter
		if type_idx > 0:
			var type_name = MOVE_TYPES[type_idx]
			if move_data.type != type_name:
				continue

		# Category filter
		if category_idx > 0:
			var category_name = MOVE_CATEGORIES[category_idx].to_lower()
			if move_data.damage_class != category_name:
				continue

		filtered_moves.append(move_data)

	_populate_move_list()


func _on_move_button_pressed(move_data) -> void:
	"""Handle move button press."""
	selected_move = move_data
	_update_details_panel(move_data)


func _update_details_panel(move_data) -> void:
	"""Update the details panel with move info."""
	move_name_label.text = move_data.name.capitalize()
	move_type_label.text = "Type: %s" % move_data.type.capitalize()
	move_category_label.text = "Category: %s" % move_data.damage_class.capitalize()

	# Power
	if move_data.power == 0:
		move_power_label.text = "Power: -"
	else:
		move_power_label.text = "Power: %d" % move_data.power

	# Accuracy
	if move_data.accuracy == 0:
		move_accuracy_label.text = "Accuracy: -"
	else:
		move_accuracy_label.text = "Accuracy: %d%%" % move_data.accuracy

	# PP
	move_pp_label.text = "PP: %d" % move_data.pp

	# Effect
	var effect_text = move_data.get("effect_text", "No description available")
	if effect_text.is_empty():
		effect_text = "No description available"
	move_effect_label.text = effect_text


func _on_ok_pressed() -> void:
	"""Handle OK button press."""
	if selected_move:
		move_selected.emit(selected_move)
		hide()


func _on_cancel_pressed() -> void:
	"""Handle Cancel button press."""
	hide()


# ==================== Helper Methods ====================

func _get_pokemon_learnset(pokemon_data) -> Array:
	"""
	Get all moves a Pokemon can learn.
	For now, returns a simplified learnset.
	TODO: Load from actual learnset data
	"""
	# Temporary: Return all moves for testing
	# In production, this would filter by actual learnset data
	var all_move_ids = []

	# Get all moves (1-919 in Gen 9)
	# For now, limit to common moves for testing
	for i in range(1, 200):
		var move = DataManager.get_move(i)
		if move:
			all_move_ids.append(i)

	return all_move_ids
