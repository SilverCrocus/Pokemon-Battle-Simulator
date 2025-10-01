extends RefCounted

## Battle AI System
##
## Provides AI opponents with varying difficulty levels.
## Handles move selection and switching decisions for computer-controlled players.

# ==================== Enums ====================

enum Difficulty {
	RANDOM,      # Completely random moves
	BASIC,       # Prefers super-effective moves
	INTERMEDIATE # Considers damage calculations (future)
}

# ==================== Constants ====================

const BattleActionScript = preload("res://scripts/core/BattleAction.gd")

# ==================== State ====================

var difficulty: Difficulty = Difficulty.RANDOM
var battle_state = null  # BattleState reference
var player_side: int = 1  # Which side AI is playing (0 or 1)

# ==================== Public Methods ====================

func set_difficulty(new_difficulty: Difficulty) -> void:
	"""Set AI difficulty level."""
	difficulty = new_difficulty


func set_battle_state(state) -> void:
	"""Set the battle state reference."""
	battle_state = state


func set_player_side(side: int) -> void:
	"""Set which side the AI is playing (0 or 1)."""
	player_side = side


func decide_action() -> BattleActionScript:
	"""
	Decide the AI's next action.

	@return: BattleAction for the AI's turn
	"""
	if not battle_state:
		push_error("[BattleAI] Battle state not set")
		return null

	# Check if active Pokemon has fainted
	var active_pokemon = _get_active_pokemon()
	if not active_pokemon or active_pokemon.current_hp <= 0:
		return _decide_switch()

	# Decide between move and switch
	match difficulty:
		Difficulty.RANDOM:
			return _decide_random()
		Difficulty.BASIC:
			return _decide_basic()
		Difficulty.INTERMEDIATE:
			return _decide_intermediate()
		_:
			return _decide_random()


# ==================== AI Decision Logic ====================

func _decide_random() -> BattleActionScript:
	"""
	Random AI: Completely random move selection.
	Simplest AI for testing.
	"""
	var active_pokemon = _get_active_pokemon()

	# Get available moves
	var available_moves = _get_available_moves(active_pokemon)
	if available_moves.is_empty():
		# No moves available (all PP depleted) - use Struggle
		push_warning("[BattleAI] No moves available, should use Struggle")
		return _create_move_action(0)  # TODO: Implement Struggle

	# Pick random move
	var move_index = randi() % available_moves.size()
	return _create_move_action(available_moves[move_index])


func _decide_basic() -> BattleActionScript:
	"""
	Basic AI: Prefers super-effective moves.
	Considers type matchups but doesn't calculate damage.
	"""
	var active_pokemon = _get_active_pokemon()
	var opponent_pokemon = _get_opponent_pokemon()

	if not opponent_pokemon:
		return _decide_random()

	var available_moves = _get_available_moves(active_pokemon)
	if available_moves.is_empty():
		return _create_move_action(0)

	# Find super-effective moves
	var super_effective_moves = []
	var neutral_moves = []

	for move_idx in available_moves:
		var move = active_pokemon.moves[move_idx]
		if not move:
			continue

		# Calculate effectiveness against both types
		var eff1 = TypeChart.get_effectiveness(move.type, opponent_pokemon.species.type1)
		var eff2 = 1.0
		if opponent_pokemon.species.type2 and not opponent_pokemon.species.type2.is_empty():
			eff2 = TypeChart.get_effectiveness(move.type, opponent_pokemon.species.type2)
		var effectiveness = eff1 * eff2

		if effectiveness >= 2.0:
			super_effective_moves.append(move_idx)
		elif effectiveness > 0.5:
			neutral_moves.append(move_idx)

	# Prefer super-effective moves
	if not super_effective_moves.is_empty():
		var move_idx = super_effective_moves[randi() % super_effective_moves.size()]
		return _create_move_action(move_idx)

	# Otherwise use neutral moves
	if not neutral_moves.is_empty():
		var move_idx = neutral_moves[randi() % neutral_moves.size()]
		return _create_move_action(move_idx)

	# Fall back to random
	var move_idx = available_moves[randi() % available_moves.size()]
	return _create_move_action(move_idx)


func _decide_intermediate() -> BattleActionScript:
	"""
	Intermediate AI: Considers damage calculations.
	TODO: Implement damage prediction
	"""
	# For now, fall back to basic AI
	return _decide_basic()


func _decide_switch() -> BattleActionScript:
	"""
	Decide which Pokemon to switch to.
	Picks the first non-fainted Pokemon.
	"""
	var team = battle_state.teams[player_side]

	# Find first non-fainted Pokemon
	for i in range(team.size()):
		var pokemon = team[i]
		if pokemon.current_hp > 0 and i != battle_state.active_pokemon_indices[player_side]:
			return _create_switch_action(i)

	# No valid switches (should not happen in normal gameplay)
	push_error("[BattleAI] No valid Pokemon to switch to")
	return null


# ==================== Helper Methods ====================

func _get_active_pokemon():
	"""Get the AI's active Pokemon."""
	if not battle_state:
		return null

	var active_index = battle_state.active_pokemon_indices[player_side]
	return battle_state.teams[player_side][active_index]


func _get_opponent_pokemon():
	"""Get the opponent's active Pokemon."""
	if not battle_state:
		return null

	var opponent_side = 1 - player_side
	var active_index = battle_state.active_pokemon_indices[opponent_side]
	return battle_state.teams[opponent_side][active_index]


func _get_available_moves(pokemon) -> Array:
	"""
	Get list of available move indices (with PP remaining).

	@param pokemon: BattlePokemon instance
	@return: Array of move indices (0-3) that have PP remaining
	"""
	var available = []

	for i in range(pokemon.moves.size()):
		var move = pokemon.moves[i]
		if move and pokemon.move_pp[i] > 0:
			available.append(i)

	return available


func _create_move_action(move_index: int) -> BattleActionScript:
	"""
	Create a move action.

	@param move_index: Index of move to use (0-3)
	@return: BattleAction for using the move
	"""
	var target_index = battle_state.active_pokemon_indices[1 - player_side]
	var action = BattleActionScript.new(
		BattleActionScript.ActionType.MOVE,
		move_index,
		target_index,
		-1  # switch_index not used
	)
	return action


func _create_switch_action(pokemon_index: int) -> BattleActionScript:
	"""
	Create a switch action.

	@param pokemon_index: Index of Pokemon to switch to (0-5)
	@return: BattleAction for switching Pokemon
	"""
	var action = BattleActionScript.new(
		BattleActionScript.ActionType.SWITCH,
		-1,  # move_index not used
		-1,  # target_index not used
		pokemon_index
	)
	return action


# ==================== Debug Methods ====================

func get_difficulty_name() -> String:
	"""Get human-readable difficulty name."""
	match difficulty:
		Difficulty.RANDOM:
			return "Random"
		Difficulty.BASIC:
			return "Basic"
		Difficulty.INTERMEDIATE:
			return "Intermediate"
		_:
			return "Unknown"
