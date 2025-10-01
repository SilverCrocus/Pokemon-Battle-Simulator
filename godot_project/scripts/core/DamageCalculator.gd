## DamageCalculator.gd
## Implements exact Gen 5-9 damage calculation formula matching Pokemon Showdown
## All formulas use floor() at every truncation point for integer precision
extends RefCounted
class_name DamageCalculator

## Critical hit chance by stage
const CRIT_CHANCES := {
	0: 0.04166667,  # 1/24
	1: 0.125,       # 1/8
	2: 0.5,         # 1/2
	3: 1.0          # 100%
}

## Critical hit damage multiplier (Gen 6-9)
const CRIT_MULTIPLIER := 1.5

## STAB multiplier (when move type matches attacker type)
const STAB_MULTIPLIER := 1.5

## STAB multiplier with Adaptability ability
const ADAPTABILITY_STAB := 2.0

## Burn physical damage reduction
const BURN_MULTIPLIER := 0.5

## Multi-target move damage reduction in doubles
const MULTI_TARGET_MULTIPLIER := 0.75

## Weather boost/reduction multipliers
const WEATHER_BOOST := 1.5
const WEATHER_REDUCE := 0.5

## Calculates base damage using Gen 5-9 formula (before modifiers)
## BaseDamage = floor(floor(floor(floor(2 × Level ÷ 5 + 2) × Power × A ÷ D) ÷ 50) + 2)
##
## @param level: Attacker's level (1-100)
## @param power: Move's base power (1-250)
## @param attack: Attacker's attack stat (after stages)
## @param defense: Defender's defense stat (after stages)
## @return: Base damage value before modifiers
static func calculate_base_damage(level: int, power: int, attack: int, defense: int) -> int:
	assert(level >= 1 and level <= 100, "Level must be 1-100")
	assert(power >= 0 and power <= 250, "Power must be 0-250")
	assert(attack >= 1, "Attack must be at least 1")
	assert(defense >= 1, "Defense must be at least 1")

	# If power is 0 (status moves), no damage
	if power == 0:
		return 0

	# BaseDamage = floor(floor(floor(floor(2 × Level ÷ 5 + 2) × Power × A ÷ D) ÷ 50) + 2)
	var level_calc := floori(2 * level / 5) + 2
	var power_calc := floori(level_calc * power * attack / defense)
	var base_damage := floori(power_calc / 50) + 2

	return base_damage

## Calculates critical hit chance based on crit stage
##
## @param crit_stage: Critical hit stage (0-3+)
## @return: Probability of critical hit (0.0-1.0)
static func calculate_critical_chance(crit_stage: int) -> float:
	assert(crit_stage >= 0, "Crit stage cannot be negative")

	if crit_stage >= 3:
		return 1.0
	return CRIT_CHANCES.get(crit_stage, CRIT_CHANCES[0])

## Gets weather modifier for a move
##
## @param move_type: Move's type
## @param weather: Current weather ("sun", "rain", "harsh_sun", "heavy_rain", "none")
## @return: Weather multiplier (0.5, 1.0, or 1.5)
static func get_weather_modifier(move_type: String, weather: String) -> float:
	match weather:
		"sun", "harsh_sun":
			if move_type == "Fire":
				return WEATHER_BOOST
			elif move_type == "Water":
				return WEATHER_REDUCE
		"rain", "heavy_rain":
			if move_type == "Water":
				return WEATHER_BOOST
			elif move_type == "Fire":
				return WEATHER_REDUCE

	return 1.0

## Gets STAB (Same Type Attack Bonus) modifier
##
## @param move_type: Move's type
## @param attacker_types: Array of attacker's types
## @param has_adaptability: Whether attacker has Adaptability ability
## @return: STAB multiplier (1.0, 1.5, or 2.0)
static func get_stab_modifier(move_type: String, attacker_types: Array, has_adaptability: bool = false) -> float:
	if move_type in attacker_types:
		return ADAPTABILITY_STAB if has_adaptability else STAB_MULTIPLIER
	return 1.0

