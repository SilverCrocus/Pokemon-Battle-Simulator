extends Node

## Test script for BattleEngine
##
## Verifies battle engine functionality by running a simple battle
## between two Pokemon with known stats and moves. Subscribes to all
## battle events and prints detailed logs to console.

# Preload necessary classes
const BattleEngineScript = preload("res://scripts/core/BattleEngine.gd")
const BattleActionScript = preload("res://scripts/core/BattleAction.gd")
const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")

# ==================== Test Configuration ====================

const TEST_SEED := 12345
const TEST_TURNS := 5

# ==================== Test State ====================

var engine  # Type: BattleEngine (from preload)
var turn_count := 0

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize and run battle engine tests."""
	print("================================================================================")
	print("BATTLE ENGINE TEST - Phase 1 Week 4")
	print("================================================================================")
	print()

	# Subscribe to all battle events
	_connect_event_signals()

	# Run test scenarios
	print("[TEST 1] Basic Battle Flow")
	print("--------------------------------------------------------------------------------")
	_test_basic_battle()

	print()
	print("[TEST 2] Deterministic Replay")
	print("--------------------------------------------------------------------------------")
	_test_deterministic_replay()

	print()
	print("================================================================================")
	print("ALL TESTS COMPLETED")
	print("================================================================================")


# ==================== Event Subscriptions ====================

func _connect_event_signals() -> void:
	"""Subscribe to all BattleEvents signals for logging."""

	# Battle flow events
	BattleEvents.battle_started.connect(_on_battle_started)
	BattleEvents.turn_started.connect(_on_turn_started)
	BattleEvents.turn_ended.connect(_on_turn_ended)
	BattleEvents.battle_ended.connect(_on_battle_ended)

	# Action events
	BattleEvents.move_used.connect(_on_move_used)
	BattleEvents.move_prevented.connect(_on_move_prevented)
	BattleEvents.move_missed.connect(_on_move_missed)
	BattleEvents.pokemon_switched.connect(_on_pokemon_switched)
	BattleEvents.player_forfeited.connect(_on_player_forfeited)

	# Damage/healing events
	BattleEvents.damage_dealt.connect(_on_damage_dealt)
	BattleEvents.pokemon_healed.connect(_on_pokemon_healed)
	BattleEvents.pokemon_fainted.connect(_on_pokemon_fainted)

	# Status events
	BattleEvents.status_applied.connect(_on_status_applied)
	BattleEvents.status_damage.connect(_on_status_damage)
	BattleEvents.stat_stage_changed.connect(_on_stat_stage_changed)

	# Field effects
	BattleEvents.weather_changed.connect(_on_weather_changed)
	BattleEvents.weather_damage.connect(_on_weather_damage)
	BattleEvents.terrain_changed.connect(_on_terrain_changed)

	# Move effects
	BattleEvents.move_critical_hit.connect(_on_move_critical_hit)
	BattleEvents.move_super_effective.connect(_on_move_super_effective)
	BattleEvents.move_not_very_effective.connect(_on_move_not_very_effective)
	BattleEvents.move_no_effect.connect(_on_move_no_effect)


# ==================== Test Scenarios ====================

func _test_basic_battle() -> void:
	"""Test basic battle flow with two Pokemon."""

	# Create engine with test seed
	engine = BattleEngineScript.new(TEST_SEED)

	# Create test teams
	var team1 := _create_test_team_1()
	var team2 := _create_test_team_2()

	# Initialize battle
	(engine as RefCounted).call("initialize_battle", team1, team2)

	# Execute several turns
	turn_count = 0
	for i in range(TEST_TURNS):
		if (engine as RefCounted).call("is_battle_over"):
			break

		# Both players use their first move
		var p1_action := BattleActionScript.new_move_action(0)
		var p2_action := BattleActionScript.new_move_action(0)

		(engine as RefCounted).call("execute_turn", p1_action, p2_action)
		turn_count += 1

	# Print final state
	print()
	print("Final Battle State:")
	var state = (engine as RefCounted).get("state")
	print("  Turn Count: %d" % turn_count)
	print("  Battle Status: %s" % _get_battle_status_string(state.battle_status))
	if (engine as RefCounted).call("is_battle_over"):
		print("  Winner: Player %d" % (engine as RefCounted).call("get_winner"))

	var p1_active = state.get_active_pokemon(1)
	print("  Player 1 Active: %s (HP: %d/%d)" % [
		p1_active.get_display_name(),
		p1_active.current_hp,
		p1_active.max_hp
	])
	var p2_active = state.get_active_pokemon(2)
	print("  Player 2 Active: %s (HP: %d/%d)" % [
		p2_active.get_display_name(),
		p2_active.current_hp,
		p2_active.max_hp
	])


func _test_deterministic_replay() -> void:
	"""Test that battles are deterministic with same seed."""

	# Run battle twice with same seed
	var results := []

	for run in range(2):
		var test_engine := BattleEngineScript.new(TEST_SEED)
		var team1 := _create_test_team_1()
		var team2 := _create_test_team_2()

		(test_engine as RefCounted).call("initialize_battle", team1, team2)

		# Execute 3 turns
		for i in range(3):
			if (test_engine as RefCounted).call("is_battle_over"):
				break

			var p1_action := BattleActionScript.new_move_action(0)
			var p2_action := BattleActionScript.new_move_action(0)
			(test_engine as RefCounted).call("execute_turn", p1_action, p2_action)

		# Record results
		var test_state = (test_engine as RefCounted).get("state")
		results.append({
			"p1_hp": test_state.get_active_pokemon(1).current_hp,
			"p2_hp": test_state.get_active_pokemon(2).current_hp,
			"turn": test_state.turn_number,
			"winner": (test_engine as RefCounted).call("get_winner")
		})

	# Compare results
	var run1 = results[0]
	var run2 = results[1]

	print("Run 1: P1 HP=%d, P2 HP=%d, Turn=%d, Winner=%d" % [
		run1.p1_hp, run1.p2_hp, run1.turn, run1.winner
	])
	print("Run 2: P1 HP=%d, P2 HP=%d, Turn=%d, Winner=%d" % [
		run2.p1_hp, run2.p2_hp, run2.turn, run2.winner
	])

	if run1.p1_hp == run2.p1_hp and run1.p2_hp == run2.p2_hp and run1.turn == run2.turn:
		print("✓ PASS: Deterministic replay verified!")
	else:
		print("✗ FAIL: Results differ between runs!")


# ==================== Test Data Creation ====================

func _create_test_team_1() -> Array:
	"""Create Player 1's test team (Pikachu)."""
	var pikachu_data := DataManager.get_pokemon_by_name("pikachu")
	var thunderbolt := DataManager.get_move_by_name("thunderbolt")
	var quick_attack := DataManager.get_move_by_name("quick-attack")

	var pikachu := BattlePokemonScript.new(
		pikachu_data,
		50,  # level
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},  # max IVs
		{"spa": 252, "spe": 252, "hp": 4},  # EVs (special attack focus)
		"Timid",  # nature (+Spe, -Atk)
		[thunderbolt, quick_attack],  # moves
		"Static",  # ability
		"",  # no item
		"Pikachu"  # nickname
	)

	return [pikachu]


