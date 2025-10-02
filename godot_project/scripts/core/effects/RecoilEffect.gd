class_name RecoilEffect
extends "res://scripts/core/MoveEffect.gd"

## Recoil damage effect
##
## User takes damage equal to a percentage of damage dealt.
## Examples:
##   - Brave Bird, Flare Blitz: 33% recoil (1/3)
##   - Double-Edge: 33% recoil
##   - Take Down: 25% recoil (1/4)
##   - Head Smash: 50% recoil (1/2)

var recoil_percent: int = 0  # Percentage of damage dealt


func _init(percent: int) -> void:
	super._init("Recoil (%d%%)" % percent, 100, true)
	recoil_percent = percent


func execute(context: Dictionary) -> Dictionary:
	"""
	Apply recoil damage to user.

	Args:
		context: Must contain:
			- attacker: BattlePokemon using the move
			- damage_dealt: int, damage dealt by the move

	Returns:
		success: true if recoil was applied
		message: Description of recoil
		data: recoil_damage amount
	"""
	var attacker = context["attacker"]  # BattlePokemon
	var damage_dealt = context.get("damage_dealt", 0)  # int

	if damage_dealt <= 0:
		# No damage was dealt, no recoil
		return {
			"success": false,
			"message": "",
			"data": {}
		}

	# Calculate recoil (minimum 1 damage)
	var recoil_damage = max(1, int(damage_dealt * recoil_percent / 100.0))

	# Apply recoil to attacker
	attacker.take_damage(recoil_damage)

	return {
		"success": true,
		"message": "%s was damaged by recoil!" % attacker.get_display_name(),
		"data": {"recoil_damage": recoil_damage}
	}
