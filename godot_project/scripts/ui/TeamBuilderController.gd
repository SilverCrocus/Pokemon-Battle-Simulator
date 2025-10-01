extends Control

## Team Builder Controller
##
## Main controller for the Pokemon team building interface.
## Manages team creation, Pokemon customization, and save/load functionality.

# ==================== Constants ====================

const NATURES := [
	"Hardy", "Lonely", "Brave", "Adamant", "Naughty",
	"Bold", "Docile", "Relaxed", "Impish", "Lax",
	"Timid", "Hasty", "Serious", "Jolly", "Naive",
	"Modest", "Mild", "Quiet", "Bashful", "Rash",
	"Calm", "Gentle", "Sassy", "Careful", "Quirky"
]

const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")
const StatSlidersScript = preload("res://scripts/ui/components/StatSliders.gd")
const MoveSelectorScript = preload("res://scripts/ui/components/MoveSelector.gd")

# ==================== Node References ====================

# Left Panel - Pokemon Browser
@onready var search_bar: LineEdit = $MainContainer/LeftPanel/MarginContainer/VBoxContainer/SearchBar
@onready var type_filter: OptionButton = $MainContainer/LeftPanel/MarginContainer/VBoxContainer/FilterContainer/TypeFilter
@onready var gen_filter: OptionButton = $MainContainer/LeftPanel/MarginContainer/VBoxContainer/FilterContainer/GenFilter
@onready var pokemon_grid: GridContainer = $MainContainer/LeftPanel/MarginContainer/VBoxContainer/PokemonScroll/PokemonGrid

# Center Panel - Pokemon Editor
@onready var pokemon_name_label: Label = $MainContainer/CenterPanel/MarginContainer/VBoxContainer/PokemonName
@onready var level_spinbox: SpinBox = $MainContainer/CenterPanel/MarginContainer/VBoxContainer/EditorScroll/EditorContent/BasicInfoSection/LevelContainer/LevelSpinBox
@onready var nickname_edit: LineEdit = $MainContainer/CenterPanel/MarginContainer/VBoxContainer/EditorScroll/EditorContent/BasicInfoSection/NicknameContainer/NicknameEdit
@onready var nature_select: OptionButton = $MainContainer/CenterPanel/MarginContainer/VBoxContainer/EditorScroll/EditorContent/NatureSection/NatureSelect
@onready var ability_select: OptionButton = $MainContainer/CenterPanel/MarginContainer/VBoxContainer/EditorScroll/EditorContent/AbilitySection/AbilitySelect
@onready var item_select: OptionButton = $MainContainer/CenterPanel/MarginContainer/VBoxContainer/EditorScroll/EditorContent/ItemSection/ItemSelect
@onready var move_buttons: Array[Button] = [
	$MainContainer/CenterPanel/MarginContainer/VBoxContainer/EditorScroll/EditorContent/MovesSection/MovesGrid/Move1,
	$MainContainer/CenterPanel/MarginContainer/VBoxContainer/EditorScroll/EditorContent/MovesSection/MovesGrid/Move2,
	$MainContainer/CenterPanel/MarginContainer/VBoxContainer/EditorScroll/EditorContent/MovesSection/MovesGrid/Move3,
	$MainContainer/CenterPanel/MarginContainer/VBoxContainer/EditorScroll/EditorContent/MovesSection/MovesGrid/Move4
]
@onready var clear_button: Button = $MainContainer/CenterPanel/MarginContainer/VBoxContainer/ActionButtons/ClearButton
@onready var add_to_team_button: Button = $MainContainer/CenterPanel/MarginContainer/VBoxContainer/ActionButtons/AddToTeamButton
@onready var stat_sliders_container: VBoxContainer = $MainContainer/CenterPanel/MarginContainer/VBoxContainer/EditorScroll/EditorContent/StatSlidersContainer

