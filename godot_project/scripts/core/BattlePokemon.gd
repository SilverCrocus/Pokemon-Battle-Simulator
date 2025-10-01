class_name BattlePokemon
extends RefCounted

## Runtime battle Pokemon instance
##
## Represents a Pokemon during battle with calculated stats, current HP, status conditions,
## stat stages, and all battle-relevant properties. This class combines static species data
## (PokemonData) with runtime instance data (IVs, EVs, nature, level).
##
## Example usage:
## [codeblock]
## var species = DataManager.get_pokemon("pikachu")
## var pikachu = BattlePokemon.new(
##     species,
##     50,  # level
##     {"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},  # IVs
##     {"spe": 252, "spa": 252, "hp": 4},  # EVs
##     "Jolly",  # nature
##     [move1, move2, move3, move4],  # moves
##     "Static"  # ability
## )
## [/codeblock]

## Reference to static species data
var species: PokemonData

## Pokemon level (1-100)
var level: int

## Individual Values - determines stat variance between same species (0-31 each)
var ivs: Dictionary = {
	"hp": 31,
	"atk": 31,
	"def": 31,
	"spa": 31,
	"spd": 31,
	"spe": 31
}

## Effort Values - earned from training, max 252 per stat, 510 total (0-252 each)
var evs: Dictionary = {
	"hp": 0,
	"atk": 0,
	"def": 0,
	"spa": 0,
	"spd": 0,
	"spe": 0
}

## Nature name (affects stat multipliers)
var nature: String

## Current HP (0 to max_hp)
var current_hp: int

## Maximum HP (calculated from stats)
var max_hp: int

## Calculated stats (hp, atk, def, spa, spd, spe)
var stats: Dictionary = {}

## Stat stages during battle (-6 to +6 for each stat)
var stat_stages: Dictionary = {
	"atk": 0,
	"def": 0,
	"spa": 0,
	"spd": 0,
	"spe": 0,
	"accuracy": 0,
	"evasion": 0
}

## Current status condition
var status: String = "none"

## Status counter (sleep turns remaining, toxic counter)
var status_counter: int = 0

## Moves known by this Pokemon (1-4 moves)
var moves: Array[MoveData] = []

## Current PP for each move (parallel to moves array)
var move_pp: Array[int] = []

## Active ability name
var ability: String

## Held item name (empty string if no item)
var item: String = ""

## Custom nickname (empty string uses species name)
var nickname: String = ""

## Valid nature names and their stat modifications
const NATURES: Dictionary = {
	"Hardy": {"increase": "", "decrease": ""},
	"Lonely": {"increase": "atk", "decrease": "def"},
	"Brave": {"increase": "atk", "decrease": "spe"},
	"Adamant": {"increase": "atk", "decrease": "spa"},
	"Naughty": {"increase": "atk", "decrease": "spd"},
	"Bold": {"increase": "def", "decrease": "atk"},
	"Docile": {"increase": "", "decrease": ""},
	"Relaxed": {"increase": "def", "decrease": "spe"},
	"Impish": {"increase": "def", "decrease": "spa"},
	"Lax": {"increase": "def", "decrease": "spd"},
	"Timid": {"increase": "spe", "decrease": "atk"},
	"Hasty": {"increase": "spe", "decrease": "def"},
	"Serious": {"increase": "", "decrease": ""},
	"Jolly": {"increase": "spe", "decrease": "spa"},
	"Naive": {"increase": "spe", "decrease": "spd"},
	"Modest": {"increase": "spa", "decrease": "atk"},
	"Mild": {"increase": "spa", "decrease": "def"},
	"Quiet": {"increase": "spa", "decrease": "spe"},
	"Bashful": {"increase": "", "decrease": ""},
	"Rash": {"increase": "spa", "decrease": "spd"},
	"Calm": {"increase": "spd", "decrease": "atk"},
	"Gentle": {"increase": "spd", "decrease": "def"},
	"Sassy": {"increase": "spd", "decrease": "spe"},
	"Careful": {"increase": "spd", "decrease": "spa"},
	"Quirky": {"increase": "", "decrease": ""}
}

## Valid status conditions
const VALID_STATUSES: Array[String] = [
	"none",
	"burn",
	"poison",
	"badly_poison",
	"paralysis",
	"sleep",
	"freeze"
]