func _create_test_team_2() -> Array:
	"""Create Player 2's test team (Charizard)."""
	var charizard_data := DataManager.get_pokemon_by_name("charizard")
	var flamethrower := DataManager.get_move_by_name("flamethrower")
	var dragon_claw := DataManager.get_move_by_name("dragon-claw")

	var charizard := BattlePokemonScript.new(
		charizard_data,
		50,  # level
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},  # max IVs
		{"spa": 252, "spe": 252, "hp": 4},  # EVs (special attack focus)
		"Modest",  # nature (+SpA, -Atk)
		[flamethrower, dragon_claw],  # moves
		"Blaze",  # ability
		"",  # no item
		"Charizard"  # nickname
	)

	return [charizard]


# ==================== Event Handlers ====================

func _on_battle_started(state) -> void:
	print("⚔️  Battle Started!")
	print("   Player 1: %s" % state.get_active_pokemon(1).get_display_name())
	print("   Player 2: %s" % state.get_active_pokemon(2).get_display_name())
	print()


func _on_turn_started(turn_number: int) -> void:
	print("--- Turn %d ---" % turn_number)


func _on_turn_ended(turn_number: int) -> void:
	print()


func _on_battle_ended(winner: int) -> void:
	print()
	if winner == 0:
		print("🏳️  Battle ended in a draw!")
	else:
		print("🏆  Player %d wins!" % winner)


