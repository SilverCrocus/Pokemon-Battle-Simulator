class_name PokemonData
extends Resource

## Static Pokemon species data loaded from PokeAPI
##
## This Resource contains immutable data about a Pokemon species (base stats,
## types, abilities, learnset). Runtime battle instances use BattlePokemon class.

@export var pokemon_id: int = 0
@export var national_dex_number: int = 0
@export var name: String = ""
@export var form: String = "base"  # base, alola, galar, mega, etc.

# Base stats
@export var base_hp: int = 0
@export var base_atk: int = 0
@export var base_def: int = 0
@export var base_spa: int = 0
@export var base_spd: int = 0
@export var base_spe: int = 0

# Types (1 or 2)
@export var type1: String = ""
@export var type2: String = ""  # Empty string if mono-type

# Abilities
@export var abilities: Array[String] = []  # Ability names
@export var hidden_ability: String = ""

# Physical attributes
@export var height: int = 0  # in decimeters
@export var weight: int = 0  # in hectograms

# Generation
@export var generation: int = 9

# Learnset (move_name -> level learned, or "egg", "tm", "tutor")
@export var learnset: Dictionary = {}

# Flags
@export var is_legendary: bool = false
@export var is_mythical: bool = false


func get_base_stat_total() -> int:
	"""Calculate total base stats."""
	return base_hp + base_atk + base_def + base_spa + base_spd + base_spe


func get_types() -> Array[String]:
	"""Get array of types (1 or 2 elements)."""
	if type2.is_empty():
		return [type1]
	return [type1, type2]


func has_type(type_name: String) -> bool:
	"""Check if Pokemon has a specific type."""
	return type1 == type_name or type2 == type_name


func can_learn_move(move_name: String) -> bool:
	"""Check if Pokemon can learn a move."""
	return move_name in learnset


func get_all_abilities() -> Array[String]:
	"""Get all abilities including hidden ability."""
	var all_abilities = abilities.duplicate()
	if not hidden_ability.is_empty():
		all_abilities.append(hidden_ability)
	return all_abilities
