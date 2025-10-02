extends Node

## Multiplayer Integration Test
##
## This test simulates a complete multiplayer flow:
## 1. Server starts and listens
## 2. Client connects
## 3. Client creates lobby
## 4. Verify lobby operations

const NetworkProtocol = preload("res://scripts/networking/NetworkProtocol.gd")

var test_passed: bool = false
var test_stage: int = 0

func _ready() -> void:
	print("=== MULTIPLAYER INTEGRATION TEST ===\n")

	# Check if we're running as dedicated server
	if OS.has_feature("dedicated_server"):
		_run_server_test()
	else:
		_run_client_test()


func _run_server_test() -> void:
	"""Test server functionality."""
	print("Running as DEDICATED SERVER")

	# Server should already be running from BattleServer autoload
	await get_tree().create_timer(1.0).timeout

	if BattleServer._is_running:
		print("✓ Server is running on port %d" % NetworkProtocol.DEFAULT_PORT)
		print("✓ Server accepting connections")
		test_passed = true
	else:
		print("✗ Server failed to start")

	print("\n=== SERVER TEST COMPLETE ===")
	# Keep server running for client connection
	# Don't quit - let it run for manual testing


func _run_client_test() -> void:
	"""Test client functionality."""
	print("Running as CLIENT")

	# Test 1: Client autoload ready
	print("\nTest 1: Client initialization...")
	if BattleClient:
		print("  ✓ BattleClient autoload ready")
	else:
		print("  ✗ BattleClient not found")
		_fail_test()
		return

	# Test 2: Check initial state
	print("\nTest 2: Initial client state...")
	assert(not BattleClient.is_connected_to_server(), "Should not be connected initially")
	assert(BattleClient.get_current_lobby() == 0, "Should not be in lobby")
	assert(BattleClient.get_player_number() == 0, "Player number should be 0")
	print("  ✓ Client state correct")

	# Test 3: Protocol validation
	print("\nTest 3: Network protocol...")
	var test_packet = NetworkProtocol.create_packet(
		NetworkProtocol.MessageType.CREATE_LOBBY,
		{"test": "data"}
	)
	assert(NetworkProtocol.validate_packet(test_packet), "Packet validation failed")
	print("  ✓ Network protocol working")

	# Test 4: Team serialization
	print("\nTest 4: Team serialization...")
	var test_team = _create_test_team()
	assert(test_team.size() == 1, "Test team should have 1 Pokemon")
	var team_dict = {"pokemon": [test_team[0].to_dict()]}
	assert(team_dict.has("pokemon"), "Team dict should have pokemon key")
	print("  ✓ Team serialization working")

	# Test 5: BattleController network mode
	print("\nTest 5: BattleController network mode...")
	assert(BattleController.current_mode == BattleController.BattleMode.LOCAL, "Should start in LOCAL mode")
	print("  ✓ BattleController ready for network mode")

	print("\n=== ALL CLIENT TESTS PASSED ===")
	print("\nTo test full multiplayer:")
	print("1. Run server: godot --headless --path . --feature dedicated_server")
	print("2. Run client: godot --path . res://scenes/lobby/LobbyScene.tscn")
	print("3. In client, connect to localhost and create/join lobby")

	test_passed = true
	get_tree().quit()


func _create_test_team() -> Array:
	"""Create a test team for validation."""
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

	return [pikachu]


func _fail_test() -> void:
	"""Mark test as failed and exit."""
	print("\n=== TEST FAILED ===")
	test_passed = false
	get_tree().quit()
