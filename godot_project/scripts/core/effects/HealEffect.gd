class_name HealEffect
extends "res://scripts/core/MoveEffect.gd"

## Healing effect
##
## Restores HP to the user or target.
##
## Heal Types:
##   - Fixed amount: Restores exact HP (e.g., Softboiled restores 1/2 max HP)
##   - Percentage: Restores % of max HP
##   - Weather-based: Varies based on weather (e.g., Synthesis, Morning Sun)
##
## Examples:
##   - Recover: Restores 1/2 max HP
##   - Roost: Restores 1/2 max HP, removes Flying type for turn
##   - Synthesis: 1/2 in normal, 2/3 in sun, 1/4 in rain/sand/hail
##   - Shore Up: 1/2 in normal, 2/3 in sandstorm
##   - Wish: Heals next turn (requires special handling)

var heal_percent: int = 50  # Percentage of max HP to restore
var weather_based: bool = false  # If true, amount varies by weather


func _init(percent: int = 50, weather_dependent: bool = false) -> void:
	super._init("Heal %d%%" % percent, 100, true)
	heal_percent = percent
	weather_based = weather_dependent


func execute(context: Dictionary) -> Dictionary:
	"""
	Restore HP to user.

	Args:
		context: Must contain:
			- attacker: BattlePokemon
			- state: BattleState (for weather info if needed)

	Returns:
		success: true if HP was restored
		message: Heal description
		data: hp_restored amount
	"""
	var attacker = context["attacker"]  # BattlePokemon
	var state = context.get("state")  # BattleState (optional)

	# Check if already at max HP
	if attacker.current_hp >= attacker.stats["hp"]:
		return {
			"success": false,
			"message": "%s's HP is already full!" % attacker.get_display_name(),
			"data": {}
		}

	# Calculate heal amount
	var heal_amount = _calculate_heal_amount(attacker, state)

	# Heal the Pokemon
	var hp_before = attacker.current_hp
	attacker.heal(heal_amount)
	var actual_heal = attacker.current_hp - hp_before

	return {
		"success": true,
		"message": "%s restored HP!" % attacker.get_display_name(),
		"data": {"hp_restored": actual_heal}
	}


func _calculate_heal_amount(pokemon, state) -> int:
	"""
	Calculate heal amount based on weather if applicable.

	Weather modifiers (for Synthesis, Morning Sun, Moonlight):
	- Sun: 2/3 max HP (66%)
	- Normal: 1/2 max HP (50%)
	- Rain/Sand/Hail/Snow: 1/4 max HP (25%)

	Args:
		pokemon: BattlePokemon to heal
		state: BattleState (can be null if not weather-based)

	Returns:
		HP to restore
	"""
	var max_hp = pokemon.stats["hp"]
	var base_percent = heal_percent

	if weather_based and state:
		var weather = state.get("weather", "")
		match weather:
			"sun":
				base_percent = 66  # 2/3
			"rain", "sandstorm", "hail", "snow":
				base_percent = 25  # 1/4
			_:
				base_percent = 50  # 1/2 (normal weather)

	return max(1, int(max_hp * base_percent / 100.0))


func get_description() -> String:
	"""Get description with heal amount."""
	if weather_based:
		return "Heal (weather-based)"
	else:
		return "Heal %d%%" % heal_percent