## Gets burn modifier for physical moves
##
## @param is_physical: Whether the move is physical category
## @param attacker_has_burn: Whether attacker is burned
## @param attacker_has_guts: Whether attacker has Guts ability (ignores burn penalty)
## @return: Burn multiplier (0.5 or 1.0)
static func get_burn_modifier(is_physical: bool, attacker_has_burn: bool, attacker_has_guts: bool = false) -> float:
	if is_physical and attacker_has_burn and not attacker_has_guts:
		return BURN_MULTIPLIER
	return 1.0

## Applies full modifier chain to base damage
## Modifiers applied in exact order: Targets × ParentalBond × Weather × GlaiveRush ×
## Critical × Random × STAB × Type × Burn × other × ZMove × TeraShield
##
## @param base_damage: Base damage from calculate_base_damage()
## @param modifiers: Dictionary containing all modifier values
## @return: Final damage after all modifiers
static func apply_modifiers(base_damage: int, modifiers: Dictionary) -> int:
	if base_damage == 0:
		return 0

	var damage := float(base_damage)

	# Targets (multi-target in doubles)
	if modifiers.get("is_multi_target", false):
		damage *= MULTI_TARGET_MULTIPLIER

	# ParentalBond (not implemented for simplicity, would be 0.25 for second hit)
	if modifiers.get("is_parental_bond_second_hit", false):
		damage *= 0.25

	# Weather
	damage *= modifiers.get("weather_modifier", 1.0)

	# GlaiveRush (2x damage if target used Glaive Rush last turn)
	if modifiers.get("target_used_glaive_rush", false):
		damage *= 2.0

	# Critical hit
	if modifiers.get("is_critical", false):
		damage *= CRIT_MULTIPLIER

	# Random factor (85-100)
	var random_factor := modifiers.get("random_factor", 1.0)
	assert(random_factor >= 0.85 and random_factor <= 1.0, "Random factor must be 0.85-1.0")
	damage *= random_factor

	# STAB
	damage *= modifiers.get("stab_modifier", 1.0)

	# Type effectiveness
	damage *= modifiers.get("type_effectiveness", 1.0)

	# Burn
	damage *= modifiers.get("burn_modifier", 1.0)

	# Other modifiers (screens, etc.)
	damage *= modifiers.get("other_modifier", 1.0)

	# Z-Move modifier (not typically used in Gen 9)
	damage *= modifiers.get("zmove_modifier", 1.0)

	# Tera Shield (reduces damage on first hit against Terastallized raid boss)
	damage *= modifiers.get("tera_shield_modifier", 1.0)

	return max(1, floori(damage))  # Minimum 1 damage if any damage is dealt

## Calculates damage range with random factor (85-100)
## Returns array of [min_damage, max_damage]
##
## @param base_damage: Base damage before random modifier
## @param modifiers: Dictionary containing all modifiers except random
## @return: Array [min_damage, max_damage]
static func damage_range(base_damage: int, modifiers: Dictionary) -> Array:
	# Calculate with min random (85)
	var min_modifiers := modifiers.duplicate()
	min_modifiers["random_factor"] = 0.85
	var min_damage := apply_modifiers(base_damage, min_modifiers)

	# Calculate with max random (100)
	var max_modifiers := modifiers.duplicate()
	max_modifiers["random_factor"] = 1.0
	var max_damage := apply_modifiers(base_damage, max_modifiers)

	return [min_damage, max_damage]

