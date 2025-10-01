extends Control

## Battle UI Controller (Gen 5 Style)
##
## Manages all battle UI components and coordinates with BattleController.
## Handles event responses, animations, and user input.
##
## Components managed:
## - Pokemon info panels (player & opponent)
## - Move selection UI
## - Action menu (Fight/Pokemon/Bag/Run)
## - Battle log / dialogue box

# ==================== Signals ====================

signal move_selected(move_index: int)
signal action_selected(action_type: String)  # "fight", "pokemon", "bag", "run"

# ==================== Node References ====================

# Pokemon Info Panels
@onready var opponent_info_panel = null  # Will be set when component is created
@onready var player_info_panel = null    # Will be set when component is created

# UI Sections
@onready var move_selection_ui = null     # Will be set when component is created
@onready var action_menu_ui = null        # Will be set when component is created
@onready var battle_log = null            # Will be set when component is created

# ==================== State ====================

var current_ui_state: String = "idle"  # idle, selecting_action, selecting_move, animating
var player_pokemon: BattlePokemon = null
var opponent_pokemon: BattlePokemon = null

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the battle UI."""
	_setup_event_connections()
	hide_all_menus()


# ==================== Public Methods - Setup ====================

func initialize_battle(player: BattlePokemon, opponent: BattlePokemon) -> void:
	"""
	Initialize UI for a new battle.

	@param player: Player's Pokemon
	@param opponent: Opponent's Pokemon
	"""
	player_pokemon = player
	opponent_pokemon = opponent

	# Setup info panels (when they exist)
	if player_info_panel:
		player_info_panel.setup(player, true)  # Show HP numbers for player

	if opponent_info_panel:
		opponent_info_panel.setup(opponent, false)  # Hide HP numbers for opponent

	# Start with action selection
	show_action_menu()


func update_player_hp(new_hp: int) -> void:
	"""Update player Pokemon HP display."""
	if player_info_panel and player_pokemon:
		player_info_panel.update_hp(new_hp, player_pokemon.max_hp)


func update_opponent_hp(new_hp: int) -> void:
	"""Update opponent Pokemon HP display."""
	if opponent_info_panel and opponent_pokemon:
		opponent_info_panel.update_hp(new_hp, opponent_pokemon.max_hp)


func set_player_status(status_name: String) -> void:
	"""Display player Pokemon status condition."""
	if player_info_panel:
		if status_name.is_empty():
			player_info_panel.clear_status()
		else:
			player_info_panel.set_status(status_name)


func set_opponent_status(status_name: String) -> void:
	"""Display opponent Pokemon status condition."""
	if opponent_info_panel:
		if status_name.is_empty():
			opponent_info_panel.clear_status()
		else:
			opponent_info_panel.set_status(status_name)


# ==================== Public Methods - UI State ====================

func show_action_menu() -> void:
	"""Show the main action menu (Fight/Pokemon/Bag/Run)."""
	hide_all_menus()

	if action_menu_ui:
		action_menu_ui.visible = true
		current_ui_state = "selecting_action"


func show_move_selection() -> void:
	"""Show the move selection UI."""
	hide_all_menus()

	if move_selection_ui:
		move_selection_ui.visible = true
		current_ui_state = "selecting_move"


func hide_all_menus() -> void:
	"""Hide all interactive menus."""
	if action_menu_ui:
		action_menu_ui.visible = false

	if move_selection_ui:
		move_selection_ui.visible = false

	current_ui_state = "idle"


func log_message(message: String) -> void:
	"""
	Add a message to the battle log.

	@param message: Text to display
	"""
	if battle_log:
		# Will be implemented when BattleLog component is created
		pass


func clear_log() -> void:
	"""Clear all messages from the battle log."""
	if battle_log:
		# Will be implemented when BattleLog component is created
		pass


# ==================== Event Handler Setup ====================

func _setup_event_connections() -> void:
	"""Connect to BattleEvents signals."""
	# Battle flow events
	BattleEvents.battle_started.connect(_on_battle_started)
	BattleEvents.turn_started.connect(_on_turn_started)
	BattleEvents.turn_ended.connect(_on_turn_ended)
	BattleEvents.battle_ended.connect(_on_battle_ended)

	# Action events
	BattleEvents.move_used.connect(_on_move_used)
	BattleEvents.move_failed.connect(_on_move_failed)
	BattleEvents.switch_pokemon.connect(_on_switch_pokemon)

	# Damage/healing events
	BattleEvents.damage_dealt.connect(_on_damage_dealt)
	BattleEvents.healing_done.connect(_on_healing_done)
	BattleEvents.pokemon_fainted.connect(_on_pokemon_fainted)

	# Status/stat events
	BattleEvents.status_applied.connect(_on_status_applied)
	BattleEvents.status_cured.connect(_on_status_cured)
	BattleEvents.stat_changed.connect(_on_stat_changed)
	BattleEvents.critical_hit.connect(_on_critical_hit)


# ==================== Event Handlers ====================

func _on_battle_started(team1: Array, team2: Array) -> void:
	"""Handle battle start."""
	log_message("Battle started!")


func _on_turn_started(turn_number: int) -> void:
	"""Handle turn start."""
	log_message("Turn %d" % turn_number)


func _on_turn_ended(turn_number: int) -> void:
	"""Handle turn end."""
	# Could add any end-of-turn UI updates here
	pass


func _on_battle_ended(winner: int) -> void:
	"""Handle battle end."""
	if winner == 1:
		log_message("You won!")
	else:
		log_message("You lost!")


func _on_move_used(user: BattlePokemon, move: MoveData, target: BattlePokemon) -> void:
	"""Handle move use."""
	log_message("%s used %s!" % [user.species.name, move.name])


func _on_move_failed(user: BattlePokemon, move: MoveData, reason: String) -> void:
	"""Handle move failure."""
	log_message("%s's %s failed! %s" % [user.species.name, move.name, reason])


func _on_switch_pokemon(trainer: int, old_pokemon: BattlePokemon, new_pokemon: BattlePokemon) -> void:
	"""Handle Pokemon switch."""
	log_message("%s switched to %s!" % [
		"Opponent" if trainer == 2 else "You",
		new_pokemon.species.name
	])


func _on_damage_dealt(pokemon: BattlePokemon, amount: int, new_hp: int) -> void:
	"""Handle damage dealt."""
	# Update HP bar for the damaged Pokemon
	if pokemon == player_pokemon:
		update_player_hp(new_hp)
	elif pokemon == opponent_pokemon:
		update_opponent_hp(new_hp)


func _on_healing_done(pokemon: BattlePokemon, amount: int, new_hp: int) -> void:
	"""Handle healing."""
	if pokemon == player_pokemon:
		update_player_hp(new_hp)
	elif pokemon == opponent_pokemon:
		update_opponent_hp(new_hp)


func _on_pokemon_fainted(pokemon: BattlePokemon) -> void:
	"""Handle Pokemon fainting."""
	log_message("%s fainted!" % pokemon.species.name)


func _on_status_applied(pokemon: BattlePokemon, status: String) -> void:
	"""Handle status condition applied."""
	log_message("%s was %s!" % [pokemon.species.name, _get_status_verb(status)])

	# Update status display
	if pokemon == player_pokemon:
		set_player_status(status)
	elif pokemon == opponent_pokemon:
		set_opponent_status(status)


func _on_status_cured(pokemon: BattlePokemon, status: String) -> void:
	"""Handle status condition cured."""
	log_message("%s was cured of %s!" % [pokemon.species.name, status])

	# Clear status display
	if pokemon == player_pokemon:
		set_player_status("")
	elif pokemon == opponent_pokemon:
		set_opponent_status("")


func _on_stat_changed(pokemon: BattlePokemon, stat: String, stages: int) -> void:
	"""Handle stat stage change."""
	var direction = "rose" if stages > 0 else "fell"
	var amount = ""

	match abs(stages):
		1: amount = ""
		2: amount = " sharply"
		3, 4, 5, 6: amount = " drastically"

	log_message("%s's %s %s%s!" % [pokemon.species.name, stat.to_upper(), direction, amount])


func _on_critical_hit(user: BattlePokemon, target: BattlePokemon) -> void:
	"""Handle critical hit."""
	log_message("A critical hit!")


# ==================== Helper Methods ====================

func _get_status_verb(status: String) -> String:
	"""Get the appropriate verb for a status condition."""
	match status.to_lower():
		"burn": return "burned"
		"poison": return "poisoned"
		"badly_poison": return "badly poisoned"
		"paralysis": return "paralyzed"
		"sleep": return "put to sleep"
		"freeze": return "frozen"
		_: return status
