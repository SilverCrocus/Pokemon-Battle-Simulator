class_name MoveData
extends Resource

## Static move data loaded from PokeAPI
##
## This Resource contains immutable data about a move (power, accuracy, type, effects).

@export var move_id: int = 0
@export var name: String = ""
@export var type: String = ""

# Move mechanics
@export var power: int = 0  # 0 for status moves
@export var accuracy: int = 0  # 0-100, or 0 for never-miss moves
@export var pp: int = 0
@export var priority: int = 0  # -7 to +5
@export var damage_class: String = ""  # "physical", "special", "status"

# Effects
@export var effect_description: String = ""
@export var short_effect: String = ""
@export var effect_chance: int = 0  # Percentage chance for secondary effect

# Status conditions (Phase 1 Week 5)
@export var status_effect: String = ""  # "burn", "poison", "paralysis", "freeze", "sleep", "badly_poison", ""
@export var stat_changes: Dictionary = {}  # {"atk": 1, "def": -1} etc.
@export var targets_user: bool = false  # true for self-buffs like Swords Dance
@export var high_crit_ratio: bool = false  # true for moves like Slash, Razor Leaf

# Target
@export var target: String = ""  # "selected-pokemon", "all-opponents", etc.

# Metadata
@export var generation: int = 9
@export var is_z_move: bool = false
@export var is_max_move: bool = false
@export var is_gmax_move: bool = false

# Move flags (for specific mechanics)
@export var makes_contact: bool = false
@export var is_sound_move: bool = false
@export var is_punch_move: bool = false
@export var is_bite_move: bool = false
@export var is_bullet_move: bool = false
@export var is_wind_move: bool = false


func is_damaging() -> bool:
	"""Check if move deals damage."""
	return damage_class in ["physical", "special"]


func is_physical() -> bool:
	"""Check if move is physical."""
	return damage_class == "physical"


func is_special() -> bool:
	"""Check if move is special."""
	return damage_class == "special"


func is_status() -> bool:
	"""Check if move is a status move."""
	return damage_class == "status"


func never_misses() -> bool:
	"""Check if move never misses (like Swift)."""
	return accuracy == 0 and is_damaging()


func has_secondary_effect() -> bool:
	"""Check if move has a secondary effect."""
	return effect_chance > 0


func applies_status() -> bool:
	"""Check if move can apply a status condition."""
	return status_effect != "" and effect_chance > 0


func get_status_inflict_chance() -> int:
	"""
	Get percentage chance to inflict status.

	Returns:
		Percentage chance (0-100), or 0 if no status effect
	"""
	if status_effect == "":
		return 0
	return effect_chance


func changes_stats() -> bool:
	"""Check if move changes stat stages."""
	return not stat_changes.is_empty()