# Right Panel - Team Preview
@onready var team_slots: Array[PanelContainer] = [
	$MainContainer/RightPanel/MarginContainer/VBoxContainer/TeamSlots/Slot1,
	$MainContainer/RightPanel/MarginContainer/VBoxContainer/TeamSlots/Slot2,
	$MainContainer/RightPanel/MarginContainer/VBoxContainer/TeamSlots/Slot3,
	$MainContainer/RightPanel/MarginContainer/VBoxContainer/TeamSlots/Slot4,
	$MainContainer/RightPanel/MarginContainer/VBoxContainer/TeamSlots/Slot5,
	$MainContainer/RightPanel/MarginContainer/VBoxContainer/TeamSlots/Slot6
]
@onready var save_button: Button = $MainContainer/RightPanel/MarginContainer/VBoxContainer/TeamActions/SaveButton
@onready var load_button: Button = $MainContainer/RightPanel/MarginContainer/VBoxContainer/TeamActions/LoadButton

# ==================== State ====================

var all_pokemon: Array = []
var filtered_pokemon: Array = []
var current_pokemon = null  # Currently selected Pokemon species data
var current_moves: Array = []  # Array of selected moves (max 4)
var team: Array = []  # Array of BattlePokemon instances (max 6)
var stat_sliders = null  # StatSliders component instance
var move_selector = null  # MoveSelector dialog instance
var current_move_slot: int = -1  # Currently editing move slot

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the team builder."""
	_setup_styling()
	_setup_filters()
	_setup_stat_sliders()
	_setup_move_selector()
	_connect_signals()
	_load_pokemon_data()
	_populate_pokemon_browser()


# ==================== Setup Methods ====================

func _setup_styling() -> void:
	"""Apply Gen 5 visual styling."""
	# Panel backgrounds
	for panel in [$MainContainer/LeftPanel, $MainContainer/CenterPanel, $MainContainer/RightPanel]:
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
		panel.add_theme_stylebox_override("panel", style_box)


func _setup_filters() -> void:
	"""Setup filter dropdowns."""
	# Type filter
	type_filter.clear()
	type_filter.add_item("All Types")
	for type_name in ["normal", "fire", "water", "electric", "grass", "ice",
					  "fighting", "poison", "ground", "flying", "psychic", "bug",
					  "rock", "ghost", "dragon", "dark", "steel", "fairy"]:
		type_filter.add_item(type_name.capitalize())

	# Generation filter
	gen_filter.clear()
	gen_filter.add_item("All Gens")
	for i in range(1, 10):
		gen_filter.add_item("Gen %d" % i)

	# Nature dropdown
	nature_select.clear()
	for nature in NATURES:
		nature_select.add_item(nature)


func _setup_stat_sliders() -> void:
	"""Create and setup the StatSliders component."""
	stat_sliders = StatSlidersScript.new()
	stat_sliders_container.add_child(stat_sliders)
	stat_sliders.stats_changed.connect(_on_stats_changed)


func _setup_move_selector() -> void:
	"""Create and setup the MoveSelector dialog."""
	move_selector = MoveSelectorScript.new()
	add_child(move_selector)
	move_selector.move_selected.connect(_on_move_selected)


func _connect_signals() -> void:
	"""Connect UI signals."""
	search_bar.text_changed.connect(_on_search_changed)
	type_filter.item_selected.connect(_on_filter_changed)
	gen_filter.item_selected.connect(_on_filter_changed)

	clear_button.pressed.connect(_on_clear_pressed)
	add_to_team_button.pressed.connect(_on_add_to_team_pressed)

	save_button.pressed.connect(_on_save_team_pressed)
	load_button.pressed.connect(_on_load_team_pressed)

	# Move buttons
	for i in range(4):
		move_buttons[i].pressed.connect(_on_move_button_pressed.bind(i))


# ==================== Data Loading ====================

func _load_pokemon_data() -> void:
	"""Load all Pokemon from DataManager."""
	print("[TeamBuilder] Loading Pokemon data...")

	# For now, load a subset for testing
	# TODO: Implement pagination or lazy loading for all 1,302
	for id in range(1, 152):  # Gen 1 for now
		var pokemon_data = DataManager.get_pokemon(id)
		if pokemon_data:
			all_pokemon.append(pokemon_data)

	filtered_pokemon = all_pokemon.duplicate()
	print("[TeamBuilder] Loaded %d Pokemon" % all_pokemon.size())


func _populate_pokemon_browser() -> void:
	"""Populate the Pokemon browser grid."""
	# Clear existing
	for child in pokemon_grid.get_children():
		child.queue_free()

	# Add Pokemon cards
	for pokemon_data in filtered_pokemon:
		var card = _create_pokemon_card(pokemon_data)
		pokemon_grid.add_child(card)


func _create_pokemon_card(pokemon_data) -> Button:
	"""Create a Pokemon card button."""
	var card = Button.new()
	card.custom_minimum_size = Vector2(160, 60)
	card.text = "#%03d %s" % [pokemon_data.national_dex_number, pokemon_data.name.capitalize()]
	card.pressed.connect(_on_pokemon_selected.bind(pokemon_data))

	# Style based on type
	var type_color = BattleTheme.get_type_color(pokemon_data.type1)
	var style = StyleBoxFlat.new()
	style.bg_color = type_color.darkened(0.3)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = type_color
	card.add_theme_stylebox_override("normal", style)

	return card


# ==================== Filter & Search ====================

func _on_search_changed(new_text: String) -> void:
	"""Handle search text change."""
	_apply_filters()


func _on_filter_changed(_index: int) -> void:
	"""Handle filter selection change."""
	_apply_filters()


func _apply_filters() -> void:
	"""Apply all active filters."""
	filtered_pokemon.clear()

	var search_text = search_bar.text.to_lower()
	var type_idx = type_filter.selected
	var gen_idx = gen_filter.selected

	for pokemon_data in all_pokemon:
		# Search filter
		if not search_text.is_empty():
			if not pokemon_data.name.to_lower().contains(search_text):
				if not str(pokemon_data.national_dex_number).contains(search_text):
					continue

		# Type filter
		if type_idx > 0:
			var type_name = type_filter.get_item_text(type_idx).to_lower()
			if pokemon_data.type1 != type_name and pokemon_data.type2 != type_name:
				continue

		# Generation filter (TODO: add gen data to Pokemon)
		# For now, approximate by dex number
		if gen_idx > 0:
			var gen_ranges = [0, 151, 251, 386, 493, 649, 721, 809, 905, 1025]
			var gen = gen_idx
			if pokemon_data.national_dex_number < gen_ranges[gen - 1] or pokemon_data.national_dex_number > gen_ranges[gen]:
				continue

		filtered_pokemon.append(pokemon_data)

	_populate_pokemon_browser()


# ==================== Pokemon Selection & Editing ====================

func _on_pokemon_selected(pokemon_data) -> void:
	"""Handle Pokemon selection from browser."""
	current_pokemon = pokemon_data
	current_moves.clear()

	# Update UI
	pokemon_name_label.text = "#%03d %s" % [pokemon_data.national_dex_number, pokemon_data.name.to_upper()]

	# Load abilities
	_load_abilities(pokemon_data)

	# Reset moves
	for button in move_buttons:
		button.text = "- Select Move -"

	# Setup stat sliders with Pokemon base stats
	if stat_sliders:
		var base_stats = {
			"hp": pokemon_data.hp,
			"atk": pokemon_data.attack,
			"def": pokemon_data.defense,
			"spa": pokemon_data.special_attack,
			"spd": pokemon_data.special_defense,
			"spe": pokemon_data.speed
		}
		stat_sliders.setup(base_stats, int(level_spinbox.value), NATURES[nature_select.selected])

	# Enable editor
	add_to_team_button.disabled = false

	print("[TeamBuilder] Selected: %s" % pokemon_data.name)


func _load_abilities(pokemon_data) -> void:
	"""Load abilities for the selected Pokemon."""
	ability_select.clear()

	# Add abilities from species data
	if pokemon_data.abilities and pokemon_data.abilities.size() > 0:
		for ability_name in pokemon_data.abilities:
			ability_select.add_item(ability_name)
	else:
		ability_select.add_item("No Ability")

	# Add hidden ability if available
	if pokemon_data.hidden_ability and not pokemon_data.hidden_ability.is_empty():
		ability_select.add_item(pokemon_data.hidden_ability + " (Hidden)")


func _on_move_button_pressed(slot: int) -> void:
	"""Handle move button press."""
	if not current_pokemon:
		return

	if not move_selector:
		print("[TeamBuilder] Error: MoveSelector not initialized")
		return

	# Store which slot we're editing
	current_move_slot = slot

	# Open move selector with current Pokemon and existing moves
	move_selector.open_for_pokemon(current_pokemon, current_moves)
	print("[TeamBuilder] Opened move selector for slot %d" % slot)


func _on_clear_pressed() -> void:
	"""Clear the current Pokemon editor."""
	current_pokemon = null
	current_moves.clear()
	pokemon_name_label.text = "Select a Pokemon"

	for button in move_buttons:
		button.text = "- Select Move -"

	add_to_team_button.disabled = true


func _on_add_to_team_pressed() -> void:
	"""Add current Pokemon to team."""
	if not current_pokemon:
		return

	if team.size() >= 6:
		print("[TeamBuilder] Team is full (6/6)")
		return

	# Get current customization
	var level = int(level_spinbox.value)
	var nature = NATURES[nature_select.selected]
	var ability = ability_select.get_item_text(ability_select.selected)
	var nickname = nickname_edit.text if not nickname_edit.text.is_empty() else ""

	# Get EVs and IVs from stat sliders
	var evs = stat_sliders.get_evs() if stat_sliders else {"hp": 0, "atk": 0, "def": 0, "spa": 0, "spd": 0, "spe": 0}
	var ivs = stat_sliders.get_ivs() if stat_sliders else {"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31}

	# Ensure we have 4 moves (fill with defaults if needed)
	var moves_to_use = current_moves.duplicate()
	while moves_to_use.size() < 4:
		var tackle = DataManager.get_move(33)  # Tackle as default
		if tackle:
			moves_to_use.append(tackle)

	# Create BattlePokemon
	var battle_pokemon = BattlePokemonScript.new(
		current_pokemon,
		level,
		ivs,
		evs,
		nature,
		moves_to_use,
		ability if not ability.ends_with("(Hidden)") else ability.trim_suffix(" (Hidden)"),
		"",  # No item for now
		nickname
	)

	# Add to team
	team.append(battle_pokemon)
	_update_team_display()

	print("[TeamBuilder] Added %s to team (%d/6)" % [current_pokemon.name, team.size()])


func _on_stats_changed(evs: Dictionary, ivs: Dictionary) -> void:
	"""Handle stat slider changes."""
	# Stats are automatically calculated and displayed by StatSliders component
	# This handler can be used for additional validation or UI updates if needed
	pass


func _on_move_selected(move_data) -> void:
	"""Handle move selection from MoveSelector dialog."""
	if current_move_slot < 0 or current_move_slot >= 4:
		return

	# Resize array if needed
	if current_move_slot >= current_moves.size():
		current_moves.resize(current_move_slot + 1)

	# Set the move
	current_moves[current_move_slot] = move_data
	move_buttons[current_move_slot].text = move_data.name.to_upper()

	# Color by type
	var type_color = BattleTheme.get_type_color(move_data.type)
	var style = StyleBoxFlat.new()
	style.bg_color = type_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = type_color.lightened(0.3)
	move_buttons[current_move_slot].add_theme_stylebox_override("normal", style)

	print("[TeamBuilder] Selected move %s for slot %d" % [move_data.name, current_move_slot])


# ==================== Team Management ====================

func _update_team_display() -> void:
	"""Update the team preview panel."""
	for i in range(6):
		# Clear existing children except Label
		for child in team_slots[i].get_children():
			if child.name != "Label":
				child.queue_free()

		var slot_label = team_slots[i].get_node("Label") as Label

		if i < team.size():
			var pokemon = team[i]
			var display_name = pokemon.nickname if not pokemon.nickname.is_empty() else pokemon.species.name.capitalize()
			slot_label.text = "%s Lv.%d" % [display_name, pokemon.level]

			# Add remove button
			if not team_slots[i].has_node("RemoveButton"):
				var remove_button = Button.new()
				remove_button.name = "RemoveButton"
				remove_button.text = "X"
				remove_button.custom_minimum_size = Vector2(30, 30)
				remove_button.position = Vector2(team_slots[i].size.x - 40, 10)
				remove_button.pressed.connect(_on_team_slot_remove.bind(i))
				team_slots[i].add_child(remove_button)

			# Make slot clickable
			if not team_slots[i].has_meta("slot_index"):
				team_slots[i].set_meta("slot_index", i)
				team_slots[i].gui_input.connect(_on_team_slot_clicked.bind(i))
		else:
			slot_label.text = "Empty Slot"


func _on_save_team_pressed() -> void:
	"""Save the current team to JSON."""
	if team.is_empty():
		print("[TeamBuilder] No team to save")
		return

	var team_data = {
		"name": "My Team",
		"format": "OU",
		"pokemon": []
	}

	for pokemon in team:
		team_data.pokemon.append({
			"species_id": pokemon.species.national_dex_number,
			"nickname": pokemon.nickname,
			"level": pokemon.level,
			"nature": pokemon.nature,
			"ability": pokemon.ability,
			"item": pokemon.item,
			"moves": pokemon.moves.map(func(m): return m.id),
			"evs": pokemon.evs,
			"ivs": pokemon.ivs
		})

	var json_string = JSON.stringify(team_data, "\t")
	var file = FileAccess.open("user://team.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[TeamBuilder] Team saved to user://team.json")
	else:
		print("[TeamBuilder] Failed to save team")


func _on_load_team_pressed() -> void:
	"""Load a team from JSON."""
	var file = FileAccess.open("user://team.json", FileAccess.READ)
	if not file:
		print("[TeamBuilder] No saved team found")
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("[TeamBuilder] Failed to parse team JSON")
		return

	var team_data = json.data
	if not team_data or not team_data.has("pokemon"):
		print("[TeamBuilder] Invalid team data")
		return

	# Clear current team
	team.clear()

	# Load each Pokemon
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

	_update_team_display()
	print("[TeamBuilder] Loaded team with %d Pokemon" % team.size())


func _on_team_slot_clicked(event: InputEvent, slot_index: int) -> void:
	"""Handle clicking on a team slot to edit that Pokemon."""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if slot_index < team.size():
			_load_pokemon_into_editor(team[slot_index])
			print("[TeamBuilder] Editing team slot %d" % slot_index)


func _on_team_slot_remove(slot_index: int) -> void:
	"""Remove Pokemon from team slot."""
	if slot_index < team.size():
		var removed_pokemon = team[slot_index]
		team.remove_at(slot_index)
		_update_team_display()
		print("[TeamBuilder] Removed %s from team (%d/6)" % [removed_pokemon.species.name, team.size()])


func _load_pokemon_into_editor(battle_pokemon) -> void:
	"""Load a BattlePokemon from the team into the editor."""
	# Set current Pokemon
	current_pokemon = battle_pokemon.species

	# Update UI
	pokemon_name_label.text = "#%03d %s" % [current_pokemon.national_dex_number, current_pokemon.name.to_upper()]

	# Set level
	level_spinbox.value = battle_pokemon.level

	# Set nickname
	nickname_edit.text = battle_pokemon.nickname

	# Set nature
	var nature_index = NATURES.find(battle_pokemon.nature)
	if nature_index >= 0:
		nature_select.selected = nature_index

	# Load abilities and select current
	_load_abilities(current_pokemon)
	for i in range(ability_select.item_count):
		var ability_text = ability_select.get_item_text(i)
		if ability_text == battle_pokemon.ability or ability_text == battle_pokemon.ability + " (Hidden)":
			ability_select.selected = i
			break

	# Load moves
	current_moves = battle_pokemon.moves.duplicate()
	for i in range(4):
		if i < current_moves.size() and current_moves[i]:
			move_buttons[i].text = current_moves[i].name.to_upper()
			var type_color = BattleTheme.get_type_color(current_moves[i].type)
			var style = StyleBoxFlat.new()
			style.bg_color = type_color
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = type_color.lightened(0.3)
			move_buttons[i].add_theme_stylebox_override("normal", style)
		else:
			move_buttons[i].text = "- Select Move -"

	# Setup stat sliders
	if stat_sliders:
		var base_stats = {
			"hp": current_pokemon.hp,
			"atk": current_pokemon.attack,
			"def": current_pokemon.defense,
			"spa": current_pokemon.special_attack,
			"spd": current_pokemon.special_defense,
			"spe": current_pokemon.speed
		}
		stat_sliders.setup(base_stats, battle_pokemon.level, battle_pokemon.nature)
		# Set the EVs and IVs
		stat_sliders.current_evs = battle_pokemon.evs.duplicate()
		stat_sliders.current_ivs = battle_pokemon.ivs.duplicate()
		stat_sliders._update_all_sliders()
		stat_sliders._update_stat_display()

	# Enable editor
	add_to_team_button.disabled = false

	print("[TeamBuilder] Loaded %s into editor" % current_pokemon.name)
