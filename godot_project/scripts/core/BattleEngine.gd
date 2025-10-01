class_name BattleEngine
extends RefCounted

## Headless battle engine for Pokemon battles
##
## Preload dependencies to ensure they're available
const BattleStateScript = preload("res://scripts/core/BattleState.gd")
const BattleActionScript = preload("res://scripts/core/BattleAction.gd")
const ActionQueueScript = preload("res://scripts/core/ActionQueue.gd")
const DamageCalculatorScript = preload("res://scripts/core/DamageCalculator.gd")
##
## Orchestrates turn-based battle execution with deterministic simulation.
## This is the core battle system that processes player actions, calculates
## damage, applies effects, and manages battle flow. It is completely decoupled
## from UI and operates as a pure logic engine emitting events for observers.
##
## Architecture:
## - Maintains BattleState (teams, weather, turn count)
## - Uses ActionQueue for priority resolution
## - Integrates DamageCalculator and StatCalculator
## - Emits events through BattleEvents singleton
## - Deterministic with seeded RNG for replay capability
##
## Example usage:
## [codeblock]
## # Initialize battle
## var engine = BattleEngine.new(12345)  # seed for determinism
## engine.initialize_battle([pikachu, charizard], [mewtwo, dragonite])
##
## # Execute turns
## var p1_action = BattleActionScript.new_move_action(0)  # Use first move
## var p2_action = BattleActionScript.new_move_action(1)  # Use second move
## engine.execute_turn(p1_action, p2_action)
##
## # Check battle status
## if engine.state.is_battle_over():
##     print("Winner: Player %d" % engine.state.get_winner())
## [/codeblock]

# ==================== Public Properties ====================

## Current battle state
var state  # Type: BattleState

# ==================== Private Properties ====================

## Action queue for priority resolution
var _action_queue  # Type: ActionQueue

## Submitted actions for current turn
var _pending_actions: Dictionary = {}  # player -> BattleAction

# ==================== Initialization ====================

func _init(p_seed: int = 0) -> void:
	"""
	Initialize battle engine with optional RNG seed.

	Args:
		p_seed: Random seed for deterministic battles (0 for random seed)
	"""
	state = BattleStateScript.new(p_seed)
	_action_queue = ActionQueueScript.new(state._rng)


func initialize_battle(team1: Array, team2: Array) -> void:
	"""
	Setup and start a new battle with two teams.

	Args:
		team1: Player 1's team (1-6 BattlePokemon)
		team2: Player 2's team (1-6 BattlePokemon)
	"""
	state.set_team1(team1)
	state.set_team2(team2)
	state.begin_battle()

	# Emit battle started event
	BattleEvents.battle_started.emit(state)

# ==================== Turn Execution ====================

func execute_turn(player1_action, player2_action) -> void:
	"""
	Execute a complete turn with both players' actions.

	Process flow:
	1. Emit turn_started event
	2. Build action queue with priority sorting
	3. Execute actions sequentially
	4. Apply end-of-turn effects
	5. Advance turn counter
	6. Check for battle end
	7. Emit turn_ended event

	Args:
		player1_action: Player 1's chosen action
		player2_action: Player 2's chosen action
	"""
	assert(player1_action != null, "BattleEngine: player1_action cannot be null")
	assert(player2_action != null, "BattleEngine: player2_action cannot be null")
	assert(state.battle_status == 1,  # BattleState.BattleStatus.IN_PROGRESS
		"BattleEngine: cannot execute turn, battle not in progress")

	# Emit turn start
	BattleEvents.turn_started.emit(state.turn_number)

	# Build action queue
	_action_queue.clear()

	# Only queue actions if Pokemon can act
	var p1_active = state.get_active_pokemon(1)
	var p2_active = state.get_active_pokemon(2)

	if not p1_active.is_fainted():
		_action_queue.add_action(1, player1_action, p1_active, state)

	if not p2_active.is_fainted():
		_action_queue.add_action(2, player2_action, p2_active, state)

	# Execute all actions in priority order
	while _action_queue.has_actions():
		var queued_action = _action_queue.pop_next()
		_execute_action(queued_action)

		# Check for battle end after each action
		if state.is_battle_over():
			break

	# Apply end-of-turn effects (weather, status damage)
	if not state.is_battle_over():
		_apply_end_of_turn_effects()

	# Advance turn
	state.advance_turn()

	# Emit turn end
	BattleEvents.turn_ended.emit(state.turn_number - 1)

	# Check for battle end
	state.check_battle_end()
	if state.is_battle_over():
		BattleEvents.battle_ended.emit(state.get_winner())


