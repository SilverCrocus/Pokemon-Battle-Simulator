class_name ActionQueue
extends RefCounted

## Action priority queue for turn-based battle execution
##
## Manages the order in which battle actions are executed during a turn.
## Actions are sorted by Pokemon battle priority rules:
## 1. Action type (switch > move > forfeit)
## 2. Move priority bracket (-7 to +5)
## 3. Pokemon speed stat
## 4. Random tiebreaker (if same speed)
##
## This implementation follows Pokemon Showdown's action queue system,
## ensuring accurate priority resolution for competitive battle mechanics.
##
## Example usage:
## [codeblock]
## var queue = ActionQueue.new(battle_state._rng)
## var pikachu = state.get_active_pokemon(1)
## var charizard = state.get_active_pokemon(2)
##
## # Add player actions
## queue.add_action(1, move_action, pikachu, state)
## queue.add_action(2, switch_action, charizard, state)
##
## # Execute in priority order
## while queue.has_actions():
##     var queued = queue.pop_next()
##     execute_action(queued)
## [/codeblock]

## Queued action data structure
##
## Contains all information needed to execute an action in priority order,
## including the action itself, the Pokemon performing it, and priority metadata.
class QueuedAction:
	## Player number (1 or 2)
	var player: int

	## Battle action to execute
	var action  # BattleAction

	## Pokemon performing the action
	var actor  # BattlePokemon

	## Execution order category (lower goes first)
	var order: int

	## Move priority (-7 to +5, higher goes first)
	var priority: int

	## Pokemon speed at time of action (for priority resolution)
	var speed: int

	## Random tiebreaker value (for identical priority/speed)
	var tie_breaker: int

	func _init(
		p_player: int,
		p_action,  # BattleAction
		p_actor,  # BattlePokemon
		p_order: int,
		p_priority: int,
		p_speed: int,
		p_tie_breaker: int
	) -> void:
		"""
		Initialize a queued action.

		Args:
			p_player: Player number (1 or 2)
			p_action: BattleAction to execute
			p_actor: BattlePokemon performing action
			p_order: Execution order category
			p_priority: Move priority bracket
			p_speed: Pokemon speed stat
			p_tie_breaker: Random value for tiebreaking
		"""
		player = p_player
		action = p_action
		actor = p_actor
		order = p_order
		priority = p_priority
		speed = p_speed
		tie_breaker = p_tie_breaker

## Action execution order constants
const ORDER_FORFEIT = 0        # Forfeits process immediately
const ORDER_SWITCH = 103       # Switches always go first (after forfeit)
const ORDER_MOVE = 200         # Moves execute by priority/speed

## Queued actions list
var _actions: Array[QueuedAction] = []

## Random number generator for deterministic tiebreaking
var _rng: RandomNumberGenerator


func _init(p_rng: RandomNumberGenerator) -> void:
	"""
	Initialize action queue with RNG for deterministic behavior.

	Args:
		p_rng: RandomNumberGenerator from BattleState (for determinism)
	"""
	assert(p_rng != null, "ActionQueue: RNG cannot be null")
	_rng = p_rng


func add_action(
	player: int,
	action,  # BattleAction
	actor,  # BattlePokemon
	state  # BattleState
) -> void:
	"""
	Add an action to the queue with proper priority calculation.

	Actions are inserted in sorted order to maintain priority queue invariant.
	Speed ties are resolved randomly using the battle's RNG for deterministic replay.

	Args:
		player: Player number (1 or 2)
		action: BattleAction to queue
		actor: BattlePokemon performing the action
		state: Current BattleState (for priority calculations)
	"""
	assert(player == 1 or player == 2, "ActionQueue: player must be 1 or 2, got %d" % player)
	assert(action != null, "ActionQueue: action cannot be null")
	assert(actor != null, "ActionQueue: actor cannot be null")
	assert(state != null, "ActionQueue: state cannot be null")

	# Calculate priority metadata
	var order = _get_action_order(action)
	var priority = _calculate_priority(action, actor, state)
	var speed = actor.get_stat_with_stage("spe")
	var tie_breaker = _rng.randi()

	# Create queued action
	var queued = QueuedAction.new(
		player,
		action,
		actor,
		order,
		priority,
		speed,
		tie_breaker
	)

	# Insert in sorted position
	_insert_sorted(queued)


func _get_action_order(action) -> int:  # BattleAction parameter
	"""
	Get the execution order category for an action.

	Args:
		action: BattleAction to categorize

	Returns:
		Order value (lower executes first)
	"""
	if action.is_forfeit():
		return ORDER_FORFEIT
	elif action.is_switch():
		return ORDER_SWITCH
	else:  # is_move()
		return ORDER_MOVE


