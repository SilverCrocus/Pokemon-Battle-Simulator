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

# ==================== Signals ====================

signal battle_ready()
signal turn_started()
signal turn_resolved()
signal battle_ended(winner: int)
signal animation_finished()
signal waiting_for_player_action()

# ==================== State ====================

var engine: RefCounted = null  # BattleEngine instance
var is_battle_active: bool = false
var is_waiting_for_action: bool = false

# Action submission
var player_action: BattleActionScript = null
var opponent_action: BattleActionScript = null

# Battle configuration
var battle_seed: int = 0

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize on game start."""
	print("[BattleController] Ready")


# ==================== Public Methods - Battle Management ====================

func start_battle(team1: Array, team2: Array, seed: int = -1) -> void:
	"""
	Start a new battle with two teams.

	@param team1: Player's team (array of BattlePokemon)
	@param team2: Opponent's team (array of BattlePokemon)
	@param seed: Random seed for determinism (-1 for random)
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

	is_battle_active = true
	print("[BattleController] Battle started with seed: %d" % battle_seed)

	# Emit ready signal
	battle_ready.emit()

	# Wait for first action
	request_player_action()


func end_battle() -> void:
	"""End the current battle."""
	if not is_battle_active:
		return

	is_battle_active = false
	is_waiting_for_action = false
	player_action = null
	opponent_action = null

	# Emit battle ended signal
	var winner = (engine as RefCounted).call("get_winner")
	battle_ended.emit(winner)

	print("[BattleController] Battle ended - Winner: Team %d" % winner)

	# Clear engine
	engine = null


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

	# Get opponent action (AI decision)
	opponent_action = _get_opponent_action()

	# Execute turn
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
	Generate opponent's action (simple AI for now).

	@return: BattleAction for opponent
	"""
	# Simple AI: Always use move 0 (first move)
	# TODO: Implement smarter AI in future phases
	return BattleActionScript.new_move_action(0)


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
