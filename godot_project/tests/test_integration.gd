extends Node

## Integration Test Suite
##
## Comprehensive integration tests covering the complete battle system:
## - Data loading and caching
## - Pokemon creation and stat calculation
## - Battle engine turn execution
## - Damage calculation accuracy
## - Network protocol and serialization
## - Complete battle flow from start to finish

const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")
const BattleEngineScript = preload("res://scripts/core/BattleEngine.gd")
const BattleActionScript = preload("res://scripts/core/BattleAction.gd")
const NetworkProtocol = preload("res://scripts/networking/NetworkProtocol.gd")

var test_results: Array = []
var total_tests: int = 0
var passed_tests: int = 0


func _ready() -> void:
	print("=== INTEGRATION TEST SUITE ===\n")

	# Run all integration tests
	_test_data_manager()
	_test_pokemon_creation()
	_test_stat_calculation()
	_test_type_effectiveness()
	_test_damage_calculation()
	_test_battle_initialization()
	_test_battle_turn_execution()
	_test_pokemon_serialization()
	_test_battle_state_serialization()
	_test_complete_battle_flow()

	# Print results
	_print_results()

	# Exit
	get_tree().quit()


func _test_data_manager() -> void:
	"""Test DataManager resource loading."""
	print("Test Suite: DataManager")

	# Load Pokemon data
	var pikachu = DataManager.get_pokemon(25)
	_assert(pikachu != null, "Pikachu data should load")
	_assert(pikachu.name == "pikachu", "Pikachu name should match")
	_assert(pikachu.type1 == "electric", "Pikachu type should be electric")

	# Load move data
	var thunderbolt = DataManager.get_move(85)
	_assert(thunderbolt != null, "Thunderbolt data should load")
	_assert(thunderbolt.name == "thunderbolt", "Thunderbolt name should match")
	_assert(thunderbolt.power == 90, "Thunderbolt power should be 90")

	# Caching test - second load should be instant
	var pikachu2 = DataManager.get_pokemon(25)
	_assert(pikachu == pikachu2, "DataManager should cache resources")

	print("")


func _test_pokemon_creation() -> void:
	"""Test BattlePokemon instantiation."""
	print("Test Suite: Pokemon Creation")

	var species = DataManager.get_pokemon(25)  # Pikachu
	var move1 = DataManager.get_move(85)  # Thunderbolt
	var move2 = DataManager.get_move(98)  # Quick Attack

	var pokemon = BattlePokemonScript.new(
		species, 50,
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},
		{"hp": 4, "atk": 0, "def": 0, "spa": 252, "spd": 0, "spe": 252},
		"Timid",
		[move1, move2],
		"",  # Empty string uses default ability
		"",
		"TestPikachu"
	)

	_assert(pokemon != null, "Pokemon should be created")
	_assert(pokemon.species.name == "pikachu", "Species should be pikachu")
	_assert(pokemon.level == 50, "Level should be 50")
	_assert(pokemon.nickname == "TestPikachu", "Nickname should match")
	_assert(pokemon.moves.size() == 2, "Should have 2 moves")
	_assert(pokemon.current_hp > 0, "HP should be calculated")
	_assert(not pokemon.is_fainted(), "Pokemon should not be fainted")

	print("")


func _test_stat_calculation() -> void:
	"""Test stat calculation formulas."""
	print("Test Suite: Stat Calculation")

	var species = DataManager.get_pokemon(25)  # Pikachu
	var move = DataManager.get_move(85)

	# Perfect IVs, max EVs in SpA and Spe, Timid nature
	var pokemon = BattlePokemonScript.new(
		species, 50,
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},
		{"hp": 4, "atk": 0, "def": 0, "spa": 252, "spd": 0, "spe": 252},
		"Timid",
		[move],
		"",  # Empty string uses default ability
		"",
		""
	)

	# HP stat
	_assert(pokemon.stats["hp"] > 0, "HP stat should be calculated")

	# Stats should be calculated
	_assert(pokemon.stats["atk"] > 0, "Attack stat should be calculated")
	_assert(pokemon.stats["def"] > 0, "Defense stat should be calculated")
	_assert(pokemon.stats["spa"] > 0, "Sp. Atk stat should be calculated")
	_assert(pokemon.stats["spd"] > 0, "Sp. Def stat should be calculated")
	_assert(pokemon.stats["spe"] > 0, "Speed stat should be calculated")

	# Stat stages (0 at start)
	_assert(pokemon.stat_stages["atk"] == 0, "Stat stages should start at 0")

	print("")


