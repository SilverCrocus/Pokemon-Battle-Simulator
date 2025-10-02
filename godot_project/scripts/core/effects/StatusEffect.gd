extends MoveEffect

## Status condition inflicting effect
##
## Applies a major status condition (burn, poison, paralysis, freeze, sleep, badly_poison)
## to the target Pokemon. Checks for existing status and type immunities.

var status_to_inflict: String = ""  # "burn", "poison", "paralysis", "freeze", "sleep", "badly_poison"


func _init(status: String, chance: int = 100) -> void:
	super._init("Inflict " + status.capitalize(), chance, false)
	status_to_inflict = status


func execute(context: Dictionary) -> Dictionary:
	"""
	Inflict status condition on target.

	Checks:
	- Target doesn't already have a status
	- Type immunities (Fire types can't be burned, etc.)
	- Abilities that prevent status

	Returns:
		success: true if status was applied
		message: Description of result
	"""
	var attacker = context["attacker"]  # BattlePokemon
	var defender = context["defender"]  # BattlePokemon
	var state = context["state"]  # BattleState

	# Check if defender already has a status
	if defender.status != "":
		return {
			"success": false,
			"message": "%s already has %s" % [defender.get_display_name(), defender.status],
			"data": {}
		}

	# Check type immunities
	if _is_immune_to_status(defender, status_to_inflict):
		return {
			"success": false,
			"message": "%s is immune to %s" % [defender.get_display_name(), status_to_inflict],
			"data": {}
		}

	# Apply status
	defender.status = status_to_inflict

	# Initialize status-specific data
	if status_to_inflict == "sleep":
		# Sleep lasts 1-3 turns
		defender.status_counter = state._rng.randi_range(1, 3)
	elif status_to_inflict == "badly_poison":
		# Toxic damage starts at 1/16 and increases each turn
		defender.status_counter = 1

	return {
		"success": true,
		"message": "%s was inflicted with %s!" % [defender.get_display_name(), status_to_inflict],
		"data": {"status": status_to_inflict}
	}


func _is_immune_to_status(pokemon, status: String) -> bool:
	"""
	Check if Pokemon is immune to a status condition.

	Type immunities:
	- Fire types can't be burned
	- Electric types can't be paralyzed
	- Ice types can't be frozen
	- Poison/Steel types can't be poisoned

	Args:
		pokemon: BattlePokemon to check
		status: Status condition to check

	Returns:
		True if immune
	"""
	var type1 = pokemon.species.type1
	var type2 = pokemon.species.type2

	match status:
		"burn":
			return type1 == "fire" or type2 == "fire"
		"paralysis":
			return type1 == "electric" or type2 == "electric"
		"freeze":
			return type1 == "ice" or type2 == "ice"
		"poison", "badly_poison":
			return type1 == "poison" or type2 == "poison" or type1 == "steel" or type2 == "steel"
		_:
			return false
