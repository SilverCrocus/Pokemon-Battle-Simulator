extends Node

## Test script for core battle classes
##
## Run this script to verify BattlePokemon, BattleAction, and BattleState classes
## are working correctly.

func _ready() -> void:
	print("=== Testing Core Battle Classes ===\n")

	test_battle_pokemon()
	test_battle_action()
	test_battle_state()

	print("\n=== All Core Class Tests Completed ===")


func test_battle_pokemon() -> void:
	print("--- Testing BattlePokemon ---")

	# Create mock PokemonData
	var pikachu_data = PokemonData.new()
	pikachu_data.name = "Pikachu"
	pikachu_data.base_hp = 35
	pikachu_data.base_atk = 55
	pikachu_data.base_def = 40
	pikachu_data.base_spa = 50
	pikachu_data.base_spd = 50
	pikachu_data.base_spe = 90
	pikachu_data.type1 = "electric"
	pikachu_data.abilities = ["Static", "Lightning Rod"]

	# Create mock moves
	var thunderbolt = MoveData.new()
	thunderbolt.name = "Thunderbolt"
	thunderbolt.power = 90
	thunderbolt.accuracy = 100
	thunderbolt.pp = 15
	thunderbolt.type = "electric"
	thunderbolt.damage_class = "special"

	var quick_attack = MoveData.new()
	quick_attack.name = "Quick Attack"
	quick_attack.power = 40
	quick_attack.accuracy = 100
	quick_attack.pp = 30
	quick_attack.type = "normal"
	quick_attack.damage_class = "physical"
	quick_attack.priority = 1

	# Create BattlePokemon
	var pikachu = BattlePokemon.new(
		pikachu_data,
		50,  # level
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},  # Perfect IVs
		{"spe": 252, "spa": 252, "hp": 4},  # EVs
		"Timid",  # nature
		[thunderbolt, quick_attack],
		"Static"
	)

	print("Created: %s (Level %d)" % [pikachu.get_display_name(), pikachu.level])
	print("HP: %d/%d" % [pikachu.current_hp, pikachu.max_hp])
	print("Stats: ATK=%d, DEF=%d, SPA=%d, SPD=%d, SPE=%d" % [
		pikachu.stats["atk"],
		pikachu.stats["def"],
		pikachu.stats["spa"],
		pikachu.stats["spd"],
		pikachu.stats["spe"]
	])
	print("Ability: %s" % pikachu.ability)
	print("Moves: %s (%d PP), %s (%d PP)" % [
		pikachu.moves[0].name, pikachu.move_pp[0],
		pikachu.moves[1].name, pikachu.move_pp[1]
	])

	# Test damage and healing
	print("\nTesting damage/healing...")
	pikachu.apply_damage(50)
	print("After 50 damage: %d/%d HP (%.1f%%)" % [
		pikachu.current_hp,
		pikachu.max_hp,
		pikachu.get_hp_percentage() * 100
	])

	pikachu.heal(25)
	print("After 25 heal: %d/%d HP" % [pikachu.current_hp, pikachu.max_hp])

	# Test status
	print("\nTesting status conditions...")
	var status_applied = pikachu.apply_status("paralysis")
	print("Applied paralysis: %s" % str(status_applied))
	print("Current status: %s" % pikachu.status)
	print("Can move: %s" % str(pikachu.can_move()))

	pikachu.clear_status()
	print("After clearing status: %s" % pikachu.status)

	# Test stat stages
	print("\nTesting stat stages...")
	var atk_change = pikachu.modify_stat_stage("atk", 2)
	print("Modified ATK by +2 (actual change: %+d)" % atk_change)
	print("Base ATK: %d, With stage: %d" % [
		pikachu.stats["atk"],
		pikachu.get_stat_with_stage("atk")
	])

	# Test move usage
	print("\nTesting move usage...")
	print("Can use Thunderbolt: %s" % str(pikachu.can_use_move(0)))
	pikachu.use_move(0)
	print("After using Thunderbolt: %d PP remaining" % pikachu.move_pp[0])

	print("BattlePokemon tests passed!\n")


