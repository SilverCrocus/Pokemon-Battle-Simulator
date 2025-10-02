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

	return true

## Create an error packet
static func create_error_packet(code: ErrorCode, message: String = "") -> Dictionary:
	var error_message = message if not message.is_empty() else error_code_to_string(code)
	return create_packet(MessageType.ERROR, {
		"code": code,
		"message": error_message
	})