func _test_type_effectiveness() -> void:
	"""Test type effectiveness calculations."""
	print("Test Suite: Type Effectiveness")

	# Super effective: Electric vs Water
	var effectiveness1 = TypeChart.calculate_type_effectiveness("electric", ["water", ""])
	_assert(effectiveness1 == 2.0, "Electric vs Water should be 2x")

	# Not very effective: Electric vs Grass
	var effectiveness2 = TypeChart.calculate_type_effectiveness("electric", ["grass", ""])
	_assert(effectiveness2 == 0.5, "Electric vs Grass should be 0.5x")

	# Immune: Electric vs Ground
	var effectiveness3 = TypeChart.calculate_type_effectiveness("electric", ["ground", ""])
	_assert(effectiveness3 == 0.0, "Electric vs Ground should be 0x")

	# Dual type: Electric vs Water/Flying (4x)
	var effectiveness4 = TypeChart.calculate_type_effectiveness("electric", ["water", "flying"])
	_assert(effectiveness4 == 4.0, "Electric vs Water/Flying should be 4x")

	# Neutral
	var effectiveness5 = TypeChart.calculate_type_effectiveness("normal", ["normal", ""])
	_assert(effectiveness5 == 1.0, "Normal vs Normal should be 1x")

	print("")


func _test_damage_calculation() -> void:
	"""Test damage calculation accuracy."""
	print("Test Suite: Damage Calculation")

	var attacker_species = DataManager.get_pokemon(25)  # Pikachu
	var defender_species = DataManager.get_pokemon(130)  # Gyarados
	var move = DataManager.get_move(85)  # Thunderbolt

	var attacker = BattlePokemonScript.new(
		attacker_species, 50,
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},
		{"hp": 4, "atk": 0, "def": 0, "spa": 252, "spd": 0, "spe": 252},
		"Timid",
		[move],
		"",  # Empty string uses default ability
		"",
		""
	)

	var defender = BattlePokemonScript.new(
		defender_species, 50,
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},
		{"hp": 4, "atk": 0, "def": 0, "spa": 0, "spd": 0, "spe": 252},
		"Adamant",
		[move],
		"",  # Empty string uses default ability
		"",
		""
	)

	var type_eff = TypeChart.calculate_type_effectiveness(
		move.type,
		[defender.species.type1, defender.species.type2]
	)

	var damage = DamageCalculator.calculate_damage({
		"level": attacker.level,
		"power": move.power,
		"attack": attacker.stats["spa"],
		"defense": defender.stats["spd"],
		"move_type": move.type,
		"attacker_types": [attacker.species.type1, attacker.species.type2],
		"is_physical": false,
		"type_effectiveness": type_eff,
		"weather": "",
		"random_factor": 1.0  # Max roll
	})

	_assert(damage > 0, "Damage should be calculated")

	# Type effectiveness should increase damage
	_assert(type_eff == 4.0, "Electric vs Water/Flying should be 4x")

	print("")


func _test_battle_initialization() -> void:
	"""Test battle initialization."""
	print("Test Suite: Battle Initialization")

	var team1 = _create_test_team()
	var team2 = _create_test_team()

	var engine = BattleEngineScript.new(12345)  # Deterministic seed
	engine.call("initialize_battle", team1, team2)

	var state = engine.get("state")
	_assert(state != null, "Battle state should be initialized")
	_assert(state.get_team(1).size() == 1, "Team 1 should have 1 Pokemon")
	_assert(state.get_team(2).size() == 1, "Team 2 should have 1 Pokemon")
	_assert(state.get_active_pokemon(1) != null, "Player 1 should have active Pokemon")
	_assert(state.get_active_pokemon(2) != null, "Player 2 should have active Pokemon")
	_assert(state.turn_number == 0, "Turn should start at 0")

	print("")


func _test_battle_turn_execution() -> void:
	"""Test battle turn execution."""
	print("Test Suite: Battle Turn Execution")

	var team1 = _create_test_team()
	var team2 = _create_test_team()

	var engine = BattleEngineScript.new(12345)
	engine.call("initialize_battle", team1, team2)

	# Both players use first move
	var p1_action = BattleActionScript.new(
		BattleActionScript.ActionType.MOVE,
		0, 0, -1
	)
	var p2_action = BattleActionScript.new(
		BattleActionScript.ActionType.MOVE,
		0, 0, -1
	)

	var state_before = engine.get("state")
	var p1_hp_before = state_before.get_active_pokemon(1).current_hp
	var p2_hp_before = state_before.get_active_pokemon(2).current_hp

	engine.call("execute_turn", p1_action, p2_action)

	var state_after = engine.get("state")
	_assert(state_after.turn_number == 1, "Turn should increment")

	# At least one Pokemon should take damage
	var p1_hp_after = state_after.get_active_pokemon(1).current_hp
	var p2_hp_after = state_after.get_active_pokemon(2).current_hp
	var damage_dealt = (p1_hp_after < p1_hp_before) or (p2_hp_after < p2_hp_before)
	_assert(damage_dealt, "Damage should be dealt during turn")

	print("")


