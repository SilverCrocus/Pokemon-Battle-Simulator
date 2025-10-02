extends Node

## Test serialization round-trip for BattleState and BattlePokemon
##
## This test creates a battle state, serializes it to a dictionary,
## deserializes it back, and verifies all data is preserved.

const BattleStateScript = preload("res://scripts/core/BattleState.gd")
const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")

func _ready() -> void:
	print("=== SERIALIZATION ROUND-TRIP TEST ===\n")

	# Test 1: BattlePokemon serialization
	print("Test 1: BattlePokemon serialization...")
	test_pokemon_serialization()

	# Test 2: BattleState serialization
	print("\nTest 2: BattleState serialization...")
	test_state_serialization()

	print("\n=== ALL TESTS PASSED ===")
	get_tree().quit()


func test_pokemon_serialization() -> void:
	"""Test BattlePokemon.to_dict() and from_dict()."""
	# Create a Pokemon
	var species = DataManager.get_pokemon(25)  # Pikachu
	var move1 = DataManager.get_move(85)  # Thunderbolt
	var move2 = DataManager.get_move(98)  # Quick Attack
	var move3 = DataManager.get_move(86)  # Thunder Wave
	var move4 = DataManager.get_move(98)  # Quick Attack

	var original_pokemon = BattlePokemonScript.new(
		species,
		50,  # level
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},  # IVs
		{"hp": 4, "atk": 0, "def": 0, "spa": 252, "spd": 0, "spe": 252},  # EVs (complete)
		"Timid",  # nature
		[move1, move2, move3, move4],
		"",  # ability (empty = use default)
		"light-ball",  # item
		"Sparky"  # nickname
	)

	# Damage it and apply status
	original_pokemon.current_hp = 80
	original_pokemon.status = "paralysis"
	original_pokemon.stat_stages["atk"] = 2
	original_pokemon.stat_stages["def"] = -1

	# Serialize
	var data = original_pokemon.to_dict()
	print("  Serialized Pokemon data keys: %s" % [data.keys()])

	# Deserialize
	var restored_pokemon = BattlePokemonScript.from_dict(data)

	# Verify
	assert(restored_pokemon.species.pokemon_id == original_pokemon.species.pokemon_id, "Species ID mismatch")
	assert(restored_pokemon.level == original_pokemon.level, "Level mismatch")
	assert(restored_pokemon.current_hp == original_pokemon.current_hp, "HP mismatch")
	assert(restored_pokemon.status == original_pokemon.status, "Status mismatch")
	assert(restored_pokemon.stat_stages["atk"] == 2, "Atk stage mismatch")
	assert(restored_pokemon.stat_stages["def"] == -1, "Def stage mismatch")
	assert(restored_pokemon.ability == original_pokemon.ability, "Ability mismatch")
	assert(restored_pokemon.item == original_pokemon.item, "Item mismatch")
	assert(restored_pokemon.nickname == original_pokemon.nickname, "Nickname mismatch")
	assert(restored_pokemon.moves.size() == original_pokemon.moves.size(), "Move count mismatch")

	print("  ✓ Pokemon serialization successful")
	print("    - Species: %s" % restored_pokemon.species.name)
	print("    - Level: %d" % restored_pokemon.level)
	print("    - HP: %d/%d" % [restored_pokemon.current_hp, restored_pokemon.max_hp])
	print("    - Status: %s" % restored_pokemon.status)
	print("    - Stat stages preserved: ATK+2, DEF-1")


func test_state_serialization() -> void:
	"""Test BattleState.to_dict() and from_dict()."""
	# Create battle state with teams
	var state = BattleStateScript.new(12345)  # Fixed seed

	# Create team 1
	var team1_pokemon1 = _create_test_pokemon(25, 50, "Timid", "Sparky")  # Pikachu
	var team1_pokemon2 = _create_test_pokemon(6, 50, "Adamant", "Blaze")  # Charizard

	# Create team 2
	var team2_pokemon1 = _create_test_pokemon(9, 50, "Bold", "Shellshock")  # Blastoise
	var team2_pokemon2 = _create_test_pokemon(150, 50, "Modest", "MewTwo")  # Mewtwo

	state.set_team1([team1_pokemon1, team1_pokemon2])
	state.set_team2([team2_pokemon1, team2_pokemon2])
	state.begin_battle()

	# Modify state
	state.turn_number = 5
	state.set_weather("rain", 3)
	state.set_terrain("electric", 2)
	state.get_active_pokemon(1).current_hp = 50

	# Serialize
	var data = state.to_dict()
	print("  Serialized BattleState data keys: %s" % [data.keys()])
	print("  Team 1 size: %d" % data["team1"].size())
	print("  Team 2 size: %d" % data["team2"].size())

	# Deserialize
	var restored_state = BattleStateScript.from_dict(data)

	# Verify basic state
	assert(restored_state.turn_number == state.turn_number, "Turn number mismatch")
	assert(restored_state.weather == state.weather, "Weather mismatch")
	assert(restored_state.weather_turns_remaining == state.weather_turns_remaining, "Weather turns mismatch")
	assert(restored_state.terrain == state.terrain, "Terrain mismatch")
	assert(restored_state.terrain_turns_remaining == state.terrain_turns_remaining, "Terrain turns mismatch")
	assert(restored_state.rng_seed == state.rng_seed, "RNG seed mismatch")
	assert(restored_state.battle_status == state.battle_status, "Battle status mismatch")

	# Verify teams
	assert(restored_state.team1.size() == state.team1.size(), "Team 1 size mismatch")
	assert(restored_state.team2.size() == state.team2.size(), "Team 2 size mismatch")

	# Verify active Pokemon
	var restored_active = restored_state.get_active_pokemon(1)
	assert(restored_active.current_hp == 50, "Active Pokemon HP not restored")
	assert(restored_active.species.pokemon_id == 25, "Active Pokemon species mismatch")

	print("  ✓ BattleState serialization successful")
	print("    - Turn: %d" % restored_state.turn_number)
	print("    - Weather: %s (%d turns)" % [restored_state.weather, restored_state.weather_turns_remaining])
	print("    - Terrain: %s (%d turns)" % [restored_state.terrain, restored_state.terrain_turns_remaining])
	print("    - RNG Seed: %d" % restored_state.rng_seed)
	print("    - Team 1: %d Pokemon" % restored_state.team1.size())
	print("    - Team 2: %d Pokemon" % restored_state.team2.size())
	print("    - Active P1 HP: %d/%d" % [restored_active.current_hp, restored_active.max_hp])


func _create_test_pokemon(species_id: int, level: int, nature: String, nickname: String) -> BattlePokemon:
	"""Helper to create a test Pokemon."""
	var species = DataManager.get_pokemon(species_id)
	var move1 = DataManager.get_move(1)  # First move
	var move2 = DataManager.get_move(2)  # Second move

	return BattlePokemonScript.new(
		species,
		level,
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},
		{"hp": 252, "atk": 252, "def": 4, "spa": 0, "spd": 0, "spe": 0},  # Complete EVs
		nature,
		[move1, move2],
		species.abilities[0] if species.abilities.size() > 0 else "",
		"",
		nickname
	)
