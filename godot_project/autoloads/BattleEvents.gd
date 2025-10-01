extends Node

## Battle Events Singleton
##
## Central event bus for all battle-related events. Provides complete decoupling
## between the battle engine (RefCounted) and UI/audio systems (Nodes). All battle
## components emit events through this singleton rather than using instance signals.
##
## This pattern enables:
## - Zero coupling between battle logic and presentation
## - Easy addition of new observers (UI, sound, replay recording)
## - Memory safety with RefCounted classes (no signal connection leaks)
## - Testable battle engine (can run headless without observers)
##
## Example usage:
## [codeblock]
## # Subscribe to events (typically in UI code)
## func _ready():
##     BattleEvents.move_used.connect(_on_move_used)
##     BattleEvents.damage_dealt.connect(_on_damage_dealt)
##
## func _on_move_used(user: BattlePokemon, move: MoveData, target: BattlePokemon):
##     print("%s used %s!" % [user.get_display_name(), move.name])
##
## # Emit events (in battle engine)
## BattleEvents.move_used.emit(attacker, move, defender)
## [/codeblock]

# ==================== Battle Flow Events ====================

## Emitted when a battle begins
## @param state: Current BattleState
signal battle_started(state)

## Emitted at the start of each turn
## @param turn_number: Current turn number (1-indexed)
signal turn_started(turn_number)

## Emitted at the end of each turn
## @param turn_number: Completed turn number
signal turn_ended(turn_number)

## Emitted when the battle ends
## @param winner: Winning player (1, 2, or 0 for draw)
signal battle_ended(winner)

# ==================== Action Events ====================

## Emitted when a Pokemon uses a move
## @param user: BattlePokemon using the move
## @param move: MoveData being used
## @param target: BattlePokemon being targeted
signal move_used(user, move, target)

## Emitted when a Pokemon is prevented from moving
## @param pokemon: BattlePokemon that cannot move
## @param reason: Reason string (e.g., "sleep", "paralysis", "flinch")
signal move_prevented(pokemon, reason)

## Emitted when a move misses its target
## @param user: BattlePokemon whose move missed
## @param target: BattlePokemon that dodged
signal move_missed(user, target)

## Emitted when a Pokemon switches out
## @param player: Player number (1 or 2)
## @param old_pokemon: BattlePokemon being switched out
## @param new_pokemon: BattlePokemon being switched in
signal pokemon_switched(player, old_pokemon, new_pokemon)

## Emitted when a player forfeits the battle
## @param player: Player number who forfeited (1 or 2)
signal player_forfeited(player)

# ==================== Damage/Healing Events ====================

## Emitted when damage is dealt to a Pokemon
## @param pokemon: BattlePokemon taking damage
## @param amount: Damage amount (integer)
## @param new_hp: Pokemon's current HP after damage
signal damage_dealt(pokemon, amount, new_hp)

## Emitted when a Pokemon is healed
## @param pokemon: BattlePokemon being healed
## @param amount: Heal amount (integer)
## @param new_hp: Pokemon's current HP after healing
signal pokemon_healed(pokemon, amount, new_hp)

## Emitted when a Pokemon faints (HP reaches 0)
## @param pokemon: BattlePokemon that fainted
signal pokemon_fainted(pokemon)

# ==================== Status & Stat Events ====================

## Emitted when a status condition is applied
## @param pokemon: BattlePokemon receiving status
## @param status: Status string ("burn", "poison", "paralysis", "sleep", "freeze")
signal status_applied(pokemon, status)

## Emitted when a status condition is cleared
## @param pokemon: BattlePokemon having status removed
## @param old_status: Previous status string
signal status_cleared(pokemon, old_status)

## Emitted when a Pokemon takes damage from a status condition
## @param pokemon: BattlePokemon taking status damage
## @param status: Status causing damage ("poison", "burn", "badly_poison")
## @param damage: Damage amount
signal status_damage(pokemon, status, damage)

## Emitted when a stat stage changes
## @param pokemon: BattlePokemon having stat modified
## @param stat: Stat name ("atk", "def", "spa", "spd", "spe", "accuracy", "evasion")
## @param change: Stage change amount (e.g., +2, -1)
## @param new_stage: New stat stage value (-6 to +6)
signal stat_stage_changed(pokemon, stat, change, new_stage)

# ==================== Field Effect Events ====================

## Emitted when weather changes
## @param new_weather: Weather type ("sun", "rain", "sandstorm", "hail", "snow", "none")
## @param duration: Duration in turns (-1 for infinite)
signal weather_changed(new_weather, duration)

## Emitted when a Pokemon takes weather damage
## @param pokemon: BattlePokemon taking weather damage
## @param weather: Weather type causing damage
## @param damage: Damage amount
signal weather_damage(pokemon, weather, damage)

## Emitted when terrain changes
## @param new_terrain: Terrain type ("electric", "grassy", "misty", "psychic", "none")
## @param duration: Duration in turns (-1 for infinite)
signal terrain_changed(new_terrain, duration)

# ==================== Move Effect Events ====================

## Emitted when a critical hit occurs
## @param user: BattlePokemon landing the critical hit
## @param target: BattlePokemon receiving the critical hit
signal move_critical_hit(user, target)

## Emitted when a move is super effective
## @param effectiveness: Type effectiveness multiplier (2.0 or 4.0)
signal move_super_effective(effectiveness)

## Emitted when a move is not very effective
## @param effectiveness: Type effectiveness multiplier (0.5 or 0.25)
signal move_not_very_effective(effectiveness)

## Emitted when a move has no effect (0x effectiveness)
## @param user: BattlePokemon whose move had no effect
## @param target: BattlePokemon immune to the move
signal move_no_effect(user, target)

# ==================== Initialization ====================

func _ready() -> void:
	"""Initialize the event bus."""
	print("[BattleEvents] Event bus initialized and ready")