func _execute_action(queued_action) -> void:  # Type: ActionQueue.QueuedAction
	"""
	Execute a single queued action.

	Args:
		queued_action: QueuedAction to execute
	"""
	var action = queued_action.action
	var player = queued_action.player
	var actor = queued_action.actor

	# Skip if Pokemon fainted before their turn
	if actor.is_fainted():
		return

	# Execute based on action type
	if action.is_forfeit():
		_execute_forfeit(player)
	elif action.is_switch():
		_execute_switch(player, action)
	elif action.is_move():
		_execute_move(queued_action)


func _execute_move(queued_action) -> void:  # Type: ActionQueue.QueuedAction
	"""
	Execute a move action with full damage calculation and effects.

	Args:
		queued_action: QueuedAction containing move details
	"""
	var actor = queued_action.actor
	var action = queued_action.action
	var player = queued_action.player

	# Check if Pokemon can move (status check)
	if not actor.can_move(state._rng):
		BattleEvents.move_prevented.emit(actor, actor.status)
		return

	# Get move and target
	var move = actor.moves[action.move_index]
	var opponent = 3 - player  # 1->2, 2->1
	var target = state.get_active_pokemon(opponent)

	# Check if target exists and is not fainted
	if target.is_fainted():
		return

	# Consume PP
	if not actor.use_move(action.move_index):
		# No PP remaining
		BattleEvents.move_prevented.emit(actor, "no PP")
		return

	# Emit move used event
	BattleEvents.move_used.emit(actor, move, target)

	# Accuracy check
	if not _check_accuracy(actor, target, move):
		BattleEvents.move_missed.emit(actor, target)
		return

	# Calculate and apply damage
	if move.power > 0:
		# Check for critical hit
		var is_critical = _check_critical_hit(actor, move)

		# Calculate damage with critical hit flag
		var damage = _calculate_move_damage(actor, target, move, is_critical)

		# Emit critical hit event
		if is_critical:
			BattleEvents.critical_hit.emit(actor, target)

		# Check type effectiveness for event emission
		var effectiveness = TypeChart.calculate_type_effectiveness(
			move.type,
			[target.species.type1, target.species.type2]
		)

		if effectiveness == 0.0:
			BattleEvents.move_no_effect.emit(actor, target)
			return
		elif effectiveness > 1.0:
			BattleEvents.move_super_effective.emit(effectiveness)
		elif effectiveness < 1.0:
			BattleEvents.move_not_very_effective.emit(effectiveness)

		# Apply damage
		target.apply_damage(damage)
		BattleEvents.damage_dealt.emit(target, damage, target.current_hp)

		# Check if target fainted
		if target.is_fainted():
			BattleEvents.pokemon_fainted.emit(target)

	# Apply move effects (status conditions, stat changes)
	if not target.is_fainted():
		_apply_move_effects(actor, target, move)


func _calculate_move_damage(
	attacker,
	defender,
	move,
	is_critical: bool = false
) -> int:
	"""
	Calculate damage for a move using DamageCalculatorScript.

	Integrates all systems: stat calculation, type effectiveness, weather, etc.

	Args:
		attacker: BattlePokemon using the move
		defender: BattlePokemon receiving the move
		move: MoveData being used
		is_critical: Whether this is a critical hit

	Returns:
		Final damage amount
	"""
	# Determine if move is physical or special
	var is_physical = move.damage_class == "physical"

	# Get attack and defense stats with stages
	var attack_stat = "atk" if is_physical else "spa"
	var defense_stat = "def" if is_physical else "spd"

	var attack = attacker.get_stat_with_stage(attack_stat)
	var defense = defender.get_stat_with_stage(defense_stat)

	# Calculate type effectiveness
	var type_effectiveness = TypeChart.calculate_type_effectiveness(
		move.type,
		[defender.species.type1, defender.species.type2]
	)

	# Build parameters for DamageCalculator
	var params = {
		"level": attacker.level,
		"power": move.power,
		"attack": attack,
		"defense": defense,
		"move_type": move.type,
		"attacker_types": [attacker.species.type1, attacker.species.type2],
		"is_physical": is_physical,
		"type_effectiveness": type_effectiveness,
		"is_critical": is_critical,
		"random_factor": state._rng.randf_range(0.85, 1.0),
		"weather": state.weather,
		"attacker_has_burn": attacker.status == "burn",
		"attacker_has_guts": false  # TODO: Check ability in Phase 1 Week 6
	}

	return DamageCalculatorScript.calculate_damage(params)


