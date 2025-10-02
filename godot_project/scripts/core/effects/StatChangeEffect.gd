extends "res://scripts/core/MoveEffect.gd"

## Single stat stage change effect
##
## Changes a single stat stage by a specified amount (-6 to +6).
## Examples: Swords Dance (+2 atk), Growl (-1 atk), String Shot (-1 spe)

var stat: String = ""  # "atk", "def", "spa", "spd", "spe", "accuracy", "evasion"
var stages: int = 0  # -6 to +6


func _init(stat_name: String, stage_change: int, chance: int = 100, targets_self: bool = false) -> void:
	var target_str = " (self)" if targets_self else ""
	super._init("%s %d%s" % [stat_name.to_upper(), stage_change, target_str], chance, targets_self)
	stat = stat_name
	stages = stage_change


func execute(context: Dictionary) -> Dictionary:
	"""
	Change a stat stage.

	Args:
		context: Must contain attacker and defender BattlePokemon

	Returns:
		success: true if stat was changed
		message: Description of change
	"""
	var attacker = context["attacker"]  # BattlePokemon
	var defender = context["defender"]  # BattlePokemon

	# Determine target based on targets_user flag
	var target = attacker if targets_user else defender

	# Attempt to change stat stage
	var old_stage = target.stat_stages.get(stat, 0)
	var new_stage = clamp(old_stage + stages, -6, 6)
	var actual_change = new_stage - old_stage

	if actual_change == 0:
		# Stat is already at min/max
		var limit_msg = "maximum" if stages > 0 else "minimum"
		return {
			"success": false,
			"message": "%s's %s is already at %s!" % [target.get_display_name(), stat.to_upper(), limit_msg],
			"data": {}
		}

	# Apply change
	target.stat_stages[stat] = new_stage

	# Generate message
	var change_desc = _get_stat_change_description(actual_change)
	return {
		"success": true,
		"message": "%s's %s %s!" % [target.get_display_name(), stat.to_upper(), change_desc],
		"data": {"stat": stat, "old_stage": old_stage, "new_stage": new_stage, "change": actual_change}
	}


func _get_stat_change_description(change: int) -> String:
	"""
	Get description text for stat stage change.

	Examples:
		+1: "rose"
		+2: "rose sharply"
		+3: "rose drastically"
		-1: "fell"
		-2: "fell sharply"

	Args:
		change: Stat stage change amount

	Returns:
		Description string
	"""
	var is_positive = change > 0
	var magnitude = abs(change)

	var base_verb = "rose" if is_positive else "fell"

	match magnitude:
		1:
			return base_verb
		2:
			return base_verb + " sharply"
		_:
			return base_verb + " drastically"
