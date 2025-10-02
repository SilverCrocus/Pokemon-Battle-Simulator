extends Node

## Security Test Suite
##
## Tests security validation and exploit prevention in the networking system.
## Validates input sanitization, data validation, and anti-cheat mechanisms.

const NetworkProtocol = preload("res://scripts/networking/NetworkProtocol.gd")

var test_results: Array = []
var total_tests: int = 0
var passed_tests: int = 0


func _ready() -> void:
	print("=== SECURITY TEST SUITE ===\n")

	# Run all security tests
	_test_packet_validation()
	_test_team_validation()
	_test_action_validation()
	_test_lobby_name_validation()
	_test_string_sanitization()
	_test_timestamp_validation()
	_test_boundary_values()

	# Print results
	_print_results()

	# Exit
	get_tree().quit()


func _test_packet_validation() -> void:
	"""Test network packet validation."""
	print("Test Suite: Packet Validation")

	# Valid packet
	var valid_packet = NetworkProtocol.create_packet(
		NetworkProtocol.MessageType.PING,
		{"test": "data"}
	)
	_assert(NetworkProtocol.validate_packet(valid_packet), "Valid packet should pass")

	# Missing type
	var no_type = {"timestamp": 0.0, "version": "1.0.0", "data": {}}
	_assert(not NetworkProtocol.validate_packet(no_type), "Packet without type should fail")

	# Missing timestamp
	var no_timestamp = {"type": 0, "version": "1.0.0", "data": {}}
	_assert(not NetworkProtocol.validate_packet(no_timestamp), "Packet without timestamp should fail")

	# Missing version
	var no_version = {"type": 0, "timestamp": 0.0, "data": {}}
	_assert(not NetworkProtocol.validate_packet(no_version), "Packet without version should fail")

	# Missing data
	var no_data = {"type": 0, "timestamp": 0.0, "version": "1.0.0"}
	_assert(not NetworkProtocol.validate_packet(no_data), "Packet without data should fail")

	# Wrong version
	var wrong_version = {"type": 0, "timestamp": 0.0, "version": "0.9.0", "data": {}}
	_assert(not NetworkProtocol.validate_packet(wrong_version), "Packet with wrong version should fail")

	# Invalid type (out of enum range)
	var invalid_type = {"type": 999, "timestamp": Time.get_unix_time_from_system(), "version": "1.0.0", "data": {}}
	_assert(not NetworkProtocol.validate_packet(invalid_type), "Packet with invalid type should fail")

	# Future timestamp (beyond 5s clock skew)
	var future_packet = {
		"type": 0,
		"timestamp": Time.get_unix_time_from_system() + 10.0,
		"version": "1.0.0",
		"data": {}
	}
	_assert(not NetworkProtocol.validate_packet(future_packet), "Future timestamp should fail")

	# Old timestamp (older than 5 minutes)
	var old_packet = {
		"type": 0,
		"timestamp": Time.get_unix_time_from_system() - 400.0,
		"version": "1.0.0",
		"data": {}
	}
	_assert(not NetworkProtocol.validate_packet(old_packet), "Old timestamp should fail")

	# Not a dictionary
	_assert(not NetworkProtocol.validate_packet("not a dict"), "Non-dict should fail")
	_assert(not NetworkProtocol.validate_packet([]), "Array should fail")
	_assert(not NetworkProtocol.validate_packet(null), "Null should fail")

	print("")


