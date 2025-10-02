class_name FlinchEffect
extends "res://scripts/core/MoveEffect.gd"

## Flinch effect
##
## Causes the target to flinch this turn, preventing them from moving.
## Only works if the user moves first (usually from higher speed or priority).
##
## Examples:
##   - Fake Out: 100% flinch (priority +3)
##   - Iron Head: 30% flinch
##   - Air Slash: 30% flinch
##   - Zen Headbutt: 20% flinch
##
## Note: Flinch is turn-specific and cleared at the end of each turn.


func _init(chance: int = 100) -> void:
	super._init("Flinch", chance, false)


func execute(context: Dictionary) -> Dictionary:
	"""
	Cause target to flinch.

	Flinch only works if:
	1. The target hasn't moved yet this turn
	2. The user moved first

	Args:
		context: Must contain:
			- defender: BattlePokemon being targeted
			- turn_order: Array of who has moved this turn (optional)

	Returns:
		success: true if flinch was applied
		message: Description
	"""
	var defender = context["defender"]  # BattlePokemon

	# Check if defender has already moved this turn
	# (In real implementation, BattleEngine tracks this)
	var already_moved = context.get("defender_already_moved", false)

	if already_moved:
		# Can't flinch if target already moved
		return {
			"success": false,
			"message": "",
			"data": {}
		}

	# Set flinch flag (BattleEngine will check this before executing defender's action)
	# Note: This requires adding a flinched flag to BattlePokemon or BattleState
	# For now, we'll return success and BattleEngine needs to handle it

	return {
		"success": true,
		"message": "%s flinched!" % defender.get_display_name(),
		"data": {"flinched": true}
	}
