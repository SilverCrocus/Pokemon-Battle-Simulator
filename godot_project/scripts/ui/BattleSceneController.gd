extends Control

## Main controller for the battle scene
##
## Manages the battle scene layout, coordinates between UI components,
## and integrates with BattleController for game logic.

# ==================== Preloads ====================

const BattleActionScript = preload("res://scripts/core/BattleAction.gd")
const AnimationManagerScript = preload("res://scripts/ui/AnimationManager.gd")

# ==================== Node References ====================

@onready var background_layer: CanvasLayer = $BackgroundLayer
@onready var battle_background: ColorRect = $BackgroundLayer/BattleBackground

@onready var pokemon_layer: CanvasLayer = $PokemonLayer
@onready var opponent_position: Marker2D = $PokemonLayer/OpponentPokemonPosition
@onready var player_position: Marker2D = $PokemonLayer/PlayerPokemonPosition

@onready var ui_layer: CanvasLayer = $UILayer

# UI Components
@onready var opponent_info_panel = $UILayer/TopBar/OpponentInfoPanel
@onready var player_info_panel = $UILayer/BottomBar/PlayerInfoPanel
@onready var battle_log = $UILayer/BattleUIContainer/BattleLog
@onready var action_menu = $UILayer/BattleUIContainer/ActionMenu
@onready var move_selection_ui = $UILayer/BattleUIContainer/MoveSelectionUI
@onready var results_screen = $UILayer/BattleResultsScreen

# ==================== State ====================

var opponent_pokemon_sprite: AnimatedSprite2D = null
var player_pokemon_sprite: AnimatedSprite2D = null
var animation_manager: AnimationManagerScript = null