func _apply_move_effects(actor, target, move) -> void:
	"""
	Apply secondary effects from a move (status, stat changes).

	Args:
		actor: BattlePokemon using the move
		target: BattlePokemon receiving the move
		move: MoveData being used
	"""
	# Determine target for stat changes (user or opponent)
	var effect_target = actor if move.targets_user else target

	# Apply status condition
	if move.applies_status():
		_try_apply_status(actor, target, move)

	# Apply stat stage changes
	if move.changes_stats():
		_apply_stat_changes(effect_target, move)


func _try_apply_status(actor, target, move) -> void:
	"""
	Attempt to apply status condition with percentage chance.

	Args:
		actor: BattlePokemon using the move
		target: BattlePokemon receiving the move
		move: MoveData with status effect
	"""
	var chance = move.get_status_inflict_chance()
	var roll = state._rng.randi_range(1, 100)

	if roll <= chance:
		var status = move.status_effect
		var success = target.apply_status(status, state._rng)

		if success:
			BattleEvents.status_applied.emit(target, status)
		# TODO: Emit status immunity event if failed due to existing status


func _apply_stat_changes(pokemon, move) -> void:
	"""
	Apply stat stage changes from a move.

	Args:
		pokemon: BattlePokemon receiving stat changes
		move: MoveData with stat_changes dictionary
	"""
	for stat_name in move.stat_changes:
		var change = move.stat_changes[stat_name]
		var actual_change = pokemon.modify_stat_stage(stat_name, change)

		if actual_change != 0:
			BattleEvents.stat_stage_changed.emit(
				pokemon,
				stat_name,
				actual_change,
				pokemon.stat_stages[stat_name]
			)


func _check_accuracy(attacker, defender, move) -> bool:
	"""
	Check if move hits based on accuracy and evasion stages.

	Args:
		attacker: BattlePokemon using the move
		defender: BattlePokemon receiving the move
		move: MoveData being used

	Returns:
		true if move hits, false if move misses
	"""
	# Never-miss moves (Swift, Aerial Ace, etc.)
	if move.never_misses():
		return true

	# Status moves with 0 accuracy always hit (like Thunder Wave with 100% accuracy represented as 0)
	if move.accuracy == 0:
		return true

	# Calculate accuracy with stat stages
	var accuracy_stage = attacker.stat_stages["accuracy"]
	var evasion_stage = defender.stat_stages["evasion"]
	var net_stage = accuracy_stage - evasion_stage

	# Stage multipliers: +6 = 3x, ... 0 = 1x, ... -6 = 0.33x
	var stage_multiplier = 1.0
	if net_stage > 0:
		stage_multiplier = (3.0 + net_stage) / 3.0
	elif net_stage < 0:
		stage_multiplier = 3.0 / (3.0 - net_stage)

	var final_accuracy = move.accuracy * stage_multiplier
	var roll = state._rng.randi_range(1, 100)

	return roll <= final_accuracy


func _check_critical_hit(attacker, move) -> bool:
	"""
	Determine if attack is a critical hit.

	Args:
		attacker: BattlePokemon using the move
		move: MoveData being used

	Returns:
		true if attack is a critical hit
	"""
	var crit_stage = 0

	# High crit ratio moves (Slash, Razor Leaf, etc.) add +1 stage
	if move.high_crit_ratio:
		crit_stage += 1

	# TODO: Add ability modifiers (Super Luck +1, etc.) in Phase 1 Week 6
	# TODO: Add item modifiers (Scope Lens +1, etc.) in Phase 1 Week 6

	# Use DamageCalculator with seeded RNG
	var chance = DamageCalculatorScript.calculate_critical_chance(crit_stage)
	var roll = state._rng.randf()

	return roll < chance


func _execute_switch(player: int, action) -> void:
	"""
	Execute a Pokemon switch.

	Args:
		player: Player number performing switch
		action: BattleAction with switch details
	"""
	var old_pokemon = state.get_active_pokemon(player)

	# Perform switch
	state.switch_pokemon(player, action.switch_index)

	var new_pokemon = state.get_active_pokemon(player)

	# Emit event
	BattleEvents.pokemon_switched.emit(player, old_pokemon, new_pokemon)


func _execute_forfeit(player: int) -> void:
	"""
	Execute a battle forfeit.

	Args:
		player: Player number forfeiting
	"""
	state.forfeit(player)
	BattleEvents.player_forfeited.emit(player)