func _test_team_validation() -> void:
	"""Test team data validation."""
	print("Test Suite: Team Validation")

	# Valid team
	var valid_team = {
		"pokemon": [
			{
				"species_id": 25,
				"level": 50,
				"moves": [{"id": 85}, {"id": 98}]
			}
		]
	}
	_assert(NetworkProtocol.validate_team_data(valid_team), "Valid team should pass")

	# Missing pokemon array
	var no_pokemon = {"test": "data"}
	_assert(not NetworkProtocol.validate_team_data(no_pokemon), "Team without pokemon should fail")

	# Empty team
	var empty_team = {"pokemon": []}
	_assert(not NetworkProtocol.validate_team_data(empty_team), "Empty team should fail")

	# Too many Pokemon (>6)
	var large_team = {"pokemon": []}
	for i in range(7):
		large_team["pokemon"].append({
			"species_id": 25,
			"level": 50,
			"moves": [{"id": 85}]
		})
	_assert(not NetworkProtocol.validate_team_data(large_team), "Team with >6 Pokemon should fail")

	# Invalid level (0)
	var invalid_level_zero = {
		"pokemon": [
			{
				"species_id": 25,
				"level": 0,
				"moves": [{"id": 85}]
			}
		]
	}
	_assert(not NetworkProtocol.validate_team_data(invalid_level_zero), "Level 0 should fail")

	# Invalid level (101)
	var invalid_level_high = {
		"pokemon": [
			{
				"species_id": 25,
				"level": 101,
				"moves": [{"id": 85}]
			}
		]
	}
	_assert(not NetworkProtocol.validate_team_data(invalid_level_high), "Level 101 should fail")

	# No moves
	var no_moves = {
		"pokemon": [
			{
				"species_id": 25,
				"level": 50,
				"moves": []
			}
		]
	}
	_assert(not NetworkProtocol.validate_team_data(no_moves), "Pokemon with no moves should fail")

	# Too many moves (>4)
	var too_many_moves = {
		"pokemon": [
			{
				"species_id": 25,
				"level": 50,
				"moves": [{"id": 1}, {"id": 2}, {"id": 3}, {"id": 4}, {"id": 5}]
			}
		]
	}
	_assert(not NetworkProtocol.validate_team_data(too_many_moves), "Pokemon with >4 moves should fail")

	# Not a dictionary
	_assert(not NetworkProtocol.validate_team_data("not a dict"), "Non-dict team should fail")

	print("")


func _test_action_validation() -> void:
	"""Test battle action validation."""
	print("Test Suite: Action Validation")

	# Valid move action
	var valid_move = {
		"action_type": 0,  # MOVE
		"move_index": 0,
		"target_index": 0,
		"switch_index": -1
	}
	_assert(NetworkProtocol.validate_action_data(valid_move), "Valid move action should pass")

	# Valid switch action
	var valid_switch = {
		"action_type": 1,  # SWITCH
		"move_index": 0,
		"target_index": 0,
		"switch_index": 1
	}
	_assert(NetworkProtocol.validate_action_data(valid_switch), "Valid switch action should pass")

	# Valid forfeit action
	var valid_forfeit = {
		"action_type": 2,  # FORFEIT
		"move_index": 0,
		"target_index": 0,
		"switch_index": -1
	}
	_assert(NetworkProtocol.validate_action_data(valid_forfeit), "Valid forfeit action should pass")

	# Missing action_type
	var no_type = {"move_index": 0}
	_assert(not NetworkProtocol.validate_action_data(no_type), "Action without type should fail")

	# Invalid action type
	var invalid_type = {"action_type": 99, "move_index": 0}
	_assert(not NetworkProtocol.validate_action_data(invalid_type), "Invalid action type should fail")

	# Move with invalid index (-1)
	var invalid_move_idx = {"action_type": 0, "move_index": -1}
	_assert(not NetworkProtocol.validate_action_data(invalid_move_idx), "Move index -1 should fail")

	# Move with invalid index (>3)
	var invalid_move_idx_high = {"action_type": 0, "move_index": 4}
	_assert(not NetworkProtocol.validate_action_data(invalid_move_idx_high), "Move index 4 should fail")

	# Switch with invalid index (-1)
	var invalid_switch_idx = {"action_type": 1, "switch_index": -1}
	_assert(not NetworkProtocol.validate_action_data(invalid_switch_idx), "Switch index -1 should fail")

	# Switch with invalid index (>5)
	var invalid_switch_idx_high = {"action_type": 1, "switch_index": 6}
	_assert(not NetworkProtocol.validate_action_data(invalid_switch_idx_high), "Switch index 6 should fail")

	# Not a dictionary
	_assert(not NetworkProtocol.validate_action_data("not a dict"), "Non-dict action should fail")

	print("")


func _test_lobby_name_validation() -> void:
	"""Test lobby name validation."""
	print("Test Suite: Lobby Name Validation")

	# Valid names
	_assert(NetworkProtocol.validate_lobby_name("My Lobby"), "Valid lobby name should pass")
	_assert(NetworkProtocol.validate_lobby_name("Test-Lobby_123"), "Name with hyphens and underscores should pass")
	_assert(NetworkProtocol.validate_lobby_name(""), "Empty name should pass (generates default)")

	# Invalid: too long
	var long_name = ""
	for i in range(60):
		long_name += "a"
	_assert(not NetworkProtocol.validate_lobby_name(long_name), "Name >50 chars should fail")

	# Invalid: special characters
	_assert(not NetworkProtocol.validate_lobby_name("Lobby<script>"), "Name with < should fail")
	_assert(not NetworkProtocol.validate_lobby_name("Lobby;DROP TABLE"), "Name with ; should fail")
	_assert(not NetworkProtocol.validate_lobby_name("Lobby\n\r"), "Name with newlines should fail")

	print("")


