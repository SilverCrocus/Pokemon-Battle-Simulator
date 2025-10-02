extends Node

## Move Effect Registry
##
## Central registry that maps moves to their effects.
## This allows moves to have complex, pluggable effects beyond simple damage.
##
## Usage:
##   var effects = MoveEffectRegistry.get_move_effects(move_id)
##   for effect in effects:
##       if effect.should_execute(rng):
##           var result = effect.execute(context)

# Preload all effect classes (stored as vars since no class_name)
var StatusEffect = load("res://scripts/core/effects/StatusEffect.gd")
var StatChangeEffect = load("res://scripts/core/effects/StatChangeEffect.gd")
var MultiStatChangeEffect = load("res://scripts/core/effects/MultiStatChangeEffect.gd")
var RecoilEffect = load("res://scripts/core/effects/RecoilEffect.gd")
var DrainEffect = load("res://scripts/core/effects/DrainEffect.gd")
var FlinchEffect = load("res://scripts/core/effects/FlinchEffect.gd")
var OHKOEffect = load("res://scripts/core/effects/OHKOEffect.gd")
var MultiHitEffect = load("res://scripts/core/effects/MultiHitEffect.gd")
var WeatherEffect = load("res://scripts/core/effects/WeatherEffect.gd")
var TerrainEffect = load("res://scripts/core/effects/TerrainEffect.gd")
var HazardEffect = load("res://scripts/core/effects/HazardEffect.gd")
var HealEffect = load("res://scripts/core/effects/HealEffect.gd")

## Registry of move ID to effects
var move_effects: Dictionary = {}


func _ready() -> void:
	_initialize_move_effects()
	print("[MoveEffectRegistry] Initialized with %d moves" % move_effects.size())


func get_move_effects(move_id: int) -> Array:
	"""
	Get array of effects for a move.

	Args:
		move_id: Pokemon move ID

	Returns:
		Array of MoveEffect instances (empty if no custom effects)
	"""
	return move_effects.get(move_id, [])


func has_effects(move_id: int) -> bool:
	"""Check if move has custom effects registered."""
	return move_id in move_effects


