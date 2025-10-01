## StatCalculator.gd
## Implements exact Gen 3-9 stat calculation formulas matching Pokemon Showdown
## All formulas use floor() at truncation points for integer precision
extends RefCounted
class_name StatCalculator

## Nature multiplier table - maps nature names to [boosted_stat, lowered_stat]
## Stats: 0=HP, 1=ATK, 2=DEF, 3=SPA, 4=SPD, 5=SPE
const NATURES := {
	"Adamant": [1, 3],   # +ATK, -SPA
	"Bashful": [-1, -1], # Neutral
	"Bold": [2, 1],      # +DEF, -ATK
	"Brave": [1, 5],     # +ATK, -SPE
	"Calm": [4, 1],      # +SPD, -ATK
	"Careful": [4, 3],   # +SPD, -SPA
	"Docile": [-1, -1],  # Neutral
	"Gentle": [4, 2],    # +SPD, -DEF
	"Hardy": [-1, -1],   # Neutral
	"Hasty": [5, 2],     # +SPE, -DEF
	"Impish": [2, 3],    # +DEF, -SPA
	"Jolly": [5, 3],     # +SPE, -SPA
	"Lax": [2, 4],       # +DEF, -SPD
	"Lonely": [1, 2],    # +ATK, -DEF
	"Mild": [3, 2],      # +SPA, -DEF
	"Modest": [3, 1],    # +SPA, -ATK
	"Naive": [5, 4],     # +SPE, -SPD
	"Naughty": [1, 4],   # +ATK, -SPD
	"Quiet": [3, 5],     # +SPA, -SPE
	"Quirky": [-1, -1],  # Neutral
	"Rash": [3, 4],      # +SPA, -SPD
	"Relaxed": [2, 5],   # +DEF, -SPE
	"Sassy": [4, 5],     # +SPD, -SPE
	"Serious": [-1, -1], # Neutral
	"Timid": [5, 1]      # +SPE, -ATK
}

## Stat stage multipliers for battle boosts/drops (-6 to +6)
## Formula: max(2, 2 + stage) / max(2, 2 - stage)
const STAGE_MULTIPLIERS := {
	-6: 0.25,
	-5: 0.28571429,  # 2/7
	-4: 0.33333333,  # 2/6
	-3: 0.4,         # 2/5
	-2: 0.5,         # 2/4
	-1: 0.66666667,  # 2/3
	0: 1.0,
	1: 1.5,          # 3/2
	2: 2.0,          # 4/2
	3: 2.5,          # 5/2
	4: 3.0,          # 6/2
	5: 3.5,          # 7/2
	6: 4.0           # 8/2
}

## Calculates HP stat using Gen 3-9 formula
## HP = floor(((2 × Base + IV + floor(EV ÷ 4)) × Level) ÷ 100) + Level + 10
## Exception: Shedinja always has 1 HP regardless of calculation
##
## @param base_stat: Base HP stat (1-255)
## @param iv: Individual Value (0-31)
## @param ev: Effort Value (0-252)
## @param level: Pokemon level (1-100)
## @param species_name: Pokemon species name for Shedinja check
## @return: Calculated HP stat
static func calculate_hp_stat(base_stat: int, iv: int, ev: int, level: int, species_name: String = "") -> int:
	assert(base_stat >= 1 and base_stat <= 255, "Base HP must be 1-255")
	assert(iv >= 0 and iv <= 31, "IV must be 0-31")
	assert(ev >= 0 and ev <= 252, "EV must be 0-252")
	assert(level >= 1 and level <= 100, "Level must be 1-100")

	# Shedinja special case
	if species_name.to_lower() == "shedinja":
		return 1

	# HP = floor(((2 × Base + IV + floor(EV ÷ 4)) × Level) ÷ 100) + Level + 10
	var ev_contribution := floori(ev / 4)
	var inner_calc := (2 * base_stat + iv + ev_contribution) * level
	var hp := floori(inner_calc / 100) + level + 10

	return hp

