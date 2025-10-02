extends Node

## Move Effect Test Suite
##
## Tests the new pluggable move effect system to ensure all effect types
## work correctly in battle scenarios.

const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")
const BattleEngineScript = preload("res://scripts/core/BattleEngine.gd")
const BattleActionScript = preload("res://scripts/core/BattleAction.gd")

var test_results: Array = []
var total_tests: int = 0
var passed_tests: int = 0


func _ready() -> void:
	print("=== MOVE EFFECT TEST SUITE ===\n")

	# Run all test suites
	_test_stat_change_moves()
	_test_status_inflicting_moves()
	_test_recoil_moves()
	_test_drain_moves()
	_test_healing_moves()
	_test_weather_moves()
	_test_multi_stat_moves()

	# Print results
	_print_results()

	# Exit
	get_tree().quit()


func _test_stat_change_moves() -> void:
	"""Test stat-changing moves like Swords Dance, Growl."""
	print("Test Suite: Stat Change Moves")

	# Create Pokemon with Swords Dance
	var attacker = _create_test_pokemon(25, [14])  # Pikachu with Swords Dance (move_id 14)
	var defender = _create_test_pokemon(6)  # Charizard

	var engine = BattleEngineScript.new(12345)
	engine.call("initialize_battle", [attacker], [defender])

	# Check initial attack stage
	_assert(attacker.stat_stages["atk"] == 0, "Initial attack stage should be 0")

	# Use Swords Dance
	var action1 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	var action2 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	engine.call("execute_turn", action1, action2)

	# Check attack stage increased
	_assert(attacker.stat_stages["atk"] == 2, "Swords Dance should raise attack by 2 stages")

	print("")


func _test_status_inflicting_moves() -> void:
	"""Test status-inflicting moves like Thunder Wave."""
	print("Test Suite: Status Inflicting Moves")

	# Create Pokemon with Thunder Wave
	var attacker = _create_test_pokemon(25, [86])  # Pikachu with Thunder Wave (move_id 86)
	var defender = _create_test_pokemon(6)  # Charizard

	var engine = BattleEngineScript.new(12345)
	engine.call("initialize_battle", [attacker], [defender])

	# Check initial status
	_assert(defender.status == "", "Defender should have no status initially")

	# Use Thunder Wave
	var action1 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	var action2 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	engine.call("execute_turn", action1, action2)

	# Check paralysis applied
	_assert(defender.status == "paralysis", "Thunder Wave should paralyze target")

	print("")


func _test_recoil_moves() -> void:
	"""Test recoil moves like Brave Bird."""
	print("Test Suite: Recoil Moves")

	# Create Pokemon with Brave Bird
	var attacker = _create_test_pokemon(25, [413])  # Pikachu with Brave Bird (move_id 413)
	var defender = _create_test_pokemon(6)  # Charizard

	var engine = BattleEngineScript.new(12345)
	engine.call("initialize_battle", [attacker], [defender])

	var hp_before = attacker.current_hp

	# Use Brave Bird
	var action1 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	var action2 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	engine.call("execute_turn", action1, action2)

	# Check recoil damage taken
	_assert(attacker.current_hp < hp_before, "Brave Bird should deal recoil damage to user")

	print("")


func _test_drain_moves() -> void:
	"""Test HP-draining moves like Giga Drain."""
	print("Test Suite: Drain Moves")

	# Create Pokemon with Giga Drain
	var attacker = _create_test_pokemon(25, [202])  # Pikachu with Giga Drain (move_id 202)
	var defender = _create_test_pokemon(6)  # Charizard

	# Damage attacker first so we can see healing
	attacker.current_hp = int(attacker.stats["hp"] * 0.5)

	var engine = BattleEngineScript.new(12345)
	engine.call("initialize_battle", [attacker], [defender])

	var hp_before = attacker.current_hp

	# Use Giga Drain
	var action1 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	var action2 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	engine.call("execute_turn", action1, action2)

	# Check HP restored
	_assert(attacker.current_hp > hp_before, "Giga Drain should restore HP to user")

	print("")