func _init(
	p_species: PokemonData,
	p_level: int,
	p_ivs: Dictionary = {},
	p_evs: Dictionary = {},
	p_nature: String = "Hardy",
	p_moves: Array = [],
	p_ability: String = "",
	p_item: String = "",
	p_nickname: String = ""
) -> void:
	"""
	Initialize a battle Pokemon with validation.

	Args:
		p_species: Reference to PokemonData resource
		p_level: Pokemon level (1-100)
		p_ivs: Individual Values dictionary (hp, atk, def, spa, spd, spe)
		p_evs: Effort Values dictionary (hp, atk, def, spa, spd, spe)
		p_nature: Nature name (must be valid)
		p_moves: Array of MoveData (1-4 moves)
		p_ability: Ability name (must be valid for species)
		p_item: Held item name (optional)
		p_nickname: Custom nickname (optional)
	"""
	# Validate species
	assert(p_species != null, "BattlePokemon: species cannot be null")
	species = p_species

	# Validate and set level
	assert(p_level >= 1 and p_level <= 100, "BattlePokemon: level must be between 1 and 100")
	level = p_level

	# Validate and set IVs
	if not p_ivs.is_empty():
		_validate_ivs(p_ivs)
		ivs = p_ivs

	# Validate and set EVs
	if not p_evs.is_empty():
		_validate_evs(p_evs)
		evs = p_evs

	# Validate and set nature
	assert(p_nature in NATURES, "BattlePokemon: invalid nature '%s'" % p_nature)
	nature = p_nature

	# Validate and set moves
	assert(p_moves.size() >= 1 and p_moves.size() <= 4, "BattlePokemon: must have 1-4 moves")
	for move in p_moves:
		assert(move is MoveData, "BattlePokemon: all moves must be MoveData instances")
		moves.append(move)
		move_pp.append(move.pp)

	# Validate and set ability
	if p_ability.is_empty():
		# Default to first ability
		assert(species.abilities.size() > 0, "BattlePokemon: species has no abilities")
		ability = species.abilities[0]
	else:
		var all_abilities = species.get_all_abilities()
		assert(p_ability in all_abilities, "BattlePokemon: ability '%s' not valid for %s" % [p_ability, species.name])
		ability = p_ability

	# Set optional properties
	item = p_item
	nickname = p_nickname

	# Calculate stats
	calculate_stats()

	# Initialize HP to max
	current_hp = max_hp


func _validate_ivs(p_ivs: Dictionary) -> void:
	"""Validate IV dictionary has correct keys and values."""
	var required_keys = ["hp", "atk", "def", "spa", "spd", "spe"]
	for key in required_keys:
		assert(key in p_ivs, "BattlePokemon: IVs missing key '%s'" % key)
		var value = p_ivs[key]
		assert(value >= 0 and value <= 31, "BattlePokemon: IV '%s' must be 0-31, got %d" % [key, value])


func _validate_evs(p_evs: Dictionary) -> void:
	"""Validate EV dictionary has correct keys and values."""
	var required_keys = ["hp", "atk", "def", "spa", "spd", "spe"]
	var total = 0

	for key in required_keys:
		assert(key in p_evs, "BattlePokemon: EVs missing key '%s'" % key)
		var value = p_evs[key]
		assert(value >= 0 and value <= 252, "BattlePokemon: EV '%s' must be 0-252, got %d" % [key, value])
		total += value

	assert(total <= 510, "BattlePokemon: total EVs cannot exceed 510, got %d" % total)


func calculate_stats() -> void:
	"""
	Calculate all stats from base stats, IVs, EVs, nature, and level.
	Uses Generation 3+ stat calculation formulas.

	HP Formula: floor(((2 * Base + IV + floor(EV / 4)) * Level) / 100) + Level + 10
	Other Stats: (floor(((2 * Base + IV + floor(EV / 4)) * Level) / 100) + 5) * Nature
	"""
	# Calculate HP (special formula)
	var hp_stat = _calculate_hp_stat()
	max_hp = hp_stat
	stats["hp"] = hp_stat

	# Calculate other stats
	stats["atk"] = _calculate_stat("atk", species.base_atk)
	stats["def"] = _calculate_stat("def", species.base_def)
	stats["spa"] = _calculate_stat("spa", species.base_spa)
	stats["spd"] = _calculate_stat("spd", species.base_spd)
	stats["spe"] = _calculate_stat("spe", species.base_spe)


func _calculate_hp_stat() -> int:
	"""Calculate HP stat using Gen 3+ formula."""
	var base = species.base_hp
	var iv = ivs["hp"]
	var ev = evs["hp"]

	# Special case for Shedinja (always 1 HP)
	if species.name.to_lower() == "shedinja":
		return 1

	return int(floor((2.0 * base + iv + floor(ev / 4.0)) * level / 100.0)) + level + 10


func _calculate_stat(stat_name: String, base_stat: int) -> int:
	"""Calculate a non-HP stat using Gen 3+ formula with nature modifier."""
	var iv = ivs[stat_name]
	var ev = evs[stat_name]

	# Base calculation
	var stat_value = int(floor((2.0 * base_stat + iv + floor(ev / 4.0)) * level / 100.0)) + 5

	# Apply nature modifier
	var nature_data = NATURES[nature]
	if nature_data["increase"] == stat_name:
		stat_value = int(floor(stat_value * 1.1))
	elif nature_data["decrease"] == stat_name:
		stat_value = int(floor(stat_value * 0.9))

	return stat_value


func apply_damage(amount: int) -> void:
	"""
	Apply damage to the Pokemon, capping at 0 HP.

	Args:
		amount: Damage amount (positive integer)
	"""
	assert(amount >= 0, "BattlePokemon: damage amount cannot be negative")
	current_hp = max(0, current_hp - amount)