func _on_move_used(user, move, target) -> void:
	print("  %s used %s!" % [user.get_display_name(), move.name.capitalize()])


func _on_move_prevented(pokemon, reason) -> void:
	print("  %s cannot move (%s)!" % [pokemon.get_display_name(), reason])


func _on_move_missed(user, target) -> void:
	print("  %s's move missed!" % user.get_display_name())


func _on_pokemon_switched(player, old_pokemon, new_pokemon) -> void:
	print("  Player %d: %s switched to %s!" % [
		player,
		old_pokemon.get_display_name(),
		new_pokemon.get_display_name()
	])


func _on_player_forfeited(player) -> void:
	print("  Player %d forfeited!" % player)


func _on_damage_dealt(pokemon, amount, new_hp) -> void:
	var hp_percent = pokemon.get_hp_percentage() * 100.0
	print("  %s took %d damage! (HP: %d/%d, %.1f%%)" % [
		pokemon.get_display_name(),
		amount,
		new_hp,
		pokemon.max_hp,
		hp_percent
	])


func _on_pokemon_healed(pokemon, amount, new_hp) -> void:
	print("  %s restored %d HP! (HP: %d/%d)" % [
		pokemon.get_display_name(),
		amount,
		new_hp,
		pokemon.max_hp
	])


func _on_pokemon_fainted(pokemon) -> void:
	print("  💀 %s fainted!" % pokemon.get_display_name())


func _on_status_applied(pokemon, status) -> void:
	print("  %s was inflicted with %s!" % [pokemon.get_display_name(), status])


func _on_status_damage(pokemon, status, damage) -> void:
	print("  %s took %d damage from %s!" % [
		pokemon.get_display_name(),
		damage,
		status
	])


func _on_stat_stage_changed(pokemon, stat, change, new_stage) -> void:
	var direction = "rose" if change > 0 else "fell"
	print("  %s's %s %s!" % [pokemon.get_display_name(), stat.to_upper(), direction])


func _on_weather_changed(new_weather, duration) -> void:
	print("  🌤️  Weather changed to %s!" % new_weather)


func _on_weather_damage(pokemon, weather, damage) -> void:
	print("  %s took %d damage from %s!" % [
		pokemon.get_display_name(),
		damage,
		weather
	])


func _on_terrain_changed(new_terrain, duration) -> void:
	print("  🌍 Terrain changed to %s!" % new_terrain)


func _on_move_critical_hit(user, target) -> void:
	print("  💥 Critical hit!")


func _on_move_super_effective(effectiveness) -> void:
	print("  ✨ It's super effective! (%.1fx)" % effectiveness)


func _on_move_not_very_effective(effectiveness) -> void:
	print("  😕 It's not very effective... (%.1fx)" % effectiveness)


func _on_move_no_effect(user, target) -> void:
	print("  ❌ It had no effect on %s!" % target.get_display_name())


# ==================== Helper Methods ====================

func _get_battle_status_string(status) -> String:
	"""Convert BattleStatus enum to readable string."""
	match status:
		0:  # NOT_STARTED
			return "Not Started"
		1:  # IN_PROGRESS
			return "In Progress"
		2:  # PLAYER1_WIN
			return "Player 1 Victory"
		3:  # PLAYER2_WIN
			return "Player 2 Victory"
		4:  # DRAW
			return "Draw"
		_:
			return "Unknown"