func _test_healing_moves() -> void:
	"""Test healing moves like Recover."""
	print("Test Suite: Healing Moves")

	# Create Pokemon with Recover
	var attacker = _create_test_pokemon(25, [105])  # Pikachu with Recover (move_id 105)
	var defender = _create_test_pokemon(6)  # Charizard

	# Damage attacker so healing is visible
	attacker.current_hp = int(attacker.stats["hp"] * 0.5)

	var engine = BattleEngineScript.new(12345)
	engine.call("initialize_battle", [attacker], [defender])

	var hp_before = attacker.current_hp

	# Use Recover
	var action1 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	var action2 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	engine.call("execute_turn", action1, action2)

	# Check HP restored
	_assert(attacker.current_hp > hp_before, "Recover should restore HP")
	var expected_hp = min(attacker.stats["hp"], int(hp_before + attacker.stats["hp"] * 0.5))
	_assert(attacker.current_hp >= expected_hp - 10, "Recover should restore ~50% max HP")

	print("")


func _test_weather_moves() -> void:
	"""Test weather-setting moves like Sunny Day."""
	print("Test Suite: Weather Moves")

	# Create Pokemon with Sunny Day
	var attacker = _create_test_pokemon(25, [241])  # Pikachu with Sunny Day (move_id 241)
	var defender = _create_test_pokemon(6)  # Charizard

	var engine = BattleEngineScript.new(12345)
	engine.call("initialize_battle", [attacker], [defender])

	var state = engine.get("state")
	_assert(state.weather == "", "Weather should be clear initially")

	# Use Sunny Day
	var action1 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	var action2 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	engine.call("execute_turn", action1, action2)

	# Check weather set
	_assert(state.weather == "sun", "Sunny Day should set sun weather")
	_assert(state.weather_turns_remaining == 5, "Weather should last 5 turns")

	print("")


func _test_multi_stat_moves() -> void:
	"""Test moves that change multiple stats like Dragon Dance."""
	print("Test Suite: Multi-Stat Change Moves")

	# Create Pokemon with Dragon Dance
	var attacker = _create_test_pokemon(25, [349])  # Pikachu with Dragon Dance (move_id 349)
	var defender = _create_test_pokemon(6)  # Charizard

	var engine = BattleEngineScript.new(12345)
	engine.call("initialize_battle", [attacker], [defender])

	# Check initial stages
	_assert(attacker.stat_stages["atk"] == 0, "Initial attack stage should be 0")
	_assert(attacker.stat_stages["spe"] == 0, "Initial speed stage should be 0")

	# Use Dragon Dance
	var action1 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	var action2 = BattleActionScript.new(BattleActionScript.ActionType.MOVE, 0, 0, -1)
	engine.call("execute_turn", action1, action2)

	# Check both stats increased
	_assert(attacker.stat_stages["atk"] == 1, "Dragon Dance should raise attack by 1")
	_assert(attacker.stat_stages["spe"] == 1, "Dragon Dance should raise speed by 1")

	print("")


func _create_test_pokemon(species_id: int, move_ids: Array = []) -> BattlePokemonScript:
	"""Create a test Pokemon."""
	var species = DataManager.get_pokemon(species_id)

	# Use provided moves or default to Tackle
	var moves = []
	if move_ids.is_empty():
		moves.append(DataManager.get_move(33))  # Tackle
	else:
		for move_id in move_ids:
			moves.append(DataManager.get_move(move_id))

	return BattlePokemonScript.new(
		species, 50,
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},
		{"hp": 4, "atk": 252, "def": 0, "spa": 0, "spd": 0, "spe": 252},
		"Adamant",
		moves,
		"",
		"",
		""
	)


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
		print("\n✓ ALL MOVE EFFECT TESTS PASSED")
	else:
		print("\n✗ SOME TESTS FAILED")
		print("\nFailed tests:")
		for result in test_results:
			if not result["passed"]:
				print("  - %s" % result["name"])
