extends RefCounted

## Stat Calculator Utility
##
## Provides stat calculation formulas and nature modifier lookups.
## Used by Team Builder for displaying calculated stats and nature effects.

# ==================== Nature Data ====================

const NATURES := {
	# Neutral natures (no stat changes)
	"Hardy": {"increase": "", "decrease": ""},
	"Docile": {"increase": "", "decrease": ""},
	"Serious": {"increase": "", "decrease": ""},
	"Bashful": {"increase": "", "decrease": ""},
	"Quirky": {"increase": "", "decrease": ""},

	# Beneficial natures (+10% to one stat, -10% to another)
	"Lonely": {"increase": "atk", "decrease": "def"},
	"Brave": {"increase": "atk", "decrease": "spe"},
	"Adamant": {"increase": "atk", "decrease": "spa"},
	"Naughty": {"increase": "atk", "decrease": "spd"},

	"Bold": {"increase": "def", "decrease": "atk"},
	"Relaxed": {"increase": "def", "decrease": "spe"},
	"Impish": {"increase": "def", "decrease": "spa"},
	"Lax": {"increase": "def", "decrease": "spd"},

	"Timid": {"increase": "spe", "decrease": "atk"},
	"Hasty": {"increase": "spe", "decrease": "def"},
	"Jolly": {"increase": "spe", "decrease": "spa"},
	"Naive": {"increase": "spe", "decrease": "spd"},

	"Modest": {"increase": "spa", "decrease": "atk"},
	"Mild": {"increase": "spa", "decrease": "def"},
	"Quiet": {"increase": "spa", "decrease": "spe"},
	"Rash": {"increase": "spa", "decrease": "spd"},

	"Calm": {"increase": "spd", "decrease": "atk"},
	"Gentle": {"increase": "spd", "decrease": "def"},
	"Sassy": {"increase": "spd", "decrease": "spe"},
	"Careful": {"increase": "spd", "decrease": "spa"}
}

const STAT_NAMES := {
	"hp": "HP",
	"atk": "Attack",
	"def": "Defense",
	"spa": "Sp. Atk",
	"spd": "Sp. Def",
	"spe": "Speed"
}

# ==================== Stat Calculation ====================

static func calculate_hp(base: int, iv: int, ev: int, level: int) -> int:
	"""
	Calculate HP stat.
	Formula: floor((2 * Base + IV + floor(EV / 4)) * Level / 100) + Level + 10

	@param base: Base HP stat
	@param iv: Individual Value (0-31)
	@param ev: Effort Value (0-252)
	@param level: Pokemon level (1-100)
	@return: Calculated HP stat
	"""
	return floor((2 * base + iv + floor(ev / 4.0)) * level / 100.0) + level + 10


static func calculate_stat(base: int, iv: int, ev: int, level: int, nature_modifier: float = 1.0) -> int:
	"""
	Calculate non-HP stat (Attack, Defense, etc.).
	Formula: floor((floor((2 * Base + IV + floor(EV / 4)) * Level / 100) + 5) * Nature)

	@param base: Base stat value
	@param iv: Individual Value (0-31)
	@param ev: Effort Value (0-252)
	@param level: Pokemon level (1-100)
	@param nature_modifier: Nature multiplier (0.9, 1.0, or 1.1)
	@return: Calculated stat value
	"""
	var base_stat = floor((2 * base + iv + floor(ev / 4.0)) * level / 100.0) + 5
	return floor(base_stat * nature_modifier)


static func calculate_all_stats(species_data, level: int, ivs: Dictionary, evs: Dictionary, nature: String) -> Dictionary:
	"""
	Calculate all stats for a Pokemon.

	@param species_data: Pokemon species data with base stats
	@param level: Pokemon level
	@param ivs: Dictionary with hp, atk, def, spa, spd, spe
	@param evs: Dictionary with hp, atk, def, spa, spd, spe
	@param nature: Nature name
	@return: Dictionary with calculated stats
	"""
	var stats = {}
	var nature_data = NATURES.get(nature, {"increase": "", "decrease": ""})

	# Calculate HP
	stats["hp"] = calculate_hp(
		species_data.base_stats.hp,
		ivs.get("hp", 31),
		evs.get("hp", 0),
		level
	)

	# Calculate other stats
	for stat_key in ["atk", "def", "spa", "spd", "spe"]:
		var base = species_data.base_stats.get(stat_key, 0)
		var iv = ivs.get(stat_key, 31)
		var ev = evs.get(stat_key, 0)
		var modifier = get_nature_modifier(nature, stat_key)

		stats[stat_key] = calculate_stat(base, iv, ev, level, modifier)

	return stats