func _apply_end_of_turn_effects() -> void:
	"""
	Apply all end-of-turn effects (weather damage, status damage, etc.).

	Called after all actions have executed but before turn advances.
	"""
	# Weather damage
	if state.weather in ["sandstorm", "hail"]:
		for player in [1, 2]:
			var pokemon = state.get_active_pokemon(player)

			if pokemon.is_fainted():
				continue

			# Sandstorm: damages non Rock/Ground/Steel types
			if state.weather == "sandstorm":
				var types = [pokemon.species.type1, pokemon.species.type2]
				if not ("rock" in types or "ground" in types or "steel" in types):
					var damage = maxi(1, floori(pokemon.max_hp / 16.0))
					pokemon.apply_damage(damage)
					BattleEvents.weather_damage.emit(pokemon, state.weather, damage)

					if pokemon.is_fainted():
						BattleEvents.pokemon_fainted.emit(pokemon)

			# Hail: damages non Ice types
			elif state.weather == "hail":
				var types = [pokemon.species.type1, pokemon.species.type2]
				if not "ice" in types:
					var damage = maxi(1, floori(pokemon.max_hp / 16.0))
					pokemon.apply_damage(damage)
					BattleEvents.weather_damage.emit(pokemon, state.weather, damage)

					if pokemon.is_fainted():
						BattleEvents.pokemon_fainted.emit(pokemon)

	# Status damage (burn, poison, badly poison)
	for player in [1, 2]:
		var pokemon = state.get_active_pokemon(player)

		if pokemon.is_fainted():
			continue

		match pokemon.status:
			"burn":
				var damage = maxi(1, floori(pokemon.max_hp / 16.0))
				pokemon.apply_damage(damage)
				BattleEvents.status_damage.emit(pokemon, "burn", damage)

				if pokemon.is_fainted():
					BattleEvents.pokemon_fainted.emit(pokemon)

			"poison":
				var damage = maxi(1, floori(pokemon.max_hp / 8.0))
				pokemon.apply_damage(damage)
				BattleEvents.status_damage.emit(pokemon, "poison", damage)

				if pokemon.is_fainted():
					BattleEvents.pokemon_fainted.emit(pokemon)

			"badly_poison":
				pokemon.status_counter += 1
				var damage = maxi(1, floori(pokemon.max_hp * pokemon.status_counter / 16.0))
				pokemon.apply_damage(damage)
				BattleEvents.status_damage.emit(pokemon, "badly_poison", damage)

				if pokemon.is_fainted():
					BattleEvents.pokemon_fainted.emit(pokemon)

# ==================== Query Methods ====================

func can_execute_action(player: int, action) -> bool:
	"""
	Check if an action can be legally executed.

	Args:
		player: Player number (1 or 2)
		action: BattleAction to validate

	Returns:
		true if action is legal
	"""
	assert(player == 1 or player == 2, "BattleEngine: player must be 1 or 2")
	assert(action != null, "BattleEngine: action cannot be null")

	var pokemon = state.get_active_pokemon(player)

	if action.is_forfeit():
		return true

	if action.is_switch():
		# Check if player has Pokemon to switch to
		if not state.can_switch(player):
			return false

		# Check if target Pokemon is valid
		var team = state.get_team(player)
		if action.switch_index < 0 or action.switch_index >= team.size():
			return false

		var target = team[action.switch_index]
		return not target.is_fainted()

	if action.is_move():
		# Check move index is valid
		if action.move_index < 0 or action.move_index >= pokemon.moves.size():
			return false

		# Check if move has PP
		return pokemon.can_use_move(action.move_index)

	return false


func get_legal_actions(player: int) -> Array:
	"""
	Get all legal actions for a player.

	Useful for AI systems and input validation.

	Args:
		player: Player number (1 or 2)

	Returns:
		Array of all valid BattleActions
	"""
	assert(player == 1 or player == 2, "BattleEngine: player must be 1 or 2")

	var actions = []  # Array of BattleAction
	var pokemon = state.get_active_pokemon(player)

	# Add move actions
	for i in range(pokemon.moves.size()):
		if pokemon.can_use_move(i):
			actions.append(BattleActionScript.new_move_action(i, 0))

	# Add switch actions
	if state.can_switch(player):
		var team = state.get_team(player)
		var active_idx = state.active1_index if player == 1 else state.active2_index

		for i in range(team.size()):
			if i != active_idx and not team[i].is_fainted():
				actions.append(BattleActionScript.new_switch_action(i))

	# Always allow forfeit
	actions.append(BattleActionScript.new_forfeit_action())

	return actions


func is_battle_over() -> bool:
	"""
	Check if the battle has ended.

	Returns:
		true if battle is over
	"""
	return state.is_battle_over()


func get_winner() -> int:
	"""
	Get the winning player number.

	Returns:
		1 if player 1 won, 2 if player 2 won, 0 if draw or battle ongoing
	"""
	return state.get_winner()
