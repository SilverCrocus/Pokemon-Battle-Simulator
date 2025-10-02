class_name MultiStatChangeEffect
extends "res://scripts/core/MoveEffect.gd"

## Multiple stat stage change effect
##
## Changes multiple stat stages simultaneously.
## Examples:
##   - Bulk Up: +1 atk, +1 def
##   - Dragon Dance: +1 atk, +1 spe
##   - Calm Mind: +1 spa, +1 spd
##   - Curse (Ghost): +1 atk, +1 def, -1 spe

var stat_changes: Dictionary = {}  # {"atk": 2, "def": 1, "spe": -1}


func _init(changes: Dictionary, chance: int = 100, targets_self: bool = false) -> void:
	var change_desc = _format_changes(changes)
	super._init("Multi-stat change: %s" % change_desc, chance, targets_self)
	stat_changes = changes


func execute(context: Dictionary) -> Dictionary:
	"""
	Change multiple stat stages.

	Args:
		context: Must contain attacker and defender BattlePokemon

	Returns:
		success: true if any stat was changed
		message: Description of changes
		data: Dictionary with results for each stat
	"""
	var attacker = context["attacker"]  # BattlePokemon
	var defender = context["defender"]  # BattlePokemon

	# Determine target based on targets_user flag
	var target = attacker if targets_user else defender

	var changes_applied: Dictionary = {}
	var any_change = false

	# Apply each stat change
	for stat in stat_changes:
		var stage_change = stat_changes[stat]
		var old_stage = target.stat_stages.get(stat, 0)
		var new_stage = clamp(old_stage + stage_change, -6, 6)
		var actual_change = new_stage - old_stage

		if actual_change != 0:
			target.stat_stages[stat] = new_stage
			changes_applied[stat] = actual_change
			any_change = true

	if not any_change:
		return {
			"success": false,
			"message": "%s's stats are already at their limits!" % target.get_display_name(),
			"data": {}
		}

	# Generate message
	var message_parts = []
	for stat in changes_applied:
		var change = changes_applied[stat]
		var change_desc = _get_stat_change_description(stat, change)
		message_parts.append(change_desc)

	var full_message = "%s: %s!" % [target.get_display_name(), ", ".join(message_parts)]

	return {
		"success": true,
		"message": full_message,
		"data": changes_applied
	}


func _format_changes(changes: Dictionary) -> String:
	"""Format stat changes for effect name."""
	var parts = []
	for stat in changes:
		var change = changes[stat]
		var sign = "+" if change > 0 else ""
		parts.append("%s%d %s" % [sign, change, stat.to_upper()])
	return ", ".join(parts)


func _get_stat_change_description(stat: String, change: int) -> String:
	"""
	Get description text for a single stat change.

	Args:
		stat: Stat name
		change: Stage change amount

	Returns:
		Description string (e.g., "Attack rose sharply")
	"""
	var is_positive = change > 0
	var magnitude = abs(change)

	var stat_name = stat.to_upper()
	var base_verb = "rose" if is_positive else "fell"

	var adverb = ""
	match magnitude:
		1:
			adverb = ""
		2:
			adverb = " sharply"
		_:
			adverb = " drastically"

	return "%s %s%s" % [stat_name, base_verb, adverb]
