extends Node

## Test BattleClient basic functionality
##
## Note: Full client-server tests require running server,
## this test just verifies the client loads and signal connections work.

func _ready() -> void:
	print("=== BATTLE CLIENT TEST ===\n")

	# Test 1: Client autoload exists
	print("Test 1: BattleClient autoload...")
	test_client_exists()

	# Test 2: Signal connections
	print("\nTest 2: Signal connections...")
	test_signals()

	# Test 3: State getters
	print("\nTest 3: State getters...")
	test_state_getters()

	print("\n=== ALL TESTS PASSED ===")
	get_tree().quit()


func test_client_exists() -> void:
	"""Test that BattleClient autoload exists."""
	assert(has_node("/root/BattleClient"), "BattleClient autoload not found")

	var client = get_node("/root/BattleClient")
	assert(client != null, "BattleClient is null")

	# Check if running (should only run on client builds)
	var is_client = not OS.has_feature("dedicated_server")
	print("  ✓ BattleClient autoload exists")
	print("    - Is client build: %s" % is_client)
	print("    - Client connected: %s" % client.is_connected_to_server())


func test_signals() -> void:
	"""Test that all signals are defined."""
	var client = get_node("/root/BattleClient")

	var expected_signals = [
		"connected_to_server",
		"disconnected_from_server",
		"connection_failed",
		"lobby_created",
		"lobby_joined",
		"lobby_list_updated",
		"player_joined_lobby",
		"player_left_lobby",
		"ready_state_changed",
		"battle_started",
		"battle_state_updated",
		"battle_ended",
		"error_received"
	]

	for signal_name in expected_signals:
		assert(client.has_signal(signal_name), "Missing signal: %s" % signal_name)

	print("  ✓ All %d signals defined correctly" % expected_signals.size())


func test_state_getters() -> void:
	"""Test state getter methods."""
	var client = get_node("/root/BattleClient")

	# Initial state
	assert(not client.is_connected_to_server(), "Client should not be connected initially")
	assert(client.get_current_lobby() == 0, "Should not be in lobby initially")
	assert(client.get_player_number() == 0, "Player number should be 0 initially")
	assert(client.get_latency() == 0, "Latency should be 0 initially")

	print("  ✓ State getters working correctly")
	print("    - is_connected_to_server(): %s" % client.is_connected_to_server())
	print("    - get_current_lobby(): %d" % client.get_current_lobby())
	print("    - get_player_number(): %d" % client.get_player_number())
	print("    - get_latency(): %d ms" % client.get_latency())