func heal(amount: int) -> void:
	"""
	Heal the Pokemon, capping at max HP.

	Args:
		amount: Heal amount (positive integer)
	"""
	assert(amount >= 0, "BattlePokemon: heal amount cannot be negative")
	current_hp = min(max_hp, current_hp + amount)


func apply_status(new_status: String) -> bool:
	"""
	Apply a status condition to the Pokemon.

	Args:
		new_status: Status condition to apply

	Returns:
		true if status was applied, false if Pokemon already has a status
	"""
	assert(new_status in VALID_STATUSES, "BattlePokemon: invalid status '%s'" % new_status)

	# Cannot apply status if already has one (except none)
	if status != "none":
		return false

	status = new_status
	status_counter = 0

	# Initialize status counter for sleep (1-3 turns)
	if new_status == "sleep":
		status_counter = randi_range(1, 3)

	return true


func clear_status() -> void:
	"""Clear the current status condition."""
	status = "none"
	status_counter = 0


func can_move() -> bool:
	"""
	Check if the Pokemon can execute a move this turn.

	Returns:
		true if Pokemon can move, false if prevented by status
	"""
	if is_fainted():
		return false

	match status:
		"freeze":
			# 20% chance to thaw each turn
			if randf() < 0.2:
				clear_status()
				return true
			return false

		"sleep":
			if status_counter > 0:
				status_counter -= 1
				if status_counter == 0:
					clear_status()
					return true
				return false
			return true

		"paralysis":
			# 25% chance to be fully paralyzed
			return randf() >= 0.25

		_:
			return true


func is_fainted() -> bool:
	"""
	Check if the Pokemon has fainted.

	Returns:
		true if current HP is 0, false otherwise
	"""
	return current_hp <= 0


func get_display_name() -> String:
	"""
	Get the display name (nickname if set, otherwise species name).

	Returns:
		Display name string
	"""
	if not nickname.is_empty():
		return nickname
	return species.name


func get_stat_with_stage(stat_name: String) -> int:
	"""
	Get a stat value with battle stage modifier applied.

	Args:
		stat_name: Stat name (atk, def, spa, spd, spe, accuracy, evasion)

	Returns:
		Modified stat value
	"""
	assert(stat_name in stat_stages, "BattlePokemon: invalid stat name '%s'" % stat_name)

	# Accuracy and evasion don't use regular stats
	if stat_name in ["accuracy", "evasion"]:
		return stat_stages[stat_name]

	var base_stat = stats[stat_name]
	var stage = stat_stages[stat_name]

	# Stat stage multipliers
	var multiplier = 1.0
	if stage >= 0:
		multiplier = (2.0 + stage) / 2.0
	else:
		multiplier = 2.0 / (2.0 - stage)

	return int(floor(base_stat * multiplier))


func modify_stat_stage(stat_name: String, change: int) -> int:
	"""
	Modify a stat stage, capping at -6 to +6.

	Args:
		stat_name: Stat name to modify
		change: Amount to change (positive or negative)

	Returns:
		Actual change applied after capping
	"""
	assert(stat_name in stat_stages, "BattlePokemon: invalid stat name '%s'" % stat_name)

	var old_stage = stat_stages[stat_name]
	stat_stages[stat_name] = clamp(old_stage + change, -6, 6)
	return stat_stages[stat_name] - old_stage


func reset_stat_stages() -> void:
	"""Reset all stat stages to 0."""
	for stat_name in stat_stages:
		stat_stages[stat_name] = 0


func get_hp_percentage() -> float:
	"""
	Get current HP as a percentage of max HP.

	Returns:
		HP percentage (0.0 to 1.0)
	"""
	if max_hp == 0:
		return 0.0
	return float(current_hp) / float(max_hp)


func can_use_move(move_index: int) -> bool:
	"""
	Check if a move can be used (has PP remaining).

	Args:
		move_index: Index of move in moves array (0-3)

	Returns:
		true if move has PP remaining, false otherwise
	"""
	assert(move_index >= 0 and move_index < moves.size(), "BattlePokemon: invalid move index %d" % move_index)
	return move_pp[move_index] > 0


func use_move(move_index: int) -> bool:
	"""
	Use a move, consuming 1 PP.

	Args:
		move_index: Index of move in moves array (0-3)

	Returns:
		true if move was used successfully, false if no PP remaining
	"""
	if not can_use_move(move_index):
		return false

	move_pp[move_index] -= 1
	return true


func restore_pp(move_index: int, amount: int) -> void:
	"""
	Restore PP for a move.

	Args:
		move_index: Index of move in moves array (0-3)
		amount: Amount of PP to restore
	"""
	assert(move_index >= 0 and move_index < moves.size(), "BattlePokemon: invalid move index %d" % move_index)
	var max_pp = moves[move_index].pp
	move_pp[move_index] = min(max_pp, move_pp[move_index] + amount)


func restore_all_pp() -> void:
	"""Restore all moves to full PP."""
	for i in range(moves.size()):
		move_pp[i] = moves[i].pp
