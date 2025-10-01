extends Node

## Test script for accuracy mechanics
##
## Verifies accuracy calculation, stat stages, and never-miss moves

# Preload necessary classes
const BattleEngineScript = preload("res://scripts/core/BattleEngine.gd")
const BattleActionScript = preload("res://scripts/core/BattleAction.gd")
const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")
const MoveDataScript = preload("res://scripts/data/MoveData.gd")

# ==================== Test Configuration ====================

const TEST_SEED := 67890
const STAT_TEST_ITERATIONS := 1000  # For statistical testing

# ==================== Test State ====================

var engine  # Type: BattleEngine
var test_passed := 0
var test_failed := 0

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize and run accuracy tests."""
	print("================================================================================")
	print("ACCURACY MECHANICS TEST - Phase 1 Week 5")
	print("================================================================================")
	print()

	# Run test scenarios
	_test_perfect_accuracy()
	_test_low_accuracy()
	_test_accuracy_stat_stages()
	_test_evasion_stat_stages()
	_test_combined_accuracy_evasion()
	_test_never_miss_moves()
	_test_deterministic_accuracy()
	_test_accuracy_statistical()

	# Print summary
	print()
	print("================================================================================")
	print("TEST SUMMARY")
	print("================================================================================")
	print("Passed: %d" % test_passed)
	print("Failed: %d" % test_failed)
	print("Total:  %d" % (test_passed + test_failed))
	if test_failed == 0:
		print("✓ ALL TESTS PASSED")
	else:
		print("✗ SOME TESTS FAILED")
	print("================================================================================")


# ==================== Test Scenarios ====================

func _test_perfect_accuracy() -> void:
	"""Test that 100% accuracy moves always hit."""
	print("[TEST] Perfect Accuracy (100%)")
	print("--------------------------------------------------------------------------------")

	var move := _create_test_move("Perfect Move", "normal", 50, 100)
	var attacker := _create_test_pokemon("pikachu", [move])
	var defender := _create_test_pokemon("charizard", [])

	var hits := 0
	var total_attempts := 100

	for i in range(total_attempts):
		var test_engine := BattleEngineScript.new(TEST_SEED + i)
		(test_engine as RefCounted).call("initialize_battle", [attacker], [defender])

		var state = (test_engine as RefCounted).get("state")
		var target = state.get_active_pokemon(2)
		var hp_before = target.current_hp

		var action := BattleActionScript.new_move_action(0)
		var pass_action := BattleActionScript.new_forfeit_action()
		(test_engine as RefCounted).call("execute_turn", action, pass_action)

		var hp_after = target.current_hp

		if hp_after < hp_before:
			hits += 1

	if hits == total_attempts:
		print("✓ PASS: 100%% accuracy move hit %d/%d times" % [hits, total_attempts])
		test_passed += 1
	else:
		print("✗ FAIL: 100%% accuracy move hit %d/%d times" % [hits, total_attempts])
		test_failed += 1

	print()


func _test_low_accuracy() -> void:
	"""Test that low accuracy moves miss appropriately."""
	print("[TEST] Low Accuracy (50%)")
	print("--------------------------------------------------------------------------------")

	var move := _create_test_move("Low Accuracy Move", "normal", 50, 50)
	var attacker := _create_test_pokemon("pikachu", [move])
	var defender := _create_test_pokemon("charizard", [])

	var hits := 0
	var total_attempts := STAT_TEST_ITERATIONS

	for i in range(total_attempts):
		var test_engine := BattleEngineScript.new(TEST_SEED + i)
		var test_attacker := _create_test_pokemon("pikachu", [move])
		var test_defender := _create_test_pokemon("charizard", [])

		(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

		var state = (test_engine as RefCounted).get("state")
		var target = state.get_active_pokemon(2)
		var hp_before = target.current_hp

		var action := BattleActionScript.new_move_action(0)
		var pass_action := BattleActionScript.new_forfeit_action()
		(test_engine as RefCounted).call("execute_turn", action, pass_action)

		var hp_after = target.current_hp

		if hp_after < hp_before:
			hits += 1

	var hit_rate = float(hits) / float(total_attempts)
	var expected_rate = 0.50
	var tolerance = 0.05  # 5% tolerance

	print("  Hit rate: %d/%d (%.1f%%)" % [hits, total_attempts, hit_rate * 100])

	if abs(hit_rate - expected_rate) <= tolerance:
		print("✓ PASS: 50%% accuracy within tolerance")
		test_passed += 1
	else:
		print("✗ FAIL: 50%% accuracy outside tolerance (expected 50%% ± 5%%)")
		test_failed += 1

	print()


func _test_accuracy_stat_stages() -> void:
	"""Test that accuracy stat stages increase hit rate."""
	print("[TEST] Accuracy Stat Stages (+6)")
	print("--------------------------------------------------------------------------------")

	var move := _create_test_move("Test Move", "normal", 50, 50)

	var hits_normal := 0
	var hits_boosted := 0
	var total_attempts := STAT_TEST_ITERATIONS

	# Test without accuracy boost
	for i in range(total_attempts):
		var test_engine := BattleEngineScript.new(TEST_SEED + i)
		var test_attacker := _create_test_pokemon("pikachu", [move])
		var test_defender := _create_test_pokemon("charizard", [])

		(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

		var state = (test_engine as RefCounted).get("state")
		var target = state.get_active_pokemon(2)
		var hp_before = target.current_hp

		var action := BattleActionScript.new_move_action(0)
		var pass_action := BattleActionScript.new_forfeit_action()
		(test_engine as RefCounted).call("execute_turn", action, pass_action)

		var hp_after = target.current_hp
		if hp_after < hp_before:
			hits_normal += 1

	# Test with +6 accuracy
	for i in range(total_attempts):
		var test_engine := BattleEngineScript.new(TEST_SEED + i + 10000)
		var test_attacker := _create_test_pokemon("pikachu", [move])
		test_attacker.modify_stat_stage("accuracy", 6)
		var test_defender := _create_test_pokemon("charizard", [])

		(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

		var state = (test_engine as RefCounted).get("state")
		var target = state.get_active_pokemon(2)
		var hp_before = target.current_hp

		var action := BattleActionScript.new_move_action(0)
		var pass_action := BattleActionScript.new_forfeit_action()
		(test_engine as RefCounted).call("execute_turn", action, pass_action)

		var hp_after = target.current_hp
		if hp_after < hp_before:
			hits_boosted += 1

	var hit_rate_normal = float(hits_normal) / float(total_attempts)
	var hit_rate_boosted = float(hits_boosted) / float(total_attempts)

	print("  Normal hit rate: %.1f%%" % (hit_rate_normal * 100))
	print("  Boosted hit rate (+6 accuracy): %.1f%%" % (hit_rate_boosted * 100))

	# With +6 accuracy, 50% base should become 50% * 3.0 = 150% (capped at 100%)
	if hit_rate_boosted > hit_rate_normal and hit_rate_boosted >= 0.95:
		print("✓ PASS: +6 accuracy significantly increased hit rate")
		test_passed += 1
	else:
		print("✗ FAIL: +6 accuracy did not increase hit rate appropriately")
		test_failed += 1

	print()


func _test_evasion_stat_stages() -> void:
	"""Test that evasion stat stages decrease hit rate."""
	print("[TEST] Evasion Stat Stages (+6)")
	print("--------------------------------------------------------------------------------")

	var move := _create_test_move("Test Move", "normal", 50, 100)

	var hits_normal := 0
	var hits_with_evasion := 0
	var total_attempts := STAT_TEST_ITERATIONS

	# Test without evasion
	for i in range(total_attempts):
		var test_engine := BattleEngineScript.new(TEST_SEED + i)
		var test_attacker := _create_test_pokemon("pikachu", [move])
		var test_defender := _create_test_pokemon("charizard", [])

		(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

		var state = (test_engine as RefCounted).get("state")
		var target = state.get_active_pokemon(2)
		var hp_before = target.current_hp

		var action := BattleActionScript.new_move_action(0)
		var pass_action := BattleActionScript.new_forfeit_action()
		(test_engine as RefCounted).call("execute_turn", action, pass_action)

		var hp_after = target.current_hp
		if hp_after < hp_before:
			hits_normal += 1

	# Test with +6 evasion on defender
	for i in range(total_attempts):
		var test_engine := BattleEngineScript.new(TEST_SEED + i + 10000)
		var test_attacker := _create_test_pokemon("pikachu", [move])
		var test_defender := _create_test_pokemon("charizard", [])
		test_defender.modify_stat_stage("evasion", 6)

		(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

		var state = (test_engine as RefCounted).get("state")
		var target = state.get_active_pokemon(2)
		var hp_before = target.current_hp

		var action := BattleActionScript.new_move_action(0)
		var pass_action := BattleActionScript.new_forfeit_action()
		(test_engine as RefCounted).call("execute_turn", action, pass_action)

		var hp_after = target.current_hp
		if hp_after < hp_before:
			hits_with_evasion += 1

	var hit_rate_normal = float(hits_normal) / float(total_attempts)
	var hit_rate_with_evasion = float(hits_with_evasion) / float(total_attempts)

	print("  Normal hit rate: %.1f%%" % (hit_rate_normal * 100))
	print("  With +6 evasion: %.1f%%" % (hit_rate_with_evasion * 100))

	# With +6 evasion, 100% accuracy should become 100% / 3.0 = 33.3%
	var expected_rate = 1.0 / 3.0
	var tolerance = 0.05

	if hit_rate_with_evasion < hit_rate_normal and abs(hit_rate_with_evasion - expected_rate) <= tolerance:
		print("✓ PASS: +6 evasion decreased hit rate to ~33%%")
		test_passed += 1
	else:
		print("✗ FAIL: +6 evasion did not decrease hit rate appropriately")
		test_failed += 1

	print()


func _test_combined_accuracy_evasion() -> void:
	"""Test combined accuracy and evasion stat stages."""
	print("[TEST] Combined Accuracy/Evasion Stages")
	print("--------------------------------------------------------------------------------")

	var move := _create_test_move("Test Move", "normal", 50, 100)

	# Test: +2 accuracy vs +2 evasion (should cancel out to 100% accuracy)
	var hits := 0
	var total_attempts := 100

	for i in range(total_attempts):
		var test_engine := BattleEngineScript.new(TEST_SEED + i)
		var test_attacker := _create_test_pokemon("pikachu", [move])
		test_attacker.modify_stat_stage("accuracy", 2)
		var test_defender := _create_test_pokemon("charizard", [])
		test_defender.modify_stat_stage("evasion", 2)

		(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

		var state = (test_engine as RefCounted).get("state")
		var target = state.get_active_pokemon(2)
		var hp_before = target.current_hp

		var action := BattleActionScript.new_move_action(0)
		var pass_action := BattleActionScript.new_forfeit_action()
		(test_engine as RefCounted).call("execute_turn", action, pass_action)

		var hp_after = target.current_hp
		if hp_after < hp_before:
			hits += 1

	var hit_rate = float(hits) / float(total_attempts)

	print("  Hit rate (+2 accuracy vs +2 evasion): %.1f%%" % (hit_rate * 100))

	# Should be close to 100% since they cancel out
	if hit_rate >= 0.95:
		print("✓ PASS: Accuracy and evasion stages cancel out correctly")
		test_passed += 1
	else:
		print("✗ FAIL: Accuracy and evasion stages did not cancel out correctly")
		test_failed += 1

	print()


func _test_never_miss_moves() -> void:
	"""Test that never-miss moves always hit regardless of evasion."""
	print("[TEST] Never-Miss Moves")
	print("--------------------------------------------------------------------------------")

	var move := _create_test_move("Swift", "normal", 60, 0)  # 0 accuracy = never miss

	var hits := 0
	var total_attempts := 100

	for i in range(total_attempts):
		var test_engine := BattleEngineScript.new(TEST_SEED + i)
		var test_attacker := _create_test_pokemon("pikachu", [move])
		var test_defender := _create_test_pokemon("charizard", [])
		test_defender.modify_stat_stage("evasion", 6)  # Max evasion

		(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

		var state = (test_engine as RefCounted).get("state")
		var target = state.get_active_pokemon(2)
		var hp_before = target.current_hp

		var action := BattleActionScript.new_move_action(0)
		var pass_action := BattleActionScript.new_forfeit_action()
		(test_engine as RefCounted).call("execute_turn", action, pass_action)

		var hp_after = target.current_hp
		if hp_after < hp_before:
			hits += 1

	if hits == total_attempts:
		print("✓ PASS: Never-miss move hit through +6 evasion (%d/%d)" % [hits, total_attempts])
		test_passed += 1
	else:
		print("✗ FAIL: Never-miss move missed %d times" % (total_attempts - hits))
		test_failed += 1

	print()


func _test_deterministic_accuracy() -> void:
	"""Test that accuracy checks are deterministic with same seed."""
	print("[TEST] Deterministic Accuracy")
	print("--------------------------------------------------------------------------------")

	var move := _create_test_move("Test Move", "normal", 50, 75)
	var results := []

	for run in range(2):
		var test_engine := BattleEngineScript.new(TEST_SEED)
		var test_attacker := _create_test_pokemon("pikachu", [move])
		var test_defender := _create_test_pokemon("charizard", [])

		(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

		var state = (test_engine as RefCounted).get("state")
		var target = state.get_active_pokemon(2)
		var hp_before = target.current_hp

		var action := BattleActionScript.new_move_action(0)
		var pass_action := BattleActionScript.new_forfeit_action()
		(test_engine as RefCounted).call("execute_turn", action, pass_action)

		var hp_after = target.current_hp
		var hit = hp_after < hp_before

		results.append(hit)

	if results[0] == results[1]:
		print("✓ PASS: Accuracy is deterministic (both runs: %s)" % ("HIT" if results[0] else "MISS"))
		test_passed += 1
	else:
		print("✗ FAIL: Accuracy differs between runs")
		test_failed += 1

	print()


func _test_accuracy_statistical() -> void:
	"""Test that accuracy follows expected distribution."""
	print("[TEST] Accuracy Statistical Distribution")
	print("--------------------------------------------------------------------------------")

	var test_cases := [
		{"accuracy": 100, "expected": 1.00, "tolerance": 0.02},
		{"accuracy": 85, "expected": 0.85, "tolerance": 0.03},
		{"accuracy": 70, "expected": 0.70, "tolerance": 0.04}
	]

	for test_case in test_cases:
		var move := _create_test_move("Test Move", "normal", 50, test_case.accuracy)
		var hits := 0
		var total_attempts := STAT_TEST_ITERATIONS

		for i in range(total_attempts):
			var test_engine := BattleEngineScript.new(TEST_SEED + i)
			var test_attacker := _create_test_pokemon("pikachu", [move])
			var test_defender := _create_test_pokemon("charizard", [])

			(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

			var state = (test_engine as RefCounted).get("state")
			var target = state.get_active_pokemon(2)
			var hp_before = target.current_hp

			var action := BattleActionScript.new_move_action(0)
			var pass_action := BattleActionScript.new_forfeit_action()
			(test_engine as RefCounted).call("execute_turn", action, pass_action)

			var hp_after = target.current_hp
			if hp_after < hp_before:
				hits += 1

		var hit_rate = float(hits) / float(total_attempts)
		var expected_rate = test_case.expected
		var tolerance = test_case.tolerance

		print("  %d%% accuracy: %.1f%% hit rate (expected %.0f%% ± %.0f%%)" % [
			test_case.accuracy,
			hit_rate * 100,
			expected_rate * 100,
			tolerance * 100
		])

		if abs(hit_rate - expected_rate) <= tolerance:
			print("  ✓ Within tolerance")
		else:
			print("  ✗ Outside tolerance")
			test_failed += 1
			return

	test_passed += 1
	print()


# ==================== Test Helper Methods ====================

func _create_test_pokemon(species_name: String, moves: Array) -> BattlePokemonScript:
	"""Create a test Pokemon with given species and moves."""
	var species_data := DataManager.get_pokemon_by_name(species_name)

	if moves.is_empty():
		var tackle := DataManager.get_move_by_name("tackle")
		moves = [tackle]

	return BattlePokemonScript.new(
		species_data,
		50,
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},
		{"hp": 252, "atk": 0, "def": 0, "spa": 0, "spd": 0, "spe": 0},
		"Hardy",
		moves,
		"",
		"",
		""
	)


func _create_test_move(
	move_name: String,
	move_type: String,
	power: int,
	accuracy: int
) -> MoveDataScript:
	"""Create a custom test move with specified properties."""
	var move := MoveDataScript.new()
	move.name = move_name
	move.type = move_type
	move.power = power
	move.accuracy = accuracy
	move.pp = 10
	move.priority = 0
	move.damage_class = "physical"
	move.target = "selected-pokemon"

	return move
