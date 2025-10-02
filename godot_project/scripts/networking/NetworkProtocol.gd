class_name NetworkProtocol
extends RefCounted

## Network Protocol Constants and Enums
##
## Defines all network message types, error codes, and protocol constants
## for client-server communication in multiplayer battles.

## Network message types for RPC communication
enum MessageType {
	# Connection & Lobby
	CREATE_LOBBY,           ## Client requests to create a new lobby
	JOIN_LOBBY,             ## Client requests to join existing lobby
	LEAVE_LOBBY,            ## Client leaves lobby
	LOBBY_CREATED,          ## Server confirms lobby creation
	LOBBY_JOINED,           ## Server confirms lobby join
	LOBBY_LIST,             ## Server sends list of available lobbies
	PLAYER_JOINED,          ## Server notifies lobby that player joined
	PLAYER_LEFT,            ## Server notifies lobby that player left
	READY_STATE_CHANGED,    ## Player ready state changed

	# Battle Flow
	BATTLE_START,           ## Server starts battle (both players ready)
	SUBMIT_ACTION,          ## Client submits battle action
	TURN_EXECUTED,          ## Server sends turn results
	BATTLE_STATE_UPDATE,    ## Server sends updated battle state
	BATTLE_ENDED,           ## Server declares battle winner

	# Matchmaking
	QUEUE_JOIN,             ## Client joins matchmaking queue
	QUEUE_LEAVE,            ## Client leaves matchmaking queue
	MATCH_FOUND,            ## Server found a match

	# Error & Status
	ERROR,                  ## Server sends error message
	PING,                   ## Heartbeat/latency check
	PONG,                   ## Heartbeat response
	DISCONNECT,             ## Graceful disconnect notification
}

## Error codes for network operations
enum ErrorCode {
	NONE = 0,                    ## No error
	INVALID_ACTION = 1,          ## Action is not valid for current game state
	INVALID_TEAM = 2,            ## Team composition is illegal
	LOBBY_FULL = 3,              ## Lobby already has 2 players
	LOBBY_NOT_FOUND = 4,         ## Lobby ID doesn't exist
	NOT_YOUR_TURN = 5,           ## Client submitted action out of turn
	ALREADY_IN_LOBBY = 6,        ## Client already in a lobby
	POKEMON_FAINTED = 7,         ## Tried to use fainted Pokemon
	MOVE_NO_PP = 8,              ## Move has no PP remaining
	INVALID_SWITCH_TARGET = 9,   ## Switch target is invalid (fainted/active)
	CONNECTION_LOST = 10,        ## Connection to server/client lost
	TIMEOUT = 11,                ## Action timeout (took too long)
	SERVER_FULL = 12,            ## Server at max capacity
	AUTHENTICATION_FAILED = 13,  ## Authentication error
	VERSION_MISMATCH = 14,       ## Client/server version incompatible
}

## Lobby states
enum LobbyState {
	WAITING,        ## Waiting for second player
	READY,          ## Both players present, waiting for ready
	IN_BATTLE,      ## Battle in progress
	COMPLETED,      ## Battle finished
	ABANDONED,      ## Lobby abandoned (player disconnect)
}

## Network configuration constants
const DEFAULT_PORT: int = 7777
const MAX_PLAYERS_PER_LOBBY: int = 2
const MAX_LOBBIES: int = 100
const LOBBY_TIMEOUT_SECONDS: int = 300  # 5 minutes
const ACTION_TIMEOUT_SECONDS: int = 60  # 1 minute per turn
const MAX_PACKET_SIZE: int = 65536  # 64KB
const PROTOCOL_VERSION: String = "1.0.0"

## RPC channel IDs
enum Channel {
	RELIABLE = 0,      ## Guaranteed delivery, ordered
	UNRELIABLE = 1,    ## Best effort, no guarantee
}

## Convert MessageType to string for debugging
static func message_type_to_string(type: MessageType) -> String:
	match type:
		MessageType.CREATE_LOBBY: return "CREATE_LOBBY"
		MessageType.JOIN_LOBBY: return "JOIN_LOBBY"
		MessageType.LEAVE_LOBBY: return "LEAVE_LOBBY"
		MessageType.LOBBY_CREATED: return "LOBBY_CREATED"
		MessageType.LOBBY_JOINED: return "LOBBY_JOINED"
		MessageType.LOBBY_LIST: return "LOBBY_LIST"
		MessageType.PLAYER_JOINED: return "PLAYER_JOINED"
		MessageType.PLAYER_LEFT: return "PLAYER_LEFT"
		MessageType.READY_STATE_CHANGED: return "READY_STATE_CHANGED"
		MessageType.BATTLE_START: return "BATTLE_START"
		MessageType.SUBMIT_ACTION: return "SUBMIT_ACTION"
		MessageType.TURN_EXECUTED: return "TURN_EXECUTED"
		MessageType.BATTLE_STATE_UPDATE: return "BATTLE_STATE_UPDATE"
		MessageType.BATTLE_ENDED: return "BATTLE_ENDED"
		MessageType.QUEUE_JOIN: return "QUEUE_JOIN"
		MessageType.QUEUE_LEAVE: return "QUEUE_LEAVE"
		MessageType.MATCH_FOUND: return "MATCH_FOUND"
		MessageType.ERROR: return "ERROR"
		MessageType.PING: return "PING"
		MessageType.PONG: return "PONG"
		MessageType.DISCONNECT: return "DISCONNECT"
		_: return "UNKNOWN"

