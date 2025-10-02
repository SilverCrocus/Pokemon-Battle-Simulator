extends Node

## BattleController - Battle Coordination System
##
## Bridges between the headless battle engine and UI layer.
## Manages battle flow, turn execution, and animations.
## Loaded as an autoload singleton.

# ==================== Preloads ====================

const BattleEngineScript = preload("res://scripts/core/BattleEngine.gd")
const BattleActionScript = preload("res://scripts/core/BattleAction.gd")
const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")
const BattleAIScript = preload("res://scripts/core/BattleAI.gd")

# ==================== Signals ====================

signal battle_ready()
signal turn_started()
signal turn_resolved()
signal battle_ended(winner: int)
signal animation_finished()
signal waiting_for_player_action()

# ==================== State ====================

## Battle modes
enum BattleMode {
	LOCAL,     ## Local battle (vs AI or hot-seat)
	NETWORK    ## Network multiplayer battle
}

var current_mode: BattleMode = BattleMode.LOCAL
var engine: RefCounted = null  # BattleEngine instance (local mode only)
var is_battle_active: bool = false
var is_waiting_for_action: bool = false

# Action submission
var player_action: BattleActionScript = null
var opponent_action: BattleActionScript = null

# Battle configuration
var battle_seed: int = 0

# Team data for battle initialization (from main menu)
var player_team_data = null  # Team JSON data
var is_vs_ai: bool = false

# AI opponent
var ai_opponent: RefCounted = null  # BattleAI instance
var ai_difficulty: int = 0  # BattleAI.Difficulty enum value

# Network mode
var network_battle_state: Dictionary = {}  # Server-authoritative state
var player_number: int = 0  # 1 or 2 in network mode

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize on game start."""
	print("[BattleController] Ready")

	# Connect to BattleClient signals for network mode
	if not OS.has_feature("dedicated_server"):
		BattleClient.battle_started.connect(_on_network_battle_started)
		BattleClient.battle_state_updated.connect(_on_network_battle_state_updated)
		BattleClient.battle_ended.connect(_on_network_battle_ended)


# ==================== Public Methods - Battle Management ====================

func start_battle(team1: Array, team2: Array, seed: int = -1, use_ai: bool = false, difficulty: int = 0) -> void:
	"""
	Start a new battle with two teams.

	@param team1: Player's team (array of BattlePokemon)
	@param team2: Opponent's team (array of BattlePokemon)
	@param seed: Random seed for determinism (-1 for random)
	@param use_ai: Whether opponent is AI-controlled
	@param difficulty: AI difficulty level (BattleAI.Difficulty enum)
	"""
	if is_battle_active:
		push_error("[BattleController] Cannot start battle - battle already active")
		return

	# Generate random seed if not provided
	if seed < 0:
		battle_seed = randi()
	else:
		battle_seed = seed

	# Create battle engine
	engine = BattleEngineScript.new(battle_seed)

	# Initialize battle
	(engine as RefCounted).call("initialize_battle", team1, team2)

	# Setup AI if requested
	is_vs_ai = use_ai
	if is_vs_ai:
		ai_opponent = BattleAIScript.new()
		ai_opponent.set_difficulty(difficulty)
		ai_opponent.set_battle_state(engine.state)
		ai_opponent.set_player_side(1)  # AI plays as team 2 (opponent)
		ai_difficulty = difficulty
		print("[BattleController] AI opponent initialized - Difficulty: %s" % ai_opponent.get_difficulty_name())

	is_battle_active = true
	print("[BattleController] Battle started with seed: %d" % battle_seed)

	# Emit ready signal
	battle_ready.emit()

	# Wait for first action
	request_player_action()


func start_network_battle(p_player_number: int) -> void:
	"""
	Start a network multiplayer battle.
	Called when BattleClient receives battle_started signal.

	@param p_player_number: This player's number (1 or 2)
	"""
	if is_battle_active:
		push_error("[BattleController] Cannot start battle - battle already active")
		return

	current_mode = BattleMode.NETWORK
	player_number = p_player_number
	is_battle_active = true

	print("[BattleController] Network battle started - You are Player %d" % player_number)

	# Battle ready signal will be emitted when we receive initial state
	battle_ready.emit()


func end_battle() -> void:
	"""End the current battle."""
	if not is_battle_active:
		return

	is_battle_active = false
	is_waiting_for_action = false
	player_action = null
	opponent_action = null

	# Emit battle ended signal
	var winner = 0
	if current_mode == BattleMode.LOCAL:
		winner = (engine as RefCounted).call("get_winner")
	# For network mode, winner is set by _on_network_battle_ended

	battle_ended.emit(winner)

	print("[BattleController] Battle ended - Winner: Team %d" % winner)

	# Clear engine and AI (local mode)
	engine = null
	ai_opponent = null
	is_vs_ai = false

	# Clear network state
	network_battle_state = {}
	player_number = 0
	current_mode = BattleMode.LOCAL


func request_player_action() -> void:
	"""Request action from player."""
	if not is_battle_active:
		return

	is_waiting_for_action = true
	waiting_for_player_action.emit()


func submit_player_action(action: BattleActionScript) -> void:
	"""
	Submit player's action for the current turn.

	@param action: BattleAction representing player's choice
	"""
	if not is_battle_active or not is_waiting_for_action:
		push_error("[BattleController] Cannot submit action - not waiting for action")
		return

	player_action = action
	is_waiting_for_action = false

	print("[BattleController] Player action submitted: %s" % action.action_type)

	# Network mode: send to server
	if current_mode == BattleMode.NETWORK:
		BattleClient.submit_battle_action(action)
		print("[BattleController] Action sent to server")
		return

	# Local mode: get opponent action and execute
	opponent_action = _get_opponent_action()
	_execute_turn()


# ==================== Private Methods - Turn Execution ====================

func _execute_turn() -> void:
	"""Execute a turn with both players' actions."""
	if not player_action or not opponent_action:
		push_error("[BattleController] Cannot execute turn - missing actions")
		return

	# Emit turn start
	turn_started.emit()

	# Execute turn in engine
	(engine as RefCounted).call("execute_turn", player_action, opponent_action)

	# Clear actions
	player_action = null
	opponent_action = null

	# Emit turn resolved
	turn_resolved.emit()

	# Check if battle is over
	if (engine as RefCounted).call("is_battle_over"):
		end_battle()
	else:
		# Request next action after a brief delay (for animations to play)
		await get_tree().create_timer(0.5).timeout
		request_player_action()


