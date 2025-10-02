class_name OHKOEffect
extends "res://scripts/core/MoveEffect.gd"

## One-Hit KO effect
##
## Instantly faints the target if it hits. Accuracy is based on level difference.
## Examples:
##   - Guillotine (Normal)
##   - Horn Drill (Normal)
##   - Fissure (Ground)
##   - Sheer Cold (Ice)
##
## Mechanics:
##   - Accuracy = (user_level - target_level) + 30
##   - Fails if target level > user level
##   - Immune if target is higher level
##   - Type immunities still apply (Ground immune to Fissure, etc.)


func _init() -> void:
	super._init("One-Hit KO", 100, false)


func execute(context: Dictionary) -> Dictionary:
	"""
	Attempt to instantly KO the target.

	OHKO moves have special accuracy calculation:
	- Base accuracy = (attacker_level - defender_level) + 30
	- Fails if defender level > attacker level
	- Still respects type immunities

	Args:
		context: Must contain:
			- attacker: BattlePokemon
			- defender: BattlePokemon
			- move: MoveData
			- rng: RandomNumberGenerator
			- type_effectiveness: float (0.0 means immune)

	Returns:
		success: true if OHKO landed
		message: Description
		data: ohko flag
	"""
	var attacker = context["attacker"]  # BattlePokemon
	var defender = context["defender"]  # BattlePokemon
	var type_eff = context.get("type_effectiveness", 1.0)
	var rng = context["rng"]  # RandomNumberGenerator

	# Check type immunity (e.g., Flying immune to Fissure)
	if type_eff == 0.0:
		return {
			"success": false,
			"message": "It doesn't affect %s..." % defender.get_display_name(),
			"data": {}
		}

	# Check level difference
	if defender.level > attacker.level:
		return {
			"success": false,
			"message": "It failed!",
			"data": {}
		}

	# Calculate OHKO accuracy
	var accuracy = (attacker.level - defender.level) + 30

	# Roll for hit
	var roll = rng.randi_range(1, 100)
	if roll > accuracy:
		return {
			"success": false,
			"message": "It failed!",
			"data": {}
		}

	# OHKO lands - instantly faint target
	defender.current_hp = 0

	return {
		"success": true,
		"message": "It's a one-hit KO!",
		"data": {"ohko": true, "damage": defender.stats["hp"]}
	}
