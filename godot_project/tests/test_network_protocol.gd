extends Node

## Test NetworkProtocol constants, enums, and utility functions

const NetworkProtocol = preload("res://scripts/networking/NetworkProtocol.gd")

func _ready() -> void:
	print("=== NETWORK PROTOCOL TEST ===\n")

	# Test 1: Message type conversion
	print("Test 1: Message type to string conversion...")
	test_message_type_conversion()

	# Test 2: Error code conversion
	print("\nTest 2: Error code to string conversion...")
	test_error_code_conversion()

	# Test 3: Packet creation
	print("\nTest 3: Packet creation and validation...")
	test_packet_creation()

	# Test 4: Error packet creation
	print("\nTest 4: Error packet creation...")
	test_error_packet()

	print("\n=== ALL TESTS PASSED ===")
	get_tree().quit()


func test_message_type_conversion() -> void:
	"""Test message type enum to string conversion."""
	var create_lobby_str = NetworkProtocol.message_type_to_string(NetworkProtocol.MessageType.CREATE_LOBBY)
	assert(create_lobby_str == "CREATE_LOBBY", "CREATE_LOBBY conversion failed")

	var battle_start_str = NetworkProtocol.message_type_to_string(NetworkProtocol.MessageType.BATTLE_START)
	assert(battle_start_str == "BATTLE_START", "BATTLE_START conversion failed")

	var error_str = NetworkProtocol.message_type_to_string(NetworkProtocol.MessageType.ERROR)
	assert(error_str == "ERROR", "ERROR conversion failed")

	print("  ✓ Message type conversion successful")
	print("    - CREATE_LOBBY → %s" % create_lobby_str)
	print("    - BATTLE_START → %s" % battle_start_str)
	print("    - ERROR → %s" % error_str)


func test_error_code_conversion() -> void:
	"""Test error code enum to string conversion."""
	var invalid_action_str = NetworkProtocol.error_code_to_string(NetworkProtocol.ErrorCode.INVALID_ACTION)
	assert(invalid_action_str == "Invalid action", "INVALID_ACTION conversion failed")

	var lobby_full_str = NetworkProtocol.error_code_to_string(NetworkProtocol.ErrorCode.LOBBY_FULL)
	assert(lobby_full_str == "Lobby is full", "LOBBY_FULL conversion failed")

	var timeout_str = NetworkProtocol.error_code_to_string(NetworkProtocol.ErrorCode.TIMEOUT)
	assert(timeout_str == "Action timeout", "TIMEOUT conversion failed")

	print("  ✓ Error code conversion successful")
	print("    - INVALID_ACTION → %s" % invalid_action_str)
	print("    - LOBBY_FULL → %s" % lobby_full_str)
	print("    - TIMEOUT → %s" % timeout_str)


func test_packet_creation() -> void:
	"""Test packet creation and validation."""
	# Create packet
	var packet = NetworkProtocol.create_packet(
		NetworkProtocol.MessageType.CREATE_LOBBY,
		{"team": [], "lobby_name": "Test Lobby"}
	)

	# Verify structure
	assert(packet.has("type"), "Packet missing 'type' field")
	assert(packet.has("timestamp"), "Packet missing 'timestamp' field")
	assert(packet.has("version"), "Packet missing 'version' field")
	assert(packet.has("data"), "Packet missing 'data' field")

	# Validate packet
	assert(NetworkProtocol.validate_packet(packet), "Packet validation failed")

	# Verify values
	assert(packet["type"] == NetworkProtocol.MessageType.CREATE_LOBBY, "Packet type mismatch")
	assert(packet["version"] == NetworkProtocol.PROTOCOL_VERSION, "Packet version mismatch")
	assert(packet["data"]["lobby_name"] == "Test Lobby", "Packet data mismatch")

	print("  ✓ Packet creation and validation successful")
	print("    - Type: %s" % NetworkProtocol.message_type_to_string(packet["type"]))
	print("    - Version: %s" % packet["version"])
	print("    - Data keys: %s" % [packet["data"].keys()])

	# Test invalid packet
	var invalid_packet = {"foo": "bar"}
	assert(not NetworkProtocol.validate_packet(invalid_packet), "Invalid packet passed validation")
	print("    - Invalid packet correctly rejected")


func test_error_packet() -> void:
	"""Test error packet creation."""
	var error_packet = NetworkProtocol.create_error_packet(
		NetworkProtocol.ErrorCode.INVALID_TEAM,
		"Team contains illegal Pokemon"
	)

	assert(error_packet["type"] == NetworkProtocol.MessageType.ERROR, "Error packet type mismatch")
	assert(error_packet["data"]["code"] == NetworkProtocol.ErrorCode.INVALID_TEAM, "Error code mismatch")
	assert(error_packet["data"]["message"] == "Team contains illegal Pokemon", "Error message mismatch")

	# Test error packet with default message
	var error_packet2 = NetworkProtocol.create_error_packet(NetworkProtocol.ErrorCode.LOBBY_FULL)
	assert(error_packet2["data"]["message"] == "Lobby is full", "Default error message incorrect")

	print("  ✓ Error packet creation successful")
	print("    - Error code: %s" % NetworkProtocol.error_code_to_string(error_packet["data"]["code"]))
	print("    - Error message: %s" % error_packet["data"]["message"])
	print("    - Default message works: %s" % error_packet2["data"]["message"])
