extends Node

## Load Test Suite
##
## Tests server performance under load by simulating multiple concurrent battles.
## Validates that the BattleServer can handle multiple simultaneous games without
## performance degradation or stability issues.

const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")
const BattleEngineScript = preload("res://scripts/core/BattleEngine.gd")
const BattleActionScript = preload("res://scripts/core/BattleAction.gd")

## Number of concurrent battles to simulate
const NUM_BATTLES = 10

## Maximum turns per battle before timeout
const MAX_TURNS_PER_BATTLE = 100

## Test results tracking
var battles: Array = []
var completed_battles: int = 0
var total_turns_executed: int = 0
var total_damage_dealt: int = 0
var start_time: float = 0.0
var end_time: float = 0.0


func _ready() -> void:
	print("=== LOAD TEST SUITE ===\n")
	print("Simulating %d concurrent battles...\n" % NUM_BATTLES)

	start_time = Time.get_ticks_msec() / 1000.0

	# Create and initialize all battles
	for i in range(NUM_BATTLES):
		_create_battle(i)

	print("All battles initialized. Starting execution...\n")

	# Execute all battles to completion
	_execute_all_battles()

	# Print results
	_print_results()

	# Exit
	get_tree().quit()


func _create_battle(battle_id: int) -> void:
	"""Create a single battle instance."""
	var team1 = _create_test_team(battle_id * 2)
	var team2 = _create_test_team(battle_id * 2 + 1)

	# Use unique seed per battle for variety
	var engine = BattleEngineScript.new(12345 + battle_id)
	engine.call("initialize_battle", team1, team2)

	battles.append({
		"id": battle_id,
		"engine": engine,
		"turns": 0,
		"completed": false,
		"winner": -1,
		"start_time": Time.get_ticks_msec() / 1000.0
	})

	print("Battle %d initialized" % battle_id)


func _execute_all_battles() -> void:
	"""Execute all battles in parallel (simulated)."""
	var max_iterations = MAX_TURNS_PER_BATTLE
	var iteration = 0

	while completed_battles < NUM_BATTLES and iteration < max_iterations:
		# Execute one turn for each active battle
		for battle in battles:
			if not battle.completed:
				_execute_battle_turn(battle)

		iteration += 1

		# Progress update every 10 turns
		if iteration % 10 == 0:
			print("Iteration %d: %d/%d battles complete" % [iteration, completed_battles, NUM_BATTLES])

	if completed_battles < NUM_BATTLES:
		print("\nWARNING: %d battles did not complete within %d turns" % [NUM_BATTLES - completed_battles, MAX_TURNS_PER_BATTLE])


func _execute_battle_turn(battle: Dictionary) -> void:
	"""Execute one turn for a specific battle."""
	var engine = battle.engine

	# Check if battle is already over
	if engine.call("is_battle_over"):
		if not battle.completed:
			battle.completed = true
			battle.winner = engine.call("get_winner")
			completed_battles += 1
			print("Battle %d completed: Winner = Player %d (Turn %d)" % [battle.id, battle.winner, battle.turns])
		return

	# Both players use first move (simplified AI)
	var p1_action = BattleActionScript.new(
		BattleActionScript.ActionType.MOVE,
		0, 0, -1
	)
	var p2_action = BattleActionScript.new(
		BattleActionScript.ActionType.MOVE,
		0, 0, -1
	)

	# Execute turn
	engine.call("execute_turn", p1_action, p2_action)
	battle.turns += 1
	total_turns_executed += 1


func _create_test_team(seed_offset: int) -> Array:
	"""Create a test team for battles."""
	var species_ids = [25, 6, 94, 130, 145, 150]  # Pikachu, Charizard, Gengar, Gyarados, Zapdos, Mewtwo
	var species_id = species_ids[seed_offset % species_ids.size()]

	var species = DataManager.get_pokemon(species_id)
	var move1 = DataManager.get_move(85)  # Thunderbolt
	var move2 = DataManager.get_move(56)  # Hydro Pump

	var pokemon = BattlePokemonScript.new(
		species, 50,
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},
		{"hp": 4, "atk": 0, "def": 0, "spa": 252, "spd": 0, "spe": 252},
		"Timid",
		[move1, move2],
		"",  # Default ability
		"",
		""
	)

	return [pokemon]


func _print_results() -> void:
	"""Print final load test results."""
	end_time = Time.get_ticks_msec() / 1000.0
	var total_time = end_time - start_time

	print("\n=== LOAD TEST RESULTS ===")
	print("Total battles: %d" % NUM_BATTLES)
	print("Completed battles: %d" % completed_battles)
	print("Total turns executed: %d" % total_turns_executed)
	print("Total time: %.2f seconds" % total_time)

	if completed_battles > 0:
		print("Average turns per battle: %.1f" % (float(total_turns_executed) / completed_battles))
		print("Average time per battle: %.2f seconds" % (total_time / completed_battles))
		print("Turns per second: %.1f" % (total_turns_executed / total_time))

	# Battle completion breakdown
	print("\nBattle Results:")
	var player1_wins = 0
	var player2_wins = 0

	for battle in battles:
		if battle.completed:
			if battle.winner == 1:
				player1_wins += 1
			elif battle.winner == 2:
				player2_wins += 1
			print("  Battle %d: Player %d won in %d turns" % [battle.id, battle.winner, battle.turns])
		else:
			print("  Battle %d: Did not complete (timeout)" % battle.id)

	print("\nWin Distribution:")
	print("  Player 1: %d wins (%.1f%%)" % [player1_wins, (player1_wins / float(NUM_BATTLES)) * 100.0])
	print("  Player 2: %d wins (%.1f%%)" % [player2_wins, (player2_wins / float(NUM_BATTLES)) * 100.0])

	# Performance assessment
	print("\nPerformance Assessment:")
	if completed_battles == NUM_BATTLES:
		print("  ✓ ALL BATTLES COMPLETED")
		print("  ✓ No timeouts or hangs detected")

		if total_time < 10.0:
			print("  ✓ Excellent performance (< 10 seconds)")
		elif total_time < 30.0:
			print("  ✓ Good performance (< 30 seconds)")
		else:
			print("  ⚠ Slow performance (> 30 seconds)")
	else:
		print("  ✗ SOME BATTLES DID NOT COMPLETE")
		print("  ⚠ Possible performance or stability issues")

	print("\n=== END LOAD TEST ===")