func _calculate_priority(
	action,  # BattleAction
	actor,  # BattlePokemon
	state  # BattleState
) -> int:
	"""
	Calculate move priority with ability/item modifiers.

	Base priority comes from the move itself (-7 to +5).
	Abilities and items can modify this further.

	Args:
		action: BattleAction being performed
		actor: BattlePokemon performing action
		state: Current BattleState

	Returns:
		Final priority value (higher goes first)
	"""
	# Non-move actions have no priority
	if not action.is_move():
		return 0

	var move = actor.moves[action.move_index]
	var base_priority = move.priority

	# TODO: Apply ability modifiers (Phase 1 Week 5)
	# - Prankster: +1 priority for status moves
	# - Gale Wings: +1 priority for Flying moves at full HP
	# - Triage: +3 priority for healing moves

	# TODO: Apply item modifiers (Phase 1 Week 5)
	# - Quick Claw: Random +1 priority (20% chance)
	# - Custap Berry: +1 priority when HP < 25%
	# - Lagging Tail/Full Incense: Always move last

	return base_priority


func _insert_sorted(new_action: QueuedAction) -> void:
	"""
	Insert action into queue maintaining sort order.

	Uses binary search to find insertion range for actions with identical priority,
	then randomly inserts within that range for speed tie resolution.

	This implements Pokemon Showdown's Fisher-Yates insertion algorithm.

	Args:
		new_action: QueuedAction to insert
	"""
	# Empty queue case
	if _actions.is_empty():
		_actions.append(new_action)
		return

	# Find insertion range (all actions with same priority)
	var first_idx = 0
	var last_idx = _actions.size()

	for i in range(_actions.size()):
		var cmp = _compare_priority(new_action, _actions[i])

		if cmp < 0:
			# New action has higher priority, goes before this action
			last_idx = i
			break
		elif cmp > 0:
			# New action has lower priority, goes after this action
			first_idx = i + 1

	# Randomly insert within tie range (speed tie resolution)
	var insert_idx = first_idx
	if first_idx < last_idx:
		insert_idx = _rng.randi_range(first_idx, last_idx)

	_actions.insert(insert_idx, new_action)


func _compare_priority(a: QueuedAction, b: QueuedAction) -> int:
	"""
	Compare two actions for priority ordering.

	Priority rules (in order):
	1. Lower order value goes first (forfeit < switch < move)
	2. Higher priority bracket goes first (+5 > 0 > -7)
	3. Higher speed goes first (100 > 50)
	4. Higher tie_breaker goes first (random)

	Args:
		a: First QueuedAction
		b: Second QueuedAction

	Returns:
		Negative if a goes first, positive if b goes first, 0 if tie
	"""
	# Compare order (lower goes first)
	if a.order != b.order:
		return a.order - b.order

	# Compare priority (higher goes first)
	if a.priority != b.priority:
		return b.priority - a.priority

	# Compare speed (higher goes first)
	if a.speed != b.speed:
		return b.speed - a.speed

	# Compare tie breaker (higher goes first)
	return b.tie_breaker - a.tie_breaker


func pop_next() -> QueuedAction:
	"""
	Remove and return the next action to execute.

	Returns:
		QueuedAction with highest priority
	"""
	assert(not _actions.is_empty(), "ActionQueue: cannot pop from empty queue")
	return _actions.pop_front()


func has_actions() -> bool:
	"""
	Check if the queue has any remaining actions.

	Returns:
		true if queue is not empty
	"""
	return not _actions.is_empty()


func clear() -> void:
	"""Clear all actions from the queue."""
	_actions.clear()


func size() -> int:
	"""
	Get the number of queued actions.

	Returns:
		Number of actions in queue
	"""
	return _actions.size()


func recalculate_speeds() -> void:
	"""
	Recalculate speed values for all queued actions.

	Called when speeds change mid-turn (e.g., paralysis, stat changes).
	After recalculation, the queue is re-sorted to maintain correct order.
	"""
	# Update speeds
	for queued in _actions:
		queued.speed = queued.actor.get_stat_with_stage("spe")

	# Re-sort with new speeds
	_actions.sort_custom(func(a: QueuedAction, b: QueuedAction) -> bool:
		return _compare_priority(a, b) < 0
	)


func peek_next() -> QueuedAction:
	"""
	View the next action without removing it.

	Returns:
		Next QueuedAction to execute (null if empty)
	"""
	if _actions.is_empty():
		return null
	return _actions[0]


func get_actions() -> Array[QueuedAction]:
	"""
	Get a copy of all queued actions (for debugging/testing).

	Returns:
		Array of all QueuedActions in priority order
	"""
	return _actions.duplicate()