## Calculates non-HP stat using Gen 3-9 formula
## Stat = floor((floor(((2 × Base + IV + floor(EV ÷ 4)) × Level) ÷ 100) + 5) × Nature)
##
## @param base_stat: Base stat value (1-255)
## @param iv: Individual Value (0-31)
## @param ev: Effort Value (0-252)
## @param level: Pokemon level (1-100)
## @param nature_multiplier: Nature multiplier (0.9, 1.0, or 1.1)
## @return: Calculated stat value
static func calculate_stat(base_stat: int, iv: int, ev: int, level: int, nature_multiplier: float) -> int:
	assert(base_stat >= 1 and base_stat <= 255, "Base stat must be 1-255")
	assert(iv >= 0 and iv <= 31, "IV must be 0-31")
	assert(ev >= 0 and ev <= 252, "EV must be 0-252")
	assert(level >= 1 and level <= 100, "Level must be 1-100")
	assert(nature_multiplier in [0.9, 1.0, 1.1], "Nature multiplier must be 0.9, 1.0, or 1.1")

	# Stat = floor((floor(((2 × Base + IV + floor(EV ÷ 4)) × Level) ÷ 100) + 5) × Nature)
	var ev_contribution := floori(ev / 4)
	var inner_calc := (2 * base_stat + iv + ev_contribution) * level
	var base_value := floori(inner_calc / 100) + 5
	var final_stat := floori(base_value * nature_multiplier)

	return final_stat

## Gets nature multiplier for a specific stat
##
## @param nature: Nature name (e.g., "Adamant", "Modest")
## @param stat_index: Stat index (1=ATK, 2=DEF, 3=SPA, 4=SPD, 5=SPE)
## @return: Multiplier value (0.9 for lowered, 1.0 for neutral, 1.1 for boosted)
static func get_nature_multiplier(nature: String, stat_index: int) -> float:
	assert(nature in NATURES, "Invalid nature: " + nature)
	assert(stat_index >= 1 and stat_index <= 5, "Stat index must be 1-5 (ATK, DEF, SPA, SPD, SPE)")

	var nature_data := NATURES[nature]
	var boosted_stat := nature_data[0]
	var lowered_stat := nature_data[1]

	# Neutral nature (no boosts/drops)
	if boosted_stat == -1:
		return 1.0

	# Boosted stat
	if stat_index == boosted_stat:
		return 1.1

	# Lowered stat
	if stat_index == lowered_stat:
		return 0.9

	# Unaffected stat
	return 1.0

## Gets stat stage multiplier for battle boosts/drops
## Formula: max(2, 2 + stage) / max(2, 2 - stage)
##
## @param stage: Stat stage (-6 to +6)
## @return: Multiplier for the stage (0.25x to 4.0x)
static func get_stat_stage_multiplier(stage: int) -> float:
	assert(stage >= -6 and stage <= 6, "Stage must be -6 to +6")
	return STAGE_MULTIPLIERS[stage]

## Calculates all stats at once for a Pokemon
## Returns a dictionary with all stat values
##
## @param base_stats: Dictionary with keys "hp", "atk", "def", "spa", "spd", "spe"
## @param ivs: Dictionary with IV values for each stat
## @param evs: Dictionary with EV values for each stat
## @param level: Pokemon level (1-100)
## @param nature: Nature name
## @param species_name: Pokemon species name (for Shedinja check)
## @return: Dictionary with calculated stat values
static func calculate_all_stats(
	base_stats: Dictionary,
	ivs: Dictionary,
	evs: Dictionary,
	level: int,
	nature: String,
	species_name: String = ""
) -> Dictionary:
	assert("hp" in base_stats and "atk" in base_stats and "def" in base_stats and "spa" in base_stats and "spd" in base_stats and "spe" in base_stats,
		"base_stats must contain all stat keys")
	assert("hp" in ivs and "atk" in ivs and "def" in ivs and "spa" in ivs and "spd" in ivs and "spe" in ivs,
		"ivs must contain all stat keys")
	assert("hp" in evs and "atk" in evs and "def" in evs and "spa" in evs and "spd" in evs and "spe" in evs,
		"evs must contain all stat keys")

	var stats := {}

	# Calculate HP
	stats["hp"] = calculate_hp_stat(base_stats["hp"], ivs["hp"], evs["hp"], level, species_name)

	# Calculate other stats with nature multipliers
	# Stat indices: 1=ATK, 2=DEF, 3=SPA, 4=SPD, 5=SPE
	var stat_keys := ["atk", "def", "spa", "spd", "spe"]
	for i in range(stat_keys.size()):
		var stat_key := stat_keys[i]
		var stat_index := i + 1
		var multiplier := get_nature_multiplier(nature, stat_index)
		stats[stat_key] = calculate_stat(
			base_stats[stat_key],
			ivs[stat_key],
			evs[stat_key],
			level,
			multiplier
		)

	return stats

## Applies stat stage modifier to a base stat value
## Used during battle calculations
##
## @param base_stat: The calculated stat value
## @param stage: Stat stage modifier (-6 to +6)
## @return: Modified stat value
static func apply_stat_stage(base_stat: int, stage: int) -> int:
	var multiplier := get_stat_stage_multiplier(stage)
	return floori(base_stat * multiplier)
