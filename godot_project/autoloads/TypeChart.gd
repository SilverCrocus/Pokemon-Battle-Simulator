extends Node

## TypeChart - Type Effectiveness System
##
## Manages Pokemon type effectiveness calculations.
## Loaded as an autoload singleton.

# Type effectiveness multipliers
const IMMUNE = 0.0
const QUARTER = 0.25
const HALF = 0.5
const NORMAL = 1.0
const DOUBLE = 2.0
const QUAD = 4.0

# Type effectiveness chart (attacking_type -> defending_type -> multiplier)
var type_chart: Dictionary = {}

# All valid types
var all_types: Array[String] = []


func _ready() -> void:
	"""Initialize type chart on game start."""
	_initialize_type_chart()


func _initialize_type_chart() -> void:
	"""
	Initialize the type effectiveness chart.
	This will be populated from downloaded PokeAPI data in the future.
	For now, hardcode Gen 9 type chart.
	"""
	all_types = [
		"normal", "fighting", "flying", "poison", "ground", "rock",
		"bug", "ghost", "steel", "fire", "water", "grass",
		"electric", "psychic", "ice", "dragon", "dark", "fairy", "stellar"
	]

	# Initialize all matchups to 1.0 (normal effectiveness)
	for atk_type in all_types:
		type_chart[atk_type] = {}
		for def_type in all_types:
			type_chart[atk_type][def_type] = NORMAL

	# Set super effective matchups (2x)
	_set_effectiveness("fighting", ["normal", "ice", "rock", "dark", "steel"], DOUBLE)
	_set_effectiveness("flying", ["fighting", "bug", "grass"], DOUBLE)
	_set_effectiveness("poison", ["grass", "fairy"], DOUBLE)
	_set_effectiveness("ground", ["fire", "electric", "poison", "rock", "steel"], DOUBLE)
	_set_effectiveness("rock", ["fire", "ice", "flying", "bug"], DOUBLE)
	_set_effectiveness("bug", ["grass", "psychic", "dark"], DOUBLE)
	_set_effectiveness("ghost", ["ghost", "psychic"], DOUBLE)
	_set_effectiveness("steel", ["ice", "rock", "fairy"], DOUBLE)
	_set_effectiveness("fire", ["grass", "ice", "bug", "steel"], DOUBLE)
	_set_effectiveness("water", ["fire", "ground", "rock"], DOUBLE)
	_set_effectiveness("grass", ["water", "ground", "rock"], DOUBLE)
	_set_effectiveness("electric", ["water", "flying"], DOUBLE)
	_set_effectiveness("psychic", ["fighting", "poison"], DOUBLE)
	_set_effectiveness("ice", ["grass", "ground", "flying", "dragon"], DOUBLE)
	_set_effectiveness("dragon", ["dragon"], DOUBLE)
	_set_effectiveness("dark", ["psychic", "ghost"], DOUBLE)
	_set_effectiveness("fairy", ["fighting", "dragon", "dark"], DOUBLE)

	# Set not very effective matchups (0.5x)
	_set_effectiveness("fighting", ["flying", "poison", "bug", "psychic", "fairy"], HALF)
	_set_effectiveness("flying", ["electric", "rock", "steel"], HALF)
	_set_effectiveness("poison", ["poison", "ground", "rock", "ghost"], HALF)
	_set_effectiveness("ground", ["grass", "bug"], HALF)
	_set_effectiveness("rock", ["fighting", "ground", "steel"], HALF)
	_set_effectiveness("bug", ["fire", "fighting", "flying", "poison", "ghost", "steel", "fairy"], HALF)
	_set_effectiveness("ghost", ["dark"], HALF)
	_set_effectiveness("steel", ["fire", "water", "electric", "steel"], HALF)
	_set_effectiveness("fire", ["fire", "water", "rock", "dragon"], HALF)
	_set_effectiveness("water", ["water", "grass", "dragon"], HALF)
	_set_effectiveness("grass", ["fire", "grass", "poison", "flying", "bug", "dragon", "steel"], HALF)
	_set_effectiveness("electric", ["electric", "grass", "dragon"], HALF)
	_set_effectiveness("psychic", ["psychic", "steel"], HALF)
	_set_effectiveness("ice", ["fire", "water", "ice", "steel"], HALF)
	_set_effectiveness("dragon", ["steel"], HALF)
	_set_effectiveness("dark", ["fighting", "dark", "fairy"], HALF)
	_set_effectiveness("fairy", ["fire", "poison", "steel"], HALF)

	# Set immune matchups (0x)
	_set_effectiveness("normal", ["ghost"], IMMUNE)
	_set_effectiveness("fighting", ["ghost"], IMMUNE)
	_set_effectiveness("poison", ["steel"], IMMUNE)
	_set_effectiveness("ground", ["flying"], IMMUNE)
	_set_effectiveness("ghost", ["normal"], IMMUNE)
	_set_effectiveness("electric", ["ground"], IMMUNE)
	_set_effectiveness("psychic", ["dark"], IMMUNE)
	_set_effectiveness("dragon", ["fairy"], IMMUNE)

	print("[TypeChart] Initialized with %d types" % all_types.size())


func _set_effectiveness(atk_type: String, def_types: Array, multiplier: float) -> void:
	"""Helper to set multiple type matchups at once."""
	for def_type in def_types:
		type_chart[atk_type][def_type] = multiplier


func get_effectiveness(atk_type: String, def_type: String) -> float:
	"""
	Get type effectiveness multiplier for attacking type vs defending type.
	Returns 0, 0.5, 1, or 2.
	"""
	if atk_type not in type_chart:
		push_warning("Unknown attacking type: %s" % atk_type)
		return NORMAL

	if def_type not in type_chart[atk_type]:
		push_warning("Unknown defending type: %s" % def_type)
		return NORMAL

	return type_chart[atk_type][def_type]


func calculate_type_effectiveness(atk_type: String, def_types: Array[String]) -> float:
	"""
	Calculate total type effectiveness against a Pokemon with 1 or 2 types.
	Multiplies effectiveness for each defending type.

	Examples:
	  - Fire vs Grass = 2.0 (super effective)
	  - Fire vs Grass/Water = 2.0 * 0.5 = 1.0 (neutral)
	  - Ice vs Grass/Dragon = 2.0 * 2.0 = 4.0 (quad effective)
	  - Ground vs Flying = 0.0 (immune)
	"""
	var total_multiplier: float = 1.0

	for def_type in def_types:
		total_multiplier *= get_effectiveness(atk_type, def_type)

	return total_multiplier


func get_effectiveness_text(multiplier: float) -> String:
	"""
	Get human-readable effectiveness text.
	"""
	if multiplier == IMMUNE:
		return "No Effect"
	elif multiplier == QUARTER:
		return "Not Very Effective (1/4x)"
	elif multiplier == HALF:
		return "Not Very Effective"
	elif multiplier == NORMAL:
		return "Neutral"
	elif multiplier == DOUBLE:
		return "Super Effective"
	elif multiplier == QUAD:
		return "Super Effective (4x)"
	else:
		return "Unknown"


func is_super_effective(multiplier: float) -> bool:
	"""Check if effectiveness is super effective (>1.0)."""
	return multiplier > NORMAL


func is_not_very_effective(multiplier: float) -> bool:
	"""Check if effectiveness is not very effective (<1.0 but not immune)."""
	return multiplier < NORMAL and multiplier > IMMUNE


func is_immune(multiplier: float) -> bool:
	"""Check if effectiveness is immune (0)."""
	return multiplier == IMMUNE


func get_all_types() -> Array[String]:
	"""Get array of all valid types."""
	return all_types.duplicate()
