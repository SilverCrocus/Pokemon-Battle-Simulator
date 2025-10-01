extends Node

## Test script for critical hit mechanics
##
## Verifies critical hit rate, high crit ratio moves, and damage calculation

# Preload necessary classes
const BattleEngineScript = preload("res://scripts/core/BattleEngine.gd")
const BattleActionScript = preload("res://scripts/core/BattleAction.gd")
const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")
const MoveDataScript = preload("res://scripts/data/MoveData.gd")
const DamageCalculatorScript = preload("res://scripts/core/DamageCalculator.gd")

# ==================== Test Configuration ====================

const TEST_SEED := 98765
const STAT_TEST_ITERATIONS := 1000  # For statistical testing

# ==================== Test State ====================

var engine  # Type: BattleEngine
var test_passed := 0
var test_failed := 0
var crit_hits_detected := 0

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize and run critical hit tests."""
	print("================================================================================")
	print("CRITICAL HIT MECHANICS TEST - Phase 1 Week 5")
	print("================================================================================")
	print()

	# Subscribe to crit event for tracking
	BattleEvents.critical_hit.connect(_on_critical_hit)

	# Run test scenarios
	_test_critical_hit_probability()
	_test_high_crit_ratio()
	_test_critical_hit_damage_multiplier()
	_test_critical_hit_stage_calculation()
	_test_deterministic_crits()

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

func _test_critical_hit_probability() -> void:
	"""Test that critical hits occur at 1/24 rate (4.17%)."""
	print("[TEST] Critical Hit Base Rate (Statistical)")
	print("--------------------------------------------------------------------------------")

	var move := _create_test_move("Test Move", "normal", 50, 100, false)
	var crit_count := 0
	var total_attempts := STAT_TEST_ITERATIONS

	for i in range(total_attempts):
		crit_hits_detected = 0

		var test_engine := BattleEngineScript.new(TEST_SEED + i)
		var test_attacker := _create_test_pokemon("pikachu", [move])
		var test_defender := _create_test_pokemon("charizard", [])

		(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

		var action := BattleActionScript.new_move_action(0)
		var pass_action := BattleActionScript.new_forfeit_action()
		(test_engine as RefCounted).call("execute_turn", action, pass_action)

		if crit_hits_detected > 0:
			crit_count += 1

	var crit_rate = float(crit_count) / float(total_attempts)
	var expected_rate = 1.0 / 24.0  # 4.17%
	var tolerance = 0.015  # 1.5% tolerance

	print("  Critical hits: %d / %d (%.2f%%)" % [
		crit_count,
		total_attempts,
		crit_rate * 100
	])
	print("  Expected rate: %.2f%% ± %.2f%%" % [expected_rate * 100, tolerance * 100])

	if abs(crit_rate - expected_rate) <= tolerance:
		print("✓ PASS: Critical hit rate within tolerance")
		test_passed += 1
	else:
		print("✗ FAIL: Critical hit rate outside tolerance")
		test_failed += 1

	print()


func _test_high_crit_ratio() -> void:
	"""Test that high crit ratio moves have increased crit rate (1/8)."""
	print("[TEST] High Crit Ratio Moves (Statistical)")
	print("--------------------------------------------------------------------------------")

	var normal_move := _create_test_move("Normal Move", "normal", 50, 100, false)
	var high_crit_move := _create_test_move("High Crit Move", "normal", 50, 100, true)

	# Test normal move
	var normal_crits := 0
	var total_attempts := STAT_TEST_ITERATIONS

	for i in range(total_attempts):
		crit_hits_detected = 0

		var test_engine := BattleEngineScript.new(TEST_SEED + i)
		var test_attacker := _create_test_pokemon("pikachu", [normal_move])
		var test_defender := _create_test_pokemon("charizard", [])

		(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

		var action := BattleActionScript.new_move_action(0)
		var pass_action := BattleActionScript.new_forfeit_action()
		(test_engine as RefCounted).call("execute_turn", action, pass_action)

		if crit_hits_detected > 0:
			normal_crits += 1

	# Test high crit ratio move
	var high_crit_crits := 0

	for i in range(total_attempts):
		crit_hits_detected = 0

		var test_engine := BattleEngineScript.new(TEST_SEED + i + 20000)
		var test_attacker := _create_test_pokemon("pikachu", [high_crit_move])
		var test_defender := _create_test_pokemon("charizard", [])

		(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

		var action := BattleActionScript.new_move_action(0)
		var pass_action := BattleActionScript.new_forfeit_action()
		(test_engine as RefCounted).call("execute_turn", action, pass_action)

		if crit_hits_detected > 0:
			high_crit_crits += 1

	var normal_rate = float(normal_crits) / float(total_attempts)
	var high_crit_rate = float(high_crit_crits) / float(total_attempts)
	var expected_high_rate = 1.0 / 8.0  # 12.5%
	var tolerance = 0.02  # 2% tolerance

	print("  Normal move crit rate: %.2f%%" % (normal_rate * 100))
	print("  High crit move crit rate: %.2f%%" % (high_crit_rate * 100))
	print("  Expected high crit rate: %.2f%% ± %.2f%%" % [expected_high_rate * 100, tolerance * 100])

	if high_crit_rate > normal_rate and abs(high_crit_rate - expected_high_rate) <= tolerance:
		print("✓ PASS: High crit ratio moves have increased crit rate")
		test_passed += 1
	else:
		print("✗ FAIL: High crit ratio did not work correctly")
		test_failed += 1

	print()


func _test_critical_hit_damage_multiplier() -> void:
	"""Test that critical hits deal 1.5x damage."""
	print("[TEST] Critical Hit Damage Multiplier")
	print("--------------------------------------------------------------------------------")

	var move := _create_test_move("Test Move", "normal", 50, 100, false)

	# Find a seed that produces a crit
	var crit_seed := TEST_SEED
	var found_crit := false

	for i in range(1000):
		crit_hits_detected = 0

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

		if crit_hits_detected > 0:
			crit_seed = TEST_SEED + i
			found_crit = true
			break

	if not found_crit:
		print("✗ FAIL: Could not find a critical hit in 1000 attempts")
		test_failed += 1
		print()
		return

	# Now test damage with and without crit using controlled calculation
	var attacker := _create_test_pokemon("pikachu", [move])
	var defender := _create_test_pokemon("charizard", [])

	# Calculate expected damage with and without crit
	var base_damage = DamageCalculatorScript.calculate_base_damage(
		attacker.level,
		move.power,
		attacker.get_stat_with_stage("atk"),
		defender.get_stat_with_stage("def")
	)

	# Non-crit damage (with 1.0 random factor)
	var non_crit_params = {
		"level": attacker.level,
		"power": move.power,
		"attack": attacker.get_stat_with_stage("atk"),
		"defense": defender.get_stat_with_stage("def"),
		"move_type": move.type,
		"attacker_types": [attacker.species.type1, attacker.species.type2],
		"is_physical": true,
		"type_effectiveness": 1.0,
		"is_critical": false,
		"random_factor": 1.0,
		"weather": "none"
	}

	# Crit damage (with 1.0 random factor)
	var crit_params = non_crit_params.duplicate()
	crit_params["is_critical"] = true

	var non_crit_damage = DamageCalculatorScript.calculate_damage(non_crit_params)
	var crit_damage = DamageCalculatorScript.calculate_damage(crit_params)

	var damage_ratio = float(crit_damage) / float(non_crit_damage)

	print("  Non-crit damage: %d" % non_crit_damage)
	print("  Crit damage: %d" % crit_damage)
	print("  Damage ratio: %.2fx" % damage_ratio)

	# Should be exactly 1.5x
	if abs(damage_ratio - 1.5) < 0.01:
		print("✓ PASS: Critical hits deal 1.5x damage")
		test_passed += 1
	else:
		print("✗ FAIL: Critical hit multiplier incorrect")
		test_failed += 1

	print()


func _test_critical_hit_stage_calculation() -> void:
	"""Test critical hit stage probabilities."""
	print("[TEST] Critical Hit Stage Probabilities")
	print("--------------------------------------------------------------------------------")

	var test_cases := [
		{"stage": 0, "expected": 1.0 / 24.0},  # 4.17%
		{"stage": 1, "expected": 1.0 / 8.0},   # 12.5%
		{"stage": 2, "expected": 0.5},         # 50%
		{"stage": 3, "expected": 1.0}          # 100%
	]

	for test_case in test_cases:
		var calculated_chance = DamageCalculatorScript.calculate_critical_chance(test_case.stage)

		print("  Stage %d: %.2f%% (expected %.2f%%)" % [
			test_case.stage,
			calculated_chance * 100,
			test_case.expected * 100
		])

		if abs(calculated_chance - test_case.expected) < 0.001:
			print("  ✓ Correct")
		else:
			print("  ✗ Incorrect")
			test_failed += 1
			return

	print("✓ PASS: All crit stage probabilities correct")
	test_passed += 1
	print()


func _test_deterministic_crits() -> void:
	"""Test that critical hits are deterministic with same seed."""
	print("[TEST] Deterministic Critical Hits")
	print("--------------------------------------------------------------------------------")

	var move := _create_test_move("Test Move", "normal", 50, 100, false)
	var results := []

	for run in range(2):
		crit_hits_detected = 0

		var test_engine := BattleEngineScript.new(TEST_SEED)
		var test_attacker := _create_test_pokemon("pikachu", [move])
		var test_defender := _create_test_pokemon("charizard", [])

		(test_engine as RefCounted).call("initialize_battle", [test_attacker], [test_defender])

		# Run 5 turns to increase chance of seeing a crit
		for i in range(5):
			var state = (test_engine as RefCounted).get("state")
			if (test_engine as RefCounted).call("is_battle_over"):
				break

			var action := BattleActionScript.new_move_action(0)
			var pass_action := BattleActionScript.new_forfeit_action()

			crit_hits_detected = 0
			(test_engine as RefCounted).call("execute_turn", action, pass_action)

			results.append(crit_hits_detected > 0)

	# Compare first 5 turns with second 5 turns
	var match_count = 0
	for i in range(5):
		if results[i] == results[i + 5]:
			match_count += 1

	if match_count == 5:
		print("✓ PASS: Critical hits are deterministic across both runs")
		test_passed += 1
	else:
		print("✗ FAIL: Critical hits differ between runs (%d/5 matches)" % match_count)
		test_failed += 1

	print()


# ==================== Event Handlers ====================

func _on_critical_hit(user, target) -> void:
	"""Track critical hits for testing."""
	crit_hits_detected += 1


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
	accuracy: int,
	high_crit: bool
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
	move.high_crit_ratio = high_crit

	return move