var current_ui_state: String = "idle"  # idle, action_menu, move_selection, animating

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the battle scene."""
	_setup_background()
	_setup_pokemon_positions()
	_setup_ui_components()
	_setup_animation_manager()
	_connect_signals()


# ==================== Setup Methods ====================

func _setup_background() -> void:
	"""Configure the background appearance."""
	battle_background.color = BattleTheme.BG_DARK


func _setup_pokemon_positions() -> void:
	"""Position Pokemon sprite markers for Gen 5 layout."""
	opponent_position.position = Vector2(700, 180)
	player_position.position = Vector2(192, 384)


func _setup_ui_components() -> void:
	"""Configure UI components."""
	# Start with all menus hidden
	_hide_all_menus()

	# Battle log is always visible
	battle_log.visible = true


func _setup_animation_manager() -> void:
	"""Create animation manager instance."""
	animation_manager = AnimationManagerScript.new()
	add_child(animation_manager)


func _connect_signals() -> void:
	"""Connect signals from UI components and BattleController."""
	# BattleController signals
	BattleController.battle_ready.connect(_on_battle_ready)
	BattleController.waiting_for_player_action.connect(_on_waiting_for_player_action)
	BattleController.battle_ended.connect(_on_battle_ended)

	# BattleEvents signals
	BattleEvents.battle_started.connect(_on_battle_started)
	BattleEvents.move_used.connect(_on_move_used)
	BattleEvents.damage_dealt.connect(_on_damage_dealt)
	BattleEvents.status_applied.connect(_on_status_applied)
	BattleEvents.status_cleared.connect(_on_status_cured)
	BattleEvents.pokemon_fainted.connect(_on_pokemon_fainted)

	# UI component signals
	action_menu.action_selected.connect(_on_action_selected)
	move_selection_ui.move_selected.connect(_on_move_selected)


# ==================== Public Methods - Battle Control ====================

func start_battle(player_pokemon, opponent_pokemon) -> void:
	"""
	Initialize UI for a new battle.

	@param player_pokemon: Player's Pokemon
	@param opponent_pokemon: Opponent's Pokemon
	"""
	# Setup info panels
	player_info_panel.setup(player_pokemon, true)  # Show HP numbers
	opponent_info_panel.setup(opponent_pokemon, false)  # Hide HP numbers

	# Start battle via BattleController
	BattleController.start_battle([player_pokemon], [opponent_pokemon])


# ==================== UI State Management ====================

func _show_action_menu() -> void:
	"""Show the action menu."""
	_hide_all_menus()
	action_menu.visible = true
	current_ui_state = "action_menu"


func _show_move_selection() -> void:
	"""Show the move selection UI."""
	_hide_all_menus()

	# Setup moves from current player Pokemon
	var player_pokemon = BattleController.get_player_pokemon()
	if player_pokemon:
		move_selection_ui.setup_moves(player_pokemon)

	move_selection_ui.visible = true
	current_ui_state = "move_selection"


func _hide_all_menus() -> void:
	"""Hide all interactive menus."""
	action_menu.visible = false
	move_selection_ui.visible = false
	current_ui_state = "idle"


func _show_results_screen(winner: int) -> void:
	"""Show the battle results screen."""
	var stats = {
		"turns": 0,  # TODO: Track turn count in BattleController
		"damage_dealt": 0,  # TODO: Track damage stats
		"damage_taken": 0
	}
	results_screen.show_results(winner, stats)


# ==================== Event Handlers - BattleController ====================

func _on_battle_ready() -> void:
	"""Handle battle ready event."""
	battle_log.add_message("Battle started!")


func _on_waiting_for_player_action() -> void:
	"""Handle waiting for player action."""
	_show_action_menu()


func _on_battle_ended(winner: int) -> void:
	"""Handle battle end."""
	_hide_all_menus()

	if winner == 0:
		battle_log.add_message("You won the battle!")
	else:
		battle_log.add_message("You lost the battle!")

	# Show results screen after a brief delay
	await get_tree().create_timer(1.5).timeout
	_show_results_screen(winner)


# ==================== Event Handlers - BattleEvents ====================

func _on_battle_started(team1: Array, team2: Array) -> void:
	"""Handle battle start event."""
	var player_pokemon = team1[0]
	var opponent_pokemon = team2[0]

	battle_log.add_message("Go! %s!" % player_pokemon.species.name)
	battle_log.add_message("Opponent sent out %s!" % opponent_pokemon.species.name)


func _on_move_used(user, move, target) -> void:
	"""Handle move use event."""
	var user_name = _get_pokemon_name(user)
	battle_log.add_message("%s used %s!" % [user_name, move.name])


func _on_damage_dealt(pokemon, amount: int, new_hp: int) -> void:
	"""Handle damage dealt event."""
	# Update appropriate HP bar
	if _is_player_pokemon(pokemon):
		player_info_panel.update_hp(new_hp, pokemon.max_hp)
	else:
		opponent_info_panel.update_hp(new_hp, pokemon.max_hp)


func _on_status_applied(pokemon, status: String) -> void:
	"""Handle status applied event."""
	var pokemon_name = _get_pokemon_name(pokemon)
	battle_log.add_message("%s was %s!" % [pokemon_name, _get_status_verb(status)])

	# Update status display
	if _is_player_pokemon(pokemon):
		player_info_panel.set_status(status)
	else:
		opponent_info_panel.set_status(status)


func _on_status_cured(pokemon, status: String) -> void:
	"""Handle status cured event."""
	var pokemon_name = _get_pokemon_name(pokemon)
	battle_log.add_message("%s was cured of %s!" % [pokemon_name, status])

	# Clear status display
	if _is_player_pokemon(pokemon):
		player_info_panel.set_status("")
	else:
		opponent_info_panel.set_status("")


func _on_pokemon_fainted(pokemon) -> void:
	"""Handle Pokemon fainted event."""
	var pokemon_name = _get_pokemon_name(pokemon)
	battle_log.add_message("%s fainted!" % pokemon_name)


# ==================== Event Handlers - UI ====================

func _on_action_selected(action_type: String) -> void:
	"""Handle action menu selection."""
	match action_type:
		"fight":
			_show_move_selection()
		"pokemon":
			battle_log.add_message("Pokemon switching not yet implemented")
			_show_action_menu()
		"bag":
			battle_log.add_message("Items not yet implemented")
			_show_action_menu()
		"run":
			battle_log.add_message("Cannot run from trainer battles!")
			_show_action_menu()


func _on_move_selected(move_index: int) -> void:
	"""Handle move selection."""
	_hide_all_menus()

	# Submit action to BattleController
	var action = BattleActionScript.new_move_action(move_index)
	BattleController.submit_player_action(action)


# ==================== Helper Methods ====================

func _is_player_pokemon(pokemon) -> bool:
	"""Check if Pokemon belongs to player."""
	var player_pokemon = BattleController.get_player_pokemon()
	return player_pokemon == pokemon


func _get_pokemon_name(pokemon) -> String:
	"""Get display name for Pokemon."""
	if _is_player_pokemon(pokemon):
		return pokemon.species.name
	else:
		return "Enemy %s" % pokemon.species.name


func _get_status_verb(status: String) -> String:
	"""Get appropriate verb for status condition."""
	match status.to_lower():
		"burn": return "burned"
		"poison": return "poisoned"
		"badly_poison": return "badly poisoned"
		"paralysis": return "paralyzed"
		"sleep": return "put to sleep"
		"freeze": return "frozen"
		_: return status


# ==================== Pokemon Sprite Management ====================

func set_opponent_pokemon(species_name: String) -> void:
	"""Display opponent Pokemon sprite."""
	# TODO: Load and display sprite (will be implemented in future)
	pass


func set_player_pokemon(species_name: String) -> void:
	"""Display player Pokemon sprite."""
	# TODO: Load and display sprite (will be implemented in future)
	pass


func hide_opponent_pokemon() -> void:
	"""Hide opponent Pokemon sprite."""
	if opponent_pokemon_sprite:
		opponent_pokemon_sprite.visible = false


func hide_player_pokemon() -> void:
	"""Hide player Pokemon sprite."""
	if player_pokemon_sprite:
		player_pokemon_sprite.visible = false
