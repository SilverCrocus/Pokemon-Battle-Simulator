class_name BattleAction
extends RefCounted

## Player action during battle
##
## Represents a single action a player can take during their turn: using a move,
## switching Pokemon, or forfeiting the battle. This class encapsulates all the
## information needed to execute a turn action.
##
## Example usage:
## [codeblock]
## # Create a move action
## var move_action = BattleAction.new_move_action(0, 0)  # Use first move, target opponent's active Pokemon
##
## # Create a switch action
## var switch_action = BattleAction.new_switch_action(2)  # Switch to third Pokemon in party
##
## # Create a forfeit action
## var forfeit_action = BattleAction.new_forfeit_action()
## [/codeblock]

## Action type constants
enum ActionType {
	MOVE,      ## Use a move
	SWITCH,    ## Switch to another Pokemon
	FORFEIT    ## Give up the battle
}

## Type of action (MOVE, SWITCH, or FORFEIT)
var action_type: ActionType

## Index of move to use (0-3, only valid for MOVE actions)
var move_index: int = -1

## Index of target Pokemon (0 for opponent's active Pokemon in singles)
var target_index: int = -1

## Index of Pokemon to switch to (0-5, only valid for SWITCH actions)
var switch_index: int = -1


func _init(
	p_action_type: ActionType,
	p_move_index: int = -1,
	p_target_index: int = -1,
	p_switch_index: int = -1
) -> void:
	"""
	Initialize a battle action.

	Args:
		p_action_type: Type of action to perform
		p_move_index: Index of move to use (for MOVE actions)
		p_target_index: Index of target Pokemon (for MOVE actions)
		p_switch_index: Index of Pokemon to switch to (for SWITCH actions)
	"""
	action_type = p_action_type
	move_index = p_move_index
	target_index = p_target_index
	switch_index = p_switch_index

	# Validate action data
	_validate_action()


func _validate_action() -> void:
	"""Validate that the action has appropriate data for its type."""
	match action_type:
		ActionType.MOVE:
			assert(move_index >= 0 and move_index <= 3,
				"BattleAction: MOVE action requires move_index between 0-3, got %d" % move_index)
			assert(target_index >= 0,
				"BattleAction: MOVE action requires valid target_index, got %d" % target_index)

		ActionType.SWITCH:
			assert(switch_index >= 0 and switch_index <= 5,
				"BattleAction: SWITCH action requires switch_index between 0-5, got %d" % switch_index)

		ActionType.FORFEIT:
			# No additional validation needed
			pass


static func new_move_action(p_move_index: int, p_target_index: int = 0) -> BattleAction:
	"""
	Create a new MOVE action.

	Args:
		p_move_index: Index of move to use (0-3)
		p_target_index: Index of target Pokemon (default 0)

	Returns:
		New BattleAction configured for using a move
	"""
	return load("res://scripts/core/BattleAction.gd").new(ActionType.MOVE, p_move_index, p_target_index, -1)


static func new_switch_action(p_switch_index: int) -> BattleAction:
	"""
	Create a new SWITCH action.

	Args:
		p_switch_index: Index of Pokemon to switch to (0-5)

	Returns:
		New BattleAction configured for switching Pokemon
	"""
	return load("res://scripts/core/BattleAction.gd").new(ActionType.SWITCH, -1, -1, p_switch_index)


static func new_forfeit_action() -> BattleAction:
	"""
	Create a new FORFEIT action.

	Returns:
		New BattleAction configured for forfeiting the battle
	"""
	return load("res://scripts/core/BattleAction.gd").new(ActionType.FORFEIT, -1, -1, -1)


func is_move() -> bool:
	"""
	Check if this is a MOVE action.

	Returns:
		true if action type is MOVE
	"""
	return action_type == ActionType.MOVE


func is_switch() -> bool:
	"""
	Check if this is a SWITCH action.

	Returns:
		true if action type is SWITCH
	"""
	return action_type == ActionType.SWITCH


func is_forfeit() -> bool:
	"""
	Check if this is a FORFEIT action.

	Returns:
		true if action type is FORFEIT
	"""
	return action_type == ActionType.FORFEIT


func get_action_type_string() -> String:
	"""
	Get the action type as a readable string.

	Returns:
		Action type name ("MOVE", "SWITCH", or "FORFEIT")
	"""
	match action_type:
		ActionType.MOVE:
			return "MOVE"
		ActionType.SWITCH:
			return "SWITCH"
		ActionType.FORFEIT:
			return "FORFEIT"
		_:
			return "UNKNOWN"


func get_description() -> String:
	"""
	Get a human-readable description of this action.

	Returns:
		String describing the action
	"""
	match action_type:
		ActionType.MOVE:
			return "Use move %d on target %d" % [move_index, target_index]
		ActionType.SWITCH:
			return "Switch to Pokemon %d" % switch_index
		ActionType.FORFEIT:
			return "Forfeit battle"
		_:
			return "Unknown action"


func duplicate_action() -> BattleAction:
	"""
	Create a duplicate of this action.

	Returns:
		New BattleAction with identical properties
	"""
	return load("res://scripts/core/BattleAction.gd").new(action_type, move_index, target_index, switch_index)


func equals(other: BattleAction) -> bool:
	"""
	Check if this action is equal to another action.

	Args:
		other: BattleAction to compare with

	Returns:
		true if actions are identical
	"""
	if other == null:
		return false

	return (
		action_type == other.action_type and
		move_index == other.move_index and
		target_index == other.target_index and
		switch_index == other.switch_index
	)


func to_dict() -> Dictionary:
	"""
	Convert action to a dictionary for serialization.

	Returns:
		Dictionary containing action data
	"""
	return {
		"action_type": action_type,
		"move_index": move_index,
		"target_index": target_index,
		"switch_index": switch_index
	}


static func from_dict(data: Dictionary) -> BattleAction:
	"""
	Create a BattleAction from a dictionary.

	Args:
		data: Dictionary containing action data

	Returns:
		New BattleAction reconstructed from dictionary
	"""
	return load("res://scripts/core/BattleAction.gd").new(
		data.get("action_type", ActionType.FORFEIT),
		data.get("move_index", -1),
		data.get("target_index", -1),
		data.get("switch_index", -1)
	)
