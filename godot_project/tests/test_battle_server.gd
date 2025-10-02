extends Node

## Test BattleServer basic functionality
##
## Note: Full networking tests require multiple instances,
## this test just verifies the server loads and basic validation works.

const BattleActionScript = preload("res://scripts/core/BattleAction.gd")

func _ready() -> void:
	print("=== BATTLE SERVER TEST ===\n")

	# Test 1: Server autoload exists
	print("Test 1: BattleServer autoload...")
	test_server_exists()

	# Test 2: Team validation
	print("\nTest 2: Team validation...")
	test_team_validation()

	# Test 3: Lobby list
	print("\nTest 3: Lobby list generation...")
	test_lobby_list()

	print("\n=== ALL TESTS PASSED ===")
	get_tree().quit()


func test_server_exists() -> void:
	"""Test that BattleServer autoload exists and is configured."""
	assert(has_node("/root/BattleServer"), "BattleServer autoload not found")

	var server = get_node("/root/BattleServer")
	assert(server != null, "BattleServer is null")

	# Check if running (should only run on dedicated_server feature)
	var is_server = OS.has_feature("dedicated_server")
	print("  ✓ BattleServer autoload exists")
	print("    - Is dedicated server: %s" % is_server)
	print("    - Server running: %s" % server._is_running)


func test_team_validation() -> void:
	"""Test team validation logic."""
	var server = get_node("/root/BattleServer")

	# Test valid team
	var species = DataManager.get_pokemon(25)  # Pikachu
	var move1 = DataManager.get_move(85)
	var move2 = DataManager.get_move(98)

	var pikachu = BattlePokemon.new(
		species, 50,
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},
		{"hp": 4, "atk": 0, "def": 0, "spa": 252, "spd": 0, "spe": 252},
		"Timid",
		[move1, move2],
		"",
		"",
		"TestPikachu"
	)

	var valid_team_data = {
		"pokemon": [pikachu.to_dict()]
	}

	var team = server._validate_and_create_team(valid_team_data)
	assert(team.size() == 1, "Valid team should create 1 Pokemon")
	assert(team[0].species.pokemon_id == 25, "Pokemon species mismatch")

	# Test invalid team (no pokemon key)
	var invalid_team_data = {"foo": "bar"}
	var invalid_team = server._validate_and_create_team(invalid_team_data)
	assert(invalid_team.is_empty(), "Invalid team should return empty array")

	# Test empty team
	var empty_team_data = {"pokemon": []}
	var empty_team = server._validate_and_create_team(empty_team_data)
	assert(empty_team.is_empty(), "Empty team should return empty array")

	print("  ✓ Team validation working correctly")
	print("    - Valid team: 1 Pokemon created")
	print("    - Invalid team: Rejected")
	print("    - Empty team: Rejected")


func test_lobby_list() -> void:
	"""Test lobby list generation."""
	var server = get_node("/root/BattleServer")

	# Get initial lobby list (should be empty)
	var lobby_list = server._get_lobby_list()
	assert(lobby_list is Array, "Lobby list should be an Array")

	print("  ✓ Lobby list generation working")
	print("    - Lobby count: %d" % lobby_list.size())
	print("    - Lobby list type: %s" % typeof(lobby_list))