func _initialize_move_effects() -> void:
	"""Initialize all move effects. This is where we map moves to their effects."""

	# ============================================================================
	# STATUS MOVES - Stat Boosting
	# ============================================================================

	# Swords Dance - Sharply raises Attack (+2)
	move_effects[14] = [
		MultiStatChangeEffect.new({"atk": 2}, 100, true)
	]

	# Growl - Lowers opponent's Attack (-1)
	move_effects[45] = [
		StatChangeEffect.new("atk", -1, 100, false)
	]

	# Dragon Dance - Raises Attack and Speed (+1 each)
	move_effects[349] = [
		MultiStatChangeEffect.new({"atk": 1, "spe": 1}, 100, true)
	]

	# Nasty Plot - Sharply raises Sp. Atk (+2)
	move_effects[417] = [
		MultiStatChangeEffect.new({"spa": 2}, 100, true)
	]

	# Bulk Up - Raises Attack and Defense (+1 each)
	move_effects[339] = [
		MultiStatChangeEffect.new({"atk": 1, "def": 1}, 100, true)
	]

	# Calm Mind - Raises Sp. Atk and Sp. Def (+1 each)
	move_effects[347] = [
		MultiStatChangeEffect.new({"spa": 1, "spd": 1}, 100, true)
	]

	# Agility - Sharply raises Speed (+2)
	move_effects[97] = [
		MultiStatChangeEffect.new({"spe": 2}, 100, true)
	]

	# ============================================================================
	# STATUS MOVES - Status Infliction
	# ============================================================================

	# Thunder Wave - Paralyzes target (90% accuracy, but 100% if hits)
	move_effects[86] = [
		StatusEffect.new("paralysis", 100)
	]

	# Toxic - Badly poisons target (90% accuracy, but 100% if hits)
	move_effects[92] = [
		StatusEffect.new("badly_poison", 100)
	]

	# Will-O-Wisp - Burns target (85% accuracy, but 100% if hits)
	move_effects[261] = [
		StatusEffect.new("burn", 100)
	]

	# Spore - Puts target to sleep (100% accuracy)
	move_effects[147] = [
		StatusEffect.new("sleep", 100)
	]

	# ============================================================================
	# DAMAGING MOVES - With Secondary Effects
	# ============================================================================

	# Flamethrower - 10% chance to burn
	move_effects[53] = [
		StatusEffect.new("burn", 10)
	]

	# Thunderbolt - 10% chance to paralyze
	move_effects[85] = [
		StatusEffect.new("paralysis", 10)
	]

	# Ice Beam - 10% chance to freeze
	move_effects[58] = [
		StatusEffect.new("freeze", 10)
	]

	# Fire Blast - 10% chance to burn
	move_effects[126] = [
		StatusEffect.new("burn", 10)
	]

	# Thunder - 30% chance to paralyze
	move_effects[87] = [
		StatusEffect.new("paralysis", 30)
	]

	# Blizzard - 10% chance to freeze
	move_effects[59] = [
		StatusEffect.new("freeze", 10)
	]

	# Iron Head - 30% chance to flinch
	move_effects[442] = [
		FlinchEffect.new(30)
	]

	# Air Slash - 30% chance to flinch
	move_effects[403] = [
		FlinchEffect.new(30)
	]

	# Fake Out - Always flinches (priority +3)
	move_effects[252] = [
		FlinchEffect.new(100)
	]

	# ============================================================================
	# RECOIL MOVES
	# ============================================================================

	# Brave Bird - 33% recoil
	move_effects[413] = [
		RecoilEffect.new(33)
	]

	# Flare Blitz - 33% recoil, 10% burn
	move_effects[394] = [
		RecoilEffect.new(33),
		StatusEffect.new("burn", 10)
	]

	# Double-Edge - 33% recoil
	move_effects[38] = [
		RecoilEffect.new(33)
	]

	# Take Down - 25% recoil
	move_effects[36] = [
		RecoilEffect.new(25)
	]

	# ============================================================================
	# DRAIN MOVES
	# ============================================================================

	# Giga Drain - 50% drain
	move_effects[202] = [
		DrainEffect.new(50)
	]

	# Drain Punch - 50% drain
	move_effects[409] = [
		DrainEffect.new(50)
	]

	# Leech Life - 50% drain (updated in Gen 7+)
	move_effects[141] = [
		DrainEffect.new(50)
	]

	# Draining Kiss - 75% drain
	move_effects[577] = [
		DrainEffect.new(75)
	]

	# ============================================================================
	# MULTI-HIT MOVES
	# ============================================================================

	# Bullet Seed - 2-5 hits
	move_effects[331] = [
		MultiHitEffect.new(2, 5)
	]

	# Icicle Spear - 2-5 hits
	move_effects[333] = [
		MultiHitEffect.new(2, 5)
	]

	# Rock Blast - 2-5 hits
	move_effects[350] = [
		MultiHitEffect.new(2, 5)
	]

	# Pin Missile - 2-5 hits
	move_effects[42] = [
		MultiHitEffect.new(2, 5)
	]

	# Double Kick - Always 2 hits
	move_effects[24] = [
		MultiHitEffect.new(2, 2)
	]

	# ============================================================================
	# OHKO MOVES
	# ============================================================================

	# Guillotine
	move_effects[12] = [
		OHKOEffect.new()
	]

	# Horn Drill
	move_effects[32] = [
		OHKOEffect.new()
	]

	# Fissure
	move_effects[90] = [
		OHKOEffect.new()
	]

	# Sheer Cold
	move_effects[329] = [
		OHKOEffect.new()
	]

	# ============================================================================
	# WEATHER MOVES
	# ============================================================================

	# Sunny Day - Sets sun for 5 turns
	move_effects[241] = [
		WeatherEffect.new("sun", 5)
	]

	# Rain Dance - Sets rain for 5 turns
	move_effects[240] = [
		WeatherEffect.new("rain", 5)
	]

	# Sandstorm - Sets sandstorm for 5 turns
	move_effects[201] = [
		WeatherEffect.new("sandstorm", 5)
	]

	# Hail - Sets hail for 5 turns
	move_effects[258] = [
		WeatherEffect.new("hail", 5)
	]

	# ============================================================================
	# TERRAIN MOVES
	# ============================================================================

	# Electric Terrain - Sets electric terrain for 5 turns
	move_effects[604] = [
		TerrainEffect.new("electric", 5)
	]

	# Grassy Terrain - Sets grassy terrain for 5 turns
	move_effects[580] = [
		TerrainEffect.new("grassy", 5)
	]

	# Misty Terrain - Sets misty terrain for 5 turns
	move_effects[581] = [
		TerrainEffect.new("misty", 5)
	]

	# Psychic Terrain - Sets psychic terrain for 5 turns
	move_effects[678] = [
		TerrainEffect.new("psychic", 5)
	]

	# ============================================================================
	# HAZARD MOVES
	# ============================================================================

	# Stealth Rock
	move_effects[446] = [
		HazardEffect.new("stealth_rock")
	]

	# Spikes
	move_effects[191] = [
		HazardEffect.new("spikes")
	]

	# Toxic Spikes
	move_effects[390] = [
		HazardEffect.new("toxic_spikes")
	]

	# Sticky Web
	move_effects[527] = [
		HazardEffect.new("sticky_web")
	]

	# ============================================================================
	# HEALING MOVES
	# ============================================================================

	# Recover - Restores 50% max HP
	move_effects[105] = [
		HealEffect.new(50, false)
	]

	# Softboiled - Restores 50% max HP
	move_effects[135] = [
		HealEffect.new(50, false)
	]

	# Roost - Restores 50% max HP
	move_effects[355] = [
		HealEffect.new(50, false)
	]

	# Synthesis - Weather-based healing
	move_effects[235] = [
		HealEffect.new(50, true)
	]

	# Morning Sun - Weather-based healing
	move_effects[234] = [
		HealEffect.new(50, true)
	]

	# Moonlight - Weather-based healing
	move_effects[236] = [
		HealEffect.new(50, true)
	]

	print("[MoveEffectRegistry] Registered %d moves with custom effects" % move_effects.size())
