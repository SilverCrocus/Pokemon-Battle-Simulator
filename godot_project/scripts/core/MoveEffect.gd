class_name MoveEffect
extends RefCounted

## Base class for move effects
##
## Move effects are pluggable behaviors that can be attached to moves to
## implement special mechanics beyond basic damage. Each move can have multiple
## effects that execute in sequence.
##
## Effect Types:
## - Primary effects: Always execute (e.g., damage)
## - Secondary effects: Execute with a % chance (e.g., 30% burn on Flamethrower)
## - Self-targeting effects: Affect the user (e.g., Swords Dance stat boost)
##
## Examples:
##   - Flamethrower: Damage (primary) + 10% burn (secondary)
##   - Swords Dance: +2 Attack stages (primary, self-targeting)
##   - Thunder Wave: 90% paralyze (primary)
##   - Ice Beam: Damage (primary) + 10% freeze (secondary)

## Effect metadata
var effect_name: String = ""
var effect_chance: int = 100  # Percentage chance (0-100)
var targets_user: bool = false  # If true, affects the move user instead of target


func _init(name: String = "", chance: int = 100, targets_self: bool = false) -> void:
	"""
	Initialize the move effect.

	Args:
		name: Human-readable effect name
		chance: Percentage chance to execute (0-100)
		targets_self: Whether effect targets the user instead of opponent
	"""
	effect_name = name
	effect_chance = chance
	targets_user = targets_self


func should_execute(rng: RandomNumberGenerator) -> bool:
	"""
	Determine if effect should execute based on chance.

	Args:
		rng: Deterministic RNG from BattleState

	Returns:
		True if effect should execute
	"""
	if effect_chance >= 100:
		return true

	var roll = rng.randi_range(1, 100)
	return roll <= effect_chance


func execute(context: Dictionary) -> Dictionary:
	"""
	Execute the move effect.

	Args:
		context: Effect execution context containing:
			- attacker: BattlePokemon using the move
			- defender: BattlePokemon being targeted
			- move: MoveData being used
			- damage_dealt: Damage from primary effect (if any)
			- state: BattleState reference
			- rng: RandomNumberGenerator from state

	Returns:
		Dictionary with effect results:
			- success: bool - Whether effect executed successfully
			- message: String - Description of what happened
			- data: Dictionary - Effect-specific data
	"""
	# Override in subclasses
	return {
		"success": false,
		"message": "Base effect does nothing",
		"data": {}
	}


func get_description() -> String:
	"""
	Get human-readable description of effect.

	Returns:
		Effect description string
	"""
	var desc = effect_name
	if effect_chance < 100:
		desc += " (%d%% chance)" % effect_chance
	if targets_user:
		desc += " [self]"
	return desc


## Factory methods for common effects


static func create_damage_effect() -> MoveEffect:
	"""Create a basic damage effect (primary)."""
	var effect = MoveEffect.new("Damage", 100, false)
	return effect


static func create_status_effect(status: String, chance: int = 100) -> MoveEffect:
	"""
	Create a status-inflicting effect.

	Args:
		status: Status to inflict ("burn", "poison", "paralysis", etc.)
		chance: Percentage chance (0-100)
	"""
	var effect = StatusEffect.new(status, chance)
	return effect


static func create_stat_change_effect(stat: String, stages: int, chance: int = 100, targets_self: bool = false) -> MoveEffect:
	"""
	Create a stat stage change effect.

	Args:
		stat: Stat to change ("atk", "def", "spa", "spd", "spe", "accuracy", "evasion")
		stages: Number of stages to change (-6 to +6)
		chance: Percentage chance (0-100)
		targets_self: If true, affects user instead of target
	"""
	var effect = StatChangeEffect.new(stat, stages, chance, targets_self)
	return effect


static func create_multi_stat_change_effect(stat_changes: Dictionary, chance: int = 100, targets_self: bool = false) -> MoveEffect:
	"""
	Create a multi-stat change effect.

	Args:
		stat_changes: Dictionary of stat:stages (e.g., {"atk": 2, "spe": 1})
		chance: Percentage chance (0-100)
		targets_self: If true, affects user instead of target
	"""
	var effect = MultiStatChangeEffect.new(stat_changes, chance, targets_self)
	return effect


static func create_recoil_effect(recoil_percent: int) -> MoveEffect:
	"""
	Create a recoil damage effect.

	Args:
		recoil_percent: Percentage of damage dealt taken as recoil (e.g., 25 for 1/4)
	"""
	var effect = RecoilEffect.new(recoil_percent)
	return effect


static func create_drain_effect(drain_percent: int) -> MoveEffect:
	"""
	Create a HP drain effect.

	Args:
		drain_percent: Percentage of damage dealt recovered as HP (e.g., 50 for 1/2)
	"""
	var effect = DrainEffect.new(drain_percent)
	return effect


static func create_flinch_effect(chance: int = 100) -> MoveEffect:
	"""
	Create a flinch effect (prevents target from moving this turn).

	Args:
		chance: Percentage chance (0-100)
	"""
	var effect = FlinchEffect.new(chance)
	return effect


static func create_ohko_effect() -> MoveEffect:
	"""Create a one-hit KO effect (like Guillotine, Fissure)."""
	var effect = OHKOEffect.new()
	return effect


static func create_multi_hit_effect(min_hits: int, max_hits: int) -> MoveEffect:
	"""
	Create a multi-hit effect (like Bullet Seed, Icicle Spear).

	Args:
		min_hits: Minimum number of hits
		max_hits: Maximum number of hits
	"""
	var effect = MultiHitEffect.new(min_hits, max_hits)
	return effect
