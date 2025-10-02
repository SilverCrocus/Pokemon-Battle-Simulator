extends MoveEffect

## HP drain effect
##
## User recovers HP equal to a percentage of damage dealt.
## Examples:
##   - Giga Drain, Drain Punch: 50% drain (1/2)
##   - Absorb, Mega Drain: 50% drain
##   - Leech Life: 50% drain (was 25% in older gens)
##   - Dream Eater: 50% drain
##   - Draining Kiss: 75% drain (3/4)

var drain_percent: int = 0  # Percentage of damage dealt


func _init(percent: int) -> void:
	super._init("Drain (%d%%)" % percent, 100, true)
	drain_percent = percent


func execute(context: Dictionary) -> Dictionary:
	"""
	Drain HP from target.

	Args:
		context: Must contain:
			- attacker: BattlePokemon using the move
			- damage_dealt: int, damage dealt by the move

	Returns:
		success: true if HP was drained
		message: Description of drain
		data: hp_drained amount
	"""
	var attacker = context["attacker"]  # BattlePokemon
	var damage_dealt = context.get("damage_dealt", 0)  # int

	if damage_dealt <= 0:
		# No damage was dealt, no drain
		return {
			"success": false,
			"message": "",
			"data": {}
		}

	# Calculate drain (minimum 1 HP)
	var hp_drained = max(1, int(damage_dealt * drain_percent / 100.0))

	# Heal attacker (capped at max HP)
	var hp_before = attacker.current_hp
	attacker.heal(hp_drained)
	var actual_heal = attacker.current_hp - hp_before

	return {
		"success": true,
		"message": "%s drained HP from the target!" % attacker.get_display_name(),
		"data": {"hp_drained": actual_heal}
	}