func test_battle_action() -> void:
	print("--- Testing BattleAction ---")

	# Test MOVE action
	var move_action = BattleAction.new_move_action(0, 0)
	print("Created move action: %s" % move_action.get_description())
	print("Is move: %s" % str(move_action.is_move()))

	# Test SWITCH action
	var switch_action = BattleAction.new_switch_action(2)
	print("Created switch action: %s" % switch_action.get_description())
	print("Is switch: %s" % str(switch_action.is_switch()))

	# Test FORFEIT action
	var forfeit_action = BattleAction.new_forfeit_action()
	print("Created forfeit action: %s" % forfeit_action.get_description())
	print("Is forfeit: %s" % str(forfeit_action.is_forfeit()))

	# Test serialization
	var action_dict = move_action.to_dict()
	var restored_action = BattleAction.from_dict(action_dict)
	print("Serialization test: %s" % str(move_action.equals(restored_action)))

	print("BattleAction tests passed!\n")


func test_battle_state() -> void:
	print("--- Testing BattleState ---")

	# Create mock Pokemon for teams
	var team1_pokemon = _create_test_team("Team1")
	var team2_pokemon = _create_test_team("Team2")

	# Create battle state
	var state = BattleState.new(12345)  # Fixed seed for testing
	state.set_team1(team1_pokemon)
	state.set_team2(team2_pokemon)
	state.begin_battle()

	print("Battle started!")
	print("Turn: %d" % state.turn_number)
	print("Player 1 active: %s" % state.get_active_pokemon(1).get_display_name())
	print("Player 2 active: %s" % state.get_active_pokemon(2).get_display_name())

	# Test weather
	print("\nTesting weather...")
	state.set_weather("rain", 5)
	print("Set weather to: %s (turns remaining: %d)" % [state.weather, state.weather_turns_remaining])

	# Test terrain
	print("\nTesting terrain...")
	state.set_terrain("electric", 5)
	print("Set terrain to: %s (turns remaining: %d)" % [state.terrain, state.terrain_turns_remaining])

	# Test switching
	print("\nTesting Pokemon switching...")
	print("Can Player 1 switch: %s" % str(state.can_switch(1)))
	var inactive = state.get_inactive_pokemon(1)
	print("Player 1 inactive Pokemon: %d" % inactive.size())

	if state.can_switch(1):
		state.switch_pokemon(1, 1)
		print("Switched to: %s" % state.get_active_pokemon(1).get_display_name())

	# Test turn advancement
	print("\nTesting turn advancement...")
	state.advance_turn()
	print("Turn: %d" % state.turn_number)
	print("Weather turns remaining: %d" % state.weather_turns_remaining)
	print("Terrain turns remaining: %d" % state.terrain_turns_remaining)

	# Test battle summary
	print("\nBattle summary:")
	var summary = state.get_battle_summary()
	for key in summary:
		print("  %s: %s" % [key, str(summary[key])])

	# Test battle end conditions
	print("\nTesting battle end conditions...")
	# Faint all of team2's Pokemon
	for pokemon in state.team2:
		pokemon.apply_damage(pokemon.max_hp)

	state.check_battle_end()
	print("Is battle over: %s" % str(state.is_battle_over()))
	print("Winner: Player %d" % state.get_winner())
	print("Battle status: %s" % summary.status)

	print("BattleState tests passed!\n")


func _create_test_team(prefix: String) -> Array:
	"""Create a test team of 3 Pokemon."""
	var team = []

	for i in range(3):
		# Create simple species data
		var species = PokemonData.new()
		species.name = "%s_Pokemon%d" % [prefix, i + 1]
		species.base_hp = 50 + (i * 10)
		species.base_atk = 50
		species.base_def = 50
		species.base_spa = 50
		species.base_spd = 50
		species.base_spe = 50
		species.type1 = "normal"
		species.abilities = ["TestAbility"]

		# Create a simple move
		var move = MoveData.new()
		move.name = "Tackle"
		move.power = 40
		move.accuracy = 100
		move.pp = 35
		move.type = "normal"
		move.damage_class = "physical"

		# Create BattlePokemon
		var pokemon = BattlePokemon.new(
			species,
			50,
			{},  # Default IVs
			{},  # No EVs
			"Hardy",
			[move],
			"TestAbility"
		)

		team.append(pokemon)

	return team