func _get_opponent_action() -> BattleActionScript:
	"""
	Generate opponent's action.
	Uses AI if vs AI mode, otherwise placeholder.

	@return: BattleAction for opponent
	"""
	if is_vs_ai and ai_opponent:
		# Use AI to decide action
		var action = ai_opponent.decide_action()
		if action:
			print("[BattleController] AI action: %s" % ("Move" if action.type == BattleActionScript.ActionType.MOVE else "Switch"))
			return action

	# Fallback: Use first available move
	print("[BattleController] Using fallback AI action (move 0)")
	var action = BattleActionScript.new(
		BattleActionScript.ActionType.MOVE,
		0,  # move_index
		0,  # target_index
		-1  # switch_index (not used)
	)
	return action


# ==================== Public Methods - Battle State Queries ====================

func get_player_pokemon():
	"""Get the current active player Pokemon."""
	if not engine:
		return null

	var state = (engine as RefCounted).get("state")
	return state.get_active_pokemon(1)


func get_opponent_pokemon():
	"""Get the current active opponent Pokemon."""
	if not engine:
		return null

	var state = (engine as RefCounted).get("state")
	return state.get_active_pokemon(2)


func get_battle_state():
	"""Get the current battle state."""
	if not engine:
		return null

	return (engine as RefCounted).get("state")


func is_battle_over() -> bool:
	"""Check if battle is over."""
	if not engine:
		return true

	return (engine as RefCounted).call("is_battle_over")


func get_winner() -> int:
	"""Get battle winner (1 = player, 2 = opponent, 0 = no winner yet)."""
	if not engine:
		return 0

	return (engine as RefCounted).call("get_winner")


# ==================== Network Mode Signal Handlers ====================

func _on_network_battle_started(battle_state_data: Dictionary) -> void:
	"""Handle battle start from network."""
	print("[BattleController] Network battle state received")

	# Store server-authoritative state
	network_battle_state = battle_state_data

	# Start network battle
	start_network_battle(BattleClient.get_player_number())

	# Wait for first action
	request_player_action()


func _on_network_battle_state_updated(battle_state_data: Dictionary) -> void:
	"""Handle battle state update from server."""
	print("[BattleController] Battle state updated from server")

	# Store updated state
	network_battle_state = battle_state_data

	# Emit turn resolved (UI will update based on new state)
	turn_resolved.emit()

	# Check if battle is over
	var state_status = battle_state_data.get("battle_status", 1)  # 1 = IN_PROGRESS
	if state_status != 1:  # Not IN_PROGRESS
		var winner_num = 0
		if state_status == 2:  # PLAYER1_WIN
			winner_num = 1
		elif state_status == 3:  # PLAYER2_WIN
			winner_num = 2
		_on_network_battle_ended(winner_num)
	else:
		# Request next action after a brief delay
		await get_tree().create_timer(0.5).timeout
		request_player_action()


func _on_network_battle_ended(winner: int) -> void:
	"""Handle battle end from network."""
	print("[BattleController] Network battle ended - Winner: Player %d" % winner)

	# Emit battle ended
	battle_ended.emit(winner)

	# Clean up
	is_battle_active = false
	network_battle_state = {}
	player_number = 0
	current_mode = BattleMode.LOCAL