func _test_pokemon_serialization() -> void:
	"""Test Pokemon to_dict and from_dict."""
	print("Test Suite: Pokemon Serialization")

	var species = DataManager.get_pokemon(25)
	var move1 = DataManager.get_move(85)
	var move2 = DataManager.get_move(98)

	var original = BattlePokemonScript.new(
		species, 50,
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},
		{"hp": 4, "atk": 0, "def": 0, "spa": 252, "spd": 0, "spe": 252},
		"Timid",
		[move1, move2],
		"",  # Empty string uses default ability
		"life-orb",
		"TestPikachu"
	)

	var dict = original.to_dict()
	_assert(dict is Dictionary, "to_dict should return Dictionary")
	_assert(dict.has("species_id"), "Dict should have species_id")
	_assert(dict.has("level"), "Dict should have level")

	var restored = BattlePokemonScript.from_dict(dict)
	_assert(restored != null, "Pokemon should be restored from dict")
	_assert(restored.species.pokemon_id == original.species.pokemon_id, "Species should match")
	_assert(restored.level == original.level, "Level should match")
	_assert(restored.current_hp == original.current_hp, "HP should match")
	_assert(restored.moves.size() == original.moves.size(), "Move count should match")

	print("")


func _test_battle_state_serialization() -> void:
	"""Test BattleState serialization for network transmission."""
	print("Test Suite: Battle State Serialization")

	var team1 = _create_test_team()
	var team2 = _create_test_team()

	var engine = BattleEngineScript.new(12345)
	engine.call("initialize_battle", team1, team2)

	var state = engine.get("state")
	var dict = state.to_dict()

	_assert(dict is Dictionary, "State to_dict should return Dictionary")
	_assert(dict.has("team1"), "State dict should have team1")
	_assert(dict.has("team2"), "State dict should have team2")

	# Validate team serialization
	_assert(dict["team1"] is Array, "Team1 should be an array")
	_assert(dict["team1"].size() == 1, "Team1 should have 1 Pokemon")

	print("")


func _test_complete_battle_flow() -> void:
	"""Test complete battle from start to finish."""
	print("Test Suite: Complete Battle Flow")

	var team1 = _create_test_team()
	var team2 = _create_test_team()

	var engine = BattleEngineScript.new(12345)
	engine.call("initialize_battle", team1, team2)

	# Battle until one side wins (max 100 turns to prevent infinite loop)
	var max_turns = 100
	var turns_executed = 0

	while not engine.call("is_battle_over") and turns_executed < max_turns:
		var p1_action = BattleActionScript.new(
			BattleActionScript.ActionType.MOVE,
			0, 0, -1
		)
		var p2_action = BattleActionScript.new(
			BattleActionScript.ActionType.MOVE,
			0, 0, -1
		)

		engine.call("execute_turn", p1_action, p2_action)
		turns_executed += 1

	_assert(engine.call("is_battle_over"), "Battle should end eventually")

	var winner = engine.call("get_winner")
	_assert(winner == 1 or winner == 2, "Winner should be player 1 or 2")

	var state = engine.get("state")
	var winning_team = state.get_team(winner)
	var losing_team = state.get_team(3 - winner)  # Other team

	# Winning team should have at least one conscious Pokemon
	var has_conscious = false
	for pokemon in winning_team:
		if not pokemon.is_fainted():
			has_conscious = true
			break
	_assert(has_conscious, "Winning team should have conscious Pokemon")

	# Losing team should be all fainted
	var all_fainted = true
	for pokemon in losing_team:
		if not pokemon.is_fainted():
			all_fainted = false
			break
	_assert(all_fainted, "Losing team should be all fainted")

	print("")


func _create_test_team() -> Array:
	"""Create a test team for battles."""
	var species = DataManager.get_pokemon(25)  # Pikachu
	var move1 = DataManager.get_move(85)  # Thunderbolt
	var move2 = DataManager.get_move(98)  # Quick Attack

	var pokemon = BattlePokemonScript.new(
		species, 50,
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},
		{"hp": 4, "atk": 0, "def": 0, "spa": 252, "spd": 0, "spe": 252},
		"Timid",
		[move1, move2],
		"",  # Empty string uses default ability
		"",
		""
	)

	return [pokemon]


func _assert(condition: bool, test_name: String) -> void:
	"""Record test result."""
	total_tests += 1

	if condition:
		passed_tests += 1
		print("  ✓ %s" % test_name)
		test_results.append({"name": test_name, "passed": true})
	else:
		print("  ✗ %s" % test_name)
		test_results.append({"name": test_name, "passed": false})


func _print_results() -> void:
	"""Print final test results."""
	print("\n=== TEST RESULTS ===")
	print("Total tests: %d" % total_tests)
	print("Passed: %d" % passed_tests)
	print("Failed: %d" % (total_tests - passed_tests))
	print("Success rate: %.1f%%" % ((passed_tests / float(total_tests)) * 100.0))

	if passed_tests == total_tests:
		print("\n✓ ALL INTEGRATION TESTS PASSED")
	else:
		print("\n✗ SOME TESTS FAILED")
		print("\nFailed tests:")
		for result in test_results:
			if not result["passed"]:
				print("  - %s" % result["name"])