# ==================== Nature Utilities ====================

static func get_nature_modifier(nature: String, stat: String) -> float:
	"""
	Get nature modifier for a specific stat.

	@param nature: Nature name
	@param stat: Stat key (atk, def, spa, spd, spe)
	@return: Multiplier (0.9, 1.0, or 1.1)
	"""
	if not NATURES.has(nature):
		return 1.0

	var nature_data = NATURES[nature]

	if nature_data.increase == stat:
		return 1.1
	elif nature_data.decrease == stat:
		return 0.9
	else:
		return 1.0


static func get_nature_effect(nature: String) -> String:
	"""
	Get formatted nature effect description.

	@param nature: Nature name
	@return: Human-readable description (e.g., "+Atk -Def")
	"""
	if not NATURES.has(nature):
		return "Unknown nature"

	var nature_data = NATURES[nature]

	if nature_data.increase.is_empty():
		return "Neutral"

	var inc_stat = STAT_NAMES.get(nature_data.increase, nature_data.increase)
	var dec_stat = STAT_NAMES.get(nature_data.decrease, nature_data.decrease)

	return "+%s -%s" % [inc_stat, dec_stat]


static func get_all_natures() -> Array:
	"""
	Get list of all nature names.

	@return: Array of nature names
	"""
	return NATURES.keys()


static func is_beneficial_nature(nature: String) -> bool:
	"""
	Check if nature has stat modifications.

	@param nature: Nature name
	@return: True if nature modifies stats
	"""
	if not NATURES.has(nature):
		return false

	var nature_data = NATURES[nature]
	return not nature_data.increase.is_empty()


# ==================== EV/IV Utilities ====================

static func get_max_evs() -> int:
	"""Get maximum total EVs (508)."""
	return 508


static func get_max_ev_per_stat() -> int:
	"""Get maximum EVs per individual stat (252)."""
	return 252


static func get_max_iv() -> int:
	"""Get maximum IV value (31)."""
	return 31


static func validate_evs(evs: Dictionary) -> Dictionary:
	"""
	Validate EV spread.

	@param evs: Dictionary with stat -> value mapping
	@return: Dictionary with "valid" bool and "error" string
	"""
	var total = 0

	for stat in ["hp", "atk", "def", "spa", "spd", "spe"]:
		var value = evs.get(stat, 0)

		# Check individual stat limit
		if value > get_max_ev_per_stat():
			return {"valid": false, "error": "%s exceeds 252" % STAT_NAMES[stat]}

		total += value

	# Check total limit
	if total > get_max_evs():
		return {"valid": false, "error": "Total EVs exceed 508 (currently %d)" % total}

	return {"valid": true, "error": ""}


static func get_ev_total(evs: Dictionary) -> int:
	"""
	Calculate total EVs used.

	@param evs: Dictionary with stat -> value mapping
	@return: Total EV count
	"""
	var total = 0
	for stat in ["hp", "atk", "def", "spa", "spd", "spe"]:
		total += evs.get(stat, 0)
	return total


# ==================== Stat Comparison ====================

static func get_stat_color(nature: String, stat: String) -> Color:
	"""
	Get color for stat based on nature modifier.

	@param nature: Nature name
	@param stat: Stat key
	@return: Color (red for decrease, green for increase, white for neutral)
	"""
	var modifier = get_nature_modifier(nature, stat)

	if modifier > 1.0:
		return Color(0.4, 0.9, 0.4)  # Green (increased)
	elif modifier < 1.0:
		return Color(0.9, 0.4, 0.4)  # Red (decreased)
	else:
		return Color(1.0, 1.0, 1.0)  # White (neutral)


static func format_stat_with_modifier(value: int, nature: String, stat: String) -> String:
	"""
	Format stat value with nature indicator.

	@param value: Stat value
	@param nature: Nature name
	@param stat: Stat key
	@return: Formatted string (e.g., "252 ↑" or "180 ↓")
	"""
	var modifier = get_nature_modifier(nature, stat)

	if modifier > 1.0:
		return "%d ↑" % value
	elif modifier < 1.0:
		return "%d ↓" % value
	else:
		return "%d" % value


# ==================== Debug Methods ====================

static func get_nature_info() -> String:
	"""Get formatted info about all natures."""
	var info = "=== NATURES ===\n\n"

	info += "Neutral Natures:\n"
	for nature in NATURES:
		if not is_beneficial_nature(nature):
			info += "  %s\n" % nature

	info += "\nBeneficial Natures:\n"
	for nature in NATURES:
		if is_beneficial_nature(nature):
			var effect = get_nature_effect(nature)
			info += "  %s: %s\n" % [nature, effect]

	return info