func _test_string_sanitization() -> void:
	"""Test string sanitization."""
	print("Test Suite: String Sanitization")

	# Normal string
	var normal = NetworkProtocol.sanitize_string("Hello World")
	_assert(normal == "Hello World", "Normal string should be unchanged")

	# String with control characters
	var control_char = char(0)
	var with_control = NetworkProtocol.sanitize_string("Hello" + control_char + "World")
	_assert(not with_control.contains(control_char), "Control chars should be removed")

	# String that's too long
	var long_str = ""
	for i in range(150):
		long_str += "a"
	var sanitized_long = NetworkProtocol.sanitize_string(long_str, 100)
	_assert(sanitized_long.length() == 100, "Long string should be truncated")

	# String with newlines
	var with_newlines = NetworkProtocol.sanitize_string("Line1\nLine2\rLine3")
	_assert(not with_newlines.contains("\n"), "Newlines should be removed")
	_assert(not with_newlines.contains("\r"), "Carriage returns should be removed")

	print("")


func _test_timestamp_validation() -> void:
	"""Test timestamp validation in packets."""
	print("Test Suite: Timestamp Validation")

	# Current timestamp (should pass)
	var current = {
		"type": 0,
		"timestamp": Time.get_unix_time_from_system(),
		"version": "1.0.0",
		"data": {}
	}
	_assert(NetworkProtocol.validate_packet(current), "Current timestamp should pass")

	# Slightly future (within 5s clock skew)
	var near_future = {
		"type": 0,
		"timestamp": Time.get_unix_time_from_system() + 3.0,
		"version": "1.0.0",
		"data": {}
	}
	_assert(NetworkProtocol.validate_packet(near_future), "Near future timestamp should pass")

	# Slightly old (within 5 minutes)
	var recent = {
		"type": 0,
		"timestamp": Time.get_unix_time_from_system() - 60.0,
		"version": "1.0.0",
		"data": {}
	}
	_assert(NetworkProtocol.validate_packet(recent), "Recent timestamp should pass")

	print("")


func _test_boundary_values() -> void:
	"""Test boundary values for all validations."""
	print("Test Suite: Boundary Values")

	# Team size boundaries
	var min_team = {"pokemon": [{"species_id": 1, "level": 1, "moves": [{"id": 1}]}]}
	_assert(NetworkProtocol.validate_team_data(min_team), "1 Pokemon team should pass")

	var max_team = {"pokemon": []}
	for i in range(6):
		max_team["pokemon"].append({"species_id": 1, "level": 100, "moves": [{"id": 1}]})
	_assert(NetworkProtocol.validate_team_data(max_team), "6 Pokemon team should pass")

	# Level boundaries
	var level_1 = {"pokemon": [{"species_id": 1, "level": 1, "moves": [{"id": 1}]}]}
	_assert(NetworkProtocol.validate_team_data(level_1), "Level 1 should pass")

	var level_100 = {"pokemon": [{"species_id": 1, "level": 100, "moves": [{"id": 1}]}]}
	_assert(NetworkProtocol.validate_team_data(level_100), "Level 100 should pass")

	# Move index boundaries
	var move_0 = {"action_type": 0, "move_index": 0}
	_assert(NetworkProtocol.validate_action_data(move_0), "Move index 0 should pass")

	var move_3 = {"action_type": 0, "move_index": 3}
	_assert(NetworkProtocol.validate_action_data(move_3), "Move index 3 should pass")

	# Switch index boundaries
	var switch_0 = {"action_type": 1, "switch_index": 0}
	_assert(NetworkProtocol.validate_action_data(switch_0), "Switch index 0 should pass")

	var switch_5 = {"action_type": 1, "switch_index": 5}
	_assert(NetworkProtocol.validate_action_data(switch_5), "Switch index 5 should pass")

	print("")


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
		print("\n✓ ALL SECURITY TESTS PASSED")
	else:
		print("\n✗ SOME TESTS FAILED")
		print("\nFailed tests:")
		for result in test_results:
			if not result["passed"]:
				print("  - %s" % result["name"])