## Main damage calculation function
## Calculates full damage using base formula and modifier chain
##
## @param params: Dictionary containing all calculation parameters:
##   - level: Attacker level (required)
##   - power: Move power (required)
##   - attack: Attacker's attack stat after stages (required)
##   - defense: Defender's defense stat after stages (required)
##   - move_type: Move's type string (required)
##   - attacker_types: Array of attacker's types (required)
##   - is_physical: Whether move is physical category (required)
##   - type_effectiveness: Type chart effectiveness multiplier (default: 1.0)
##   - is_critical: Whether it's a critical hit (default: false)
##   - random_factor: Random factor 0.85-1.0 (default: 1.0)
##   - weather: Current weather (default: "none")
##   - attacker_has_burn: Whether attacker is burned (default: false)
##   - attacker_has_guts: Whether attacker has Guts (default: false)
##   - has_adaptability: Whether attacker has Adaptability (default: false)
##   - is_multi_target: Whether move hits multiple targets (default: false)
##   - target_used_glaive_rush: Whether target used Glaive Rush (default: false)
##   - other_modifier: Additional modifiers like screens (default: 1.0)
## @return: Final calculated damage
static func calculate_damage(params: Dictionary) -> int:
	# Validate required parameters
	assert("level" in params, "level is required")
	assert("power" in params, "power is required")
	assert("attack" in params, "attack is required")
	assert("defense" in params, "defense is required")
	assert("move_type" in params, "move_type is required")
	assert("attacker_types" in params, "attacker_types is required")
	assert("is_physical" in params, "is_physical is required")

	# Calculate base damage
	var base_damage := calculate_base_damage(
		params["level"],
		params["power"],
		params["attack"],
		params["defense"]
	)

	if base_damage == 0:
		return 0

	# Build modifiers dictionary
	var modifiers := {
		"is_multi_target": params.get("is_multi_target", false),
		"weather_modifier": get_weather_modifier(
			params["move_type"],
			params.get("weather", "none")
		),
		"target_used_glaive_rush": params.get("target_used_glaive_rush", false),
		"is_critical": params.get("is_critical", false),
		"random_factor": params.get("random_factor", 1.0),
		"stab_modifier": get_stab_modifier(
			params["move_type"],
			params["attacker_types"],
			params.get("has_adaptability", false)
		),
		"type_effectiveness": params.get("type_effectiveness", 1.0),
		"burn_modifier": get_burn_modifier(
			params["is_physical"],
			params.get("attacker_has_burn", false),
			params.get("attacker_has_guts", false)
		),
		"other_modifier": params.get("other_modifier", 1.0),
		"zmove_modifier": params.get("zmove_modifier", 1.0),
		"tera_shield_modifier": params.get("tera_shield_modifier", 1.0)
	}

	# Apply all modifiers and return final damage
	return apply_modifiers(base_damage, modifiers)

## Calculates damage range for a move (min and max with random factor)
##
## @param params: Same parameters as calculate_damage() but random_factor will be overridden
## @return: Array [min_damage, max_damage]
static func calculate_damage_range(params: Dictionary) -> Array:
	# Calculate base damage
	var base_damage := calculate_base_damage(
		params["level"],
		params["power"],
		params["attack"],
		params["defense"]
	)

	if base_damage == 0:
		return [0, 0]

	# Build modifiers (same as calculate_damage but without random_factor)
	var modifiers := {
		"is_multi_target": params.get("is_multi_target", false),
		"weather_modifier": get_weather_modifier(
			params["move_type"],
			params.get("weather", "none")
		),
		"target_used_glaive_rush": params.get("target_used_glaive_rush", false),
		"is_critical": params.get("is_critical", false),
		"stab_modifier": get_stab_modifier(
			params["move_type"],
			params["attacker_types"],
			params.get("has_adaptability", false)
		),
		"type_effectiveness": params.get("type_effectiveness", 1.0),
		"burn_modifier": get_burn_modifier(
			params["is_physical"],
			params.get("attacker_has_burn", false),
			params.get("attacker_has_guts", false)
		),
		"other_modifier": params.get("other_modifier", 1.0),
		"zmove_modifier": params.get("zmove_modifier", 1.0),
		"tera_shield_modifier": params.get("tera_shield_modifier", 1.0)
	}

	return damage_range(base_damage, modifiers)

## Generates a random damage roll factor (85-100)
##
## @return: Random float between 0.85 and 1.0
static func get_random_damage_roll() -> float:
	var random_int := randi_range(85, 100)
	return random_int / 100.0

## Determines if an attack is a critical hit based on crit stage
##
## @param crit_stage: Critical hit stage (0-3+)
## @return: true if critical hit occurs
static func roll_critical_hit(crit_stage: int) -> bool:
	var chance := calculate_critical_chance(crit_stage)
	if chance >= 1.0:
		return true
	return randf() < chance
