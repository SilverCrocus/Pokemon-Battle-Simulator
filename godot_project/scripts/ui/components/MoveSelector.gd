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
var current_pokemon_data = null  # Current Pokemon being edited

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
	current_pokemon_data = pokemon_data
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

	# Auto-fill button
	var autofill_button = Button.new()
	autofill_button.text = "⚡ Auto-Fill Meta Moveset"
	autofill_button.tooltip_text = "Automatically select competitive moves for this Pokemon"
	autofill_button.pressed.connect(_on_autofill_pressed)
	main_container.add_child(autofill_button)

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
			if existing_move and existing_move.move_id == move_data.move_id:
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


func _on_autofill_pressed() -> void:
	"""Auto-fill meta moveset for the current Pokemon."""
	if not current_pokemon_data:
		return

	var meta_moves = _get_meta_moveset(current_pokemon_data.national_dex_number)

	if meta_moves.is_empty():
		# Fallback: select highest power STAB moves
		meta_moves = _get_fallback_moveset(current_pokemon_data)

	# Emit signals for each move
	for move_name in meta_moves:
		# Find the move data by name (MoveData uses .name, not .identifier)
		for move_data in all_legal_moves:
			if move_data.name.to_lower().replace(" ", "-") == move_name:
				move_selected.emit(move_data)
				break

	hide()


func _get_meta_moveset(national_dex_number: int) -> Array:
	"""
	Get competitive moveset for a Pokemon by National Dex number.
	Returns array of move identifiers (e.g., ["thunderbolt", "ice-beam"]).
	"""
	# Meta movesets database - Gen 1-3 competitive sets
	var meta_movesets = {
		# Gen 1 Starters
		3: ["sludge-bomb", "earthquake", "sleep-powder", "hidden-power"],  # Venusaur
		6: ["fire-blast", "air-slash", "dragon-pulse", "roost"],  # Charizard
		9: ["surf", "ice-beam", "rapid-spin", "toxic"],  # Blastoise

		# Gen 1 Legendaries
		144: ["ice-beam", "hurricane", "roost", "u-turn"],  # Articuno
		145: ["thunderbolt", "heat-wave", "roost", "volt-switch"],  # Zapdos
		146: ["fire-blast", "hurricane", "roost", "u-turn"],  # Moltres
		150: ["psystrike", "ice-beam", "aura-sphere", "recover"],  # Mewtwo
		151: ["psychic", "ice-beam", "thunderbolt", "u-turn"],  # Mew

		# Gen 1 Popular
		25: ["thunderbolt", "surf", "hidden-power", "volt-switch"],  # Pikachu
		94: ["shadow-ball", "sludge-bomb", "focus-blast", "thunderbolt"],  # Gengar
		130: ["waterfall", "ice-fang", "earthquake", "dragon-dance"],  # Gyarados
		131: ["surf", "ice-beam", "thunderbolt", "recover"],  # Lapras
		143: ["body-slam", "earthquake", "fire-blast", "rest"],  # Snorlax

		# Gen 2 Starters
		154: ["leaf-blade", "earthquake", "synthesis", "hidden-power"],  # Meganium
		157: ["eruption", "fire-blast", "earthquake", "hidden-power"],  # Typhlosion
		160: ["waterfall", "ice-punch", "earthquake", "dragon-dance"],  # Feraligatr

		# Gen 2 Legendaries
		243: ["thunderbolt", "volt-switch", "hidden-power", "extreme-speed"],  # Raikou
		244: ["fire-blast", "eruption", "hidden-power", "extreme-speed"],  # Entei
		245: ["surf", "ice-beam", "calm-mind", "rest"],  # Suicune
		249: ["aeroblast", "earthquake", "recover", "toxic"],  # Lugia
		250: ["sacred-fire", "earthquake", "brave-bird", "recover"],  # Ho-Oh

		# Gen 2 Popular
		181: ["thunderbolt", "volt-switch", "focus-blast", "cotton-guard"],  # Ampharos
		186: ["surf", "ice-beam", "focus-blast", "toxic"],  # Politoed
		197: ["foul-play", "toxic", "moonlight", "protect"],  # Umbreon
		248: ["stone-edge", "crunch", "earthquake", "dragon-dance"],  # Tyranitar

		# Gen 3 Starters
		254: ["leaf-blade", "dragon-claw", "earthquake", "swords-dance"],  # Sceptile
		257: ["fire-blast", "focus-blast", "hidden-power", "earthquake"],  # Blaziken
		260: ["surf", "ice-beam", "earthquake", "stealth-rock"],  # Swampert

		# Gen 3 Legendaries & Dragons
		373: ["outrage", "earthquake", "fire-blast", "dragon-dance"],  # Salamence
		376: ["meteor-mash", "earthquake", "zen-headbutt", "bullet-punch"],  # Metagross
		380: ["psychic", "surf", "ice-beam", "calm-mind"],  # Latias
		381: ["draco-meteor", "psychic", "surf", "roost"],  # Latios
		382: ["water-spout", "ice-beam", "thunder", "origin-pulse"],  # Kyogre
		383: ["precipice-blades", "stone-edge", "fire-punch", "swords-dance"],  # Groudon
		384: ["dragon-ascent", "extreme-speed", "earthquake", "dragon-claw"],  # Rayquaza

		# Gen 3 Popular
		282: ["psychic", "moonblast", "thunderbolt", "calm-mind"],  # Gardevoir
		289: ["facade", "earthquake", "shadow-claw", "slack-off"],  # Slaking
		306: ["iron-head", "earthquake", "stone-edge", "rock-polish"],  # Aggron
		350: ["surf", "ice-beam", "recover", "scald"],  # Milotic
	}

	if national_dex_number in meta_movesets:
		return meta_movesets[national_dex_number]

	return []


func _get_fallback_moveset(pokemon_data) -> Array:
	"""
	Generate fallback moveset based on stats and types.
	Selects highest power STAB moves + coverage.
	"""
	var stab_moves = []
	var coverage_moves = []

	# Get Pokemon types
	var types = [pokemon_data.type1]
	if pokemon_data.type2 and pokemon_data.type2 != "":
		types.append(pokemon_data.type2)

	# Find STAB moves (Same Type Attack Bonus)
	for move_data in all_legal_moves:
		if move_data.type in types and move_data.power and move_data.power > 0:
			stab_moves.append({"move": move_data.name.to_lower().replace(" ", "-"), "power": move_data.power})

	# Find coverage moves (different types with high power)
	for move_data in all_legal_moves:
		if move_data.type not in types and move_data.power and move_data.power >= 70:
			coverage_moves.append({"move": move_data.name.to_lower().replace(" ", "-"), "power": move_data.power})

	# Sort by power
	stab_moves.sort_custom(func(a, b): return a.power > b.power)
	coverage_moves.sort_custom(func(a, b): return a.power > b.power)

	# Build moveset: 2 STAB + 2 coverage
	var result = []
	for i in range(min(2, stab_moves.size())):
		result.append(stab_moves[i].move)

	for i in range(min(2, coverage_moves.size())):
		result.append(coverage_moves[i].move)

	# Fill remaining slots with any high power moves
	while result.size() < 4 and coverage_moves.size() > result.size() - 2:
		var idx = result.size() - 2
		if idx < coverage_moves.size():
			result.append(coverage_moves[idx].move)
		else:
			break

	return result