## Convert ErrorCode to string for display
static func error_code_to_string(code: ErrorCode) -> String:
	match code:
		ErrorCode.NONE: return "No error"
		ErrorCode.INVALID_ACTION: return "Invalid action"
		ErrorCode.INVALID_TEAM: return "Invalid team composition"
		ErrorCode.LOBBY_FULL: return "Lobby is full"
		ErrorCode.LOBBY_NOT_FOUND: return "Lobby not found"
		ErrorCode.NOT_YOUR_TURN: return "Not your turn"
		ErrorCode.ALREADY_IN_LOBBY: return "Already in a lobby"
		ErrorCode.POKEMON_FAINTED: return "Pokemon has fainted"
		ErrorCode.MOVE_NO_PP: return "Move has no PP"
		ErrorCode.INVALID_SWITCH_TARGET: return "Invalid switch target"
		ErrorCode.CONNECTION_LOST: return "Connection lost"
		ErrorCode.TIMEOUT: return "Action timeout"
		ErrorCode.SERVER_FULL: return "Server is full"
		ErrorCode.AUTHENTICATION_FAILED: return "Authentication failed"
		ErrorCode.VERSION_MISMATCH: return "Version mismatch"
		_: return "Unknown error"

## Create a network packet with standard structure
static func create_packet(type: MessageType, data: Dictionary = {}) -> Dictionary:
	return {
		"type": type,
		"timestamp": Time.get_unix_time_from_system(),
		"version": PROTOCOL_VERSION,
		"data": data
	}

## Validate a network packet structure
static func validate_packet(packet: Variant) -> bool:
	if not packet is Dictionary:
		return false

	if not packet.has("type") or not packet.has("timestamp") or not packet.has("version"):
		return false

	if packet["version"] != PROTOCOL_VERSION:
		return false

	# Validate type is within enum range
	var type_val = packet["type"]
	if not type_val is int or type_val < 0 or type_val >= MessageType.size():
		return false

	# Validate timestamp is reasonable (not in future, not too old)
	var current_time = Time.get_unix_time_from_system()
	var packet_time = packet["timestamp"]
	if not packet_time is float and not packet_time is int:
		return false
	if packet_time > current_time + 5.0:  # Allow 5s clock skew
		return false
	if packet_time < current_time - 300.0:  # Reject packets older than 5 minutes
		return false

	# Validate data field exists and is a dictionary
	if not packet.has("data") or not packet["data"] is Dictionary:
		return false

	return true

## Validate team data structure
static func validate_team_data(team_data: Variant) -> bool:
	if not team_data is Dictionary:
		return false

	if not team_data.has("pokemon") or not team_data["pokemon"] is Array:
		return false

	var pokemon_array = team_data["pokemon"]
	if pokemon_array.size() < 1 or pokemon_array.size() > 6:
		return false

	# Validate each Pokemon entry
	for pokemon in pokemon_array:
		if not pokemon is Dictionary:
			return false
		if not pokemon.has("species_id") or not pokemon["species_id"] is int:
			return false
		if not pokemon.has("level") or not pokemon["level"] is int:
			return false
		if pokemon["level"] < 1 or pokemon["level"] > 100:
			return false
		if not pokemon.has("moves") or not pokemon["moves"] is Array:
			return false
		if pokemon["moves"].size() < 1 or pokemon["moves"].size() > 4:
			return false

	return true

## Validate battle action data
static func validate_action_data(action_data: Variant) -> bool:
	if not action_data is Dictionary:
		return false

	if not action_data.has("action_type") or not action_data["action_type"] is int:
		return false

	var action_type = action_data["action_type"]
	if action_type < 0 or action_type > 2:  # 0=MOVE, 1=SWITCH, 2=FORFEIT
		return false

	# Validate move action
	if action_type == 0:  # MOVE
		if not action_data.has("move_index") or not action_data["move_index"] is int:
			return false
		if action_data["move_index"] < 0 or action_data["move_index"] > 3:
			return false

	# Validate switch action
	if action_type == 1:  # SWITCH
		if not action_data.has("switch_index") or not action_data["switch_index"] is int:
			return false
		if action_data["switch_index"] < 0 or action_data["switch_index"] > 5:
			return false

	return true

## Validate lobby name
static func validate_lobby_name(lobby_name: String) -> bool:
	if lobby_name.is_empty():
		return true  # Empty name is allowed (server generates default)

	# Check length
	if lobby_name.length() > 50:
		return false

	# Check for invalid characters (allow alphanumeric, spaces, hyphens, underscores)
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9 _-]+$")
	if not regex.search(lobby_name):
		return false

	return true

## Sanitize string input to prevent injection attacks
static func sanitize_string(input: String, max_length: int = 100) -> String:
	# Truncate to max length
	var sanitized = input.substr(0, max_length)

	# Remove control characters and non-printable characters
	var result = ""
	for i in range(sanitized.length()):
		var c = sanitized[i]
		var code = c.unicode_at(0)
		# Allow printable ASCII and common extended characters
		if code >= 32 and code < 127:
			result += c
		elif code >= 160 and code < 65536:  # Extended Unicode
			result += c

	return result

## Create an error packet
static func create_error_packet(code: ErrorCode, message: String = "") -> Dictionary:
	var error_message = message if not message.is_empty() else error_code_to_string(code)
	return create_packet(MessageType.ERROR, {
		"code": code,
		"message": error_message
	})
