extends Node

## Battle Client - Multiplayer Client
##
## Handles connection to battle server, lobby management, and receives
## authoritative battle state updates from server.

const NetworkProtocol = preload("res://scripts/networking/NetworkProtocol.gd")
const BattleActionScript = preload("res://scripts/core/BattleAction.gd")
const BattleStateScript = preload("res://scripts/core/BattleState.gd")

## Signals for UI layer
signal connected_to_server()
signal disconnected_from_server()
signal connection_failed(error: String)
signal lobby_created(lobby_id: int, player_number: int)
signal lobby_joined(lobby_id: int, player_number: int)
signal lobby_list_updated(lobbies: Array)
signal player_joined_lobby(player_id: int)
signal player_left_lobby(player_id: int)
signal ready_state_changed(player_id: int, ready: bool)
signal battle_started(battle_state: Dictionary)
signal battle_state_updated(battle_state: Dictionary)
signal battle_ended(winner: int)
signal error_received(error_code: int, message: String)

## Network peer
var _peer: ENetMultiplayerPeer = null

## Connection state
var _is_connected: bool = false

## Current lobby ID (0 if not in lobby)
var _current_lobby_id: int = 0

## Current player number (1 or 2)
var _player_number: int = 0

## Latency tracking
var _last_ping_time: float = 0.0
var _latency_ms: int = 0


func _ready() -> void:
	# Only run if this is a client build
	if OS.has_feature("dedicated_server"):
		return

	print("[BattleClient] Client ready")


func connect_to_server(ip: String, port: int = NetworkProtocol.DEFAULT_PORT) -> bool:
	"""
	Connect to battle server.

	Args:
		ip: Server IP address
		port: Server port

	Returns:
		true if connection initiated successfully
	"""
	if _is_connected:
		push_warning("[BattleClient] Already connected to server")
		return false

	_peer = ENetMultiplayerPeer.new()
	var error = _peer.create_client(ip, port)

	if error != OK:
		push_error("[BattleClient] Failed to connect to %s:%d - Error: %s" % [ip, port, error])
		connection_failed.emit("Failed to connect to server")
		return false

	multiplayer.multiplayer_peer = _peer

	# Connect signals
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	print("[BattleClient] Connecting to %s:%d..." % [ip, port])
	return true


func disconnect_from_server() -> void:
	"""Disconnect from server."""
	if not _is_connected:
		return

	if _peer:
		_peer.close()
		_peer = null

	multiplayer.multiplayer_peer = null
	_is_connected = false
	_current_lobby_id = 0
	_player_number = 0

	print("[BattleClient] Disconnected from server")
	disconnected_from_server.emit()


func create_lobby(team_data: Dictionary, lobby_name: String = "") -> void:
	"""
	Request server to create a new lobby.

	Args:
		team_data: Dictionary containing team Pokemon data
		lobby_name: Optional lobby name
	"""
	if not _is_connected:
		push_error("[BattleClient] Not connected to server")
		return

	if _current_lobby_id != 0:
		push_error("[BattleClient] Already in a lobby")
		return

	BattleServer.request_create_lobby.rpc_id(1, team_data, lobby_name)
	print("[BattleClient] Requesting lobby creation...")


func join_lobby(lobby_id: int, team_data: Dictionary) -> void:
	"""
	Request to join an existing lobby.

	Args:
		lobby_id: ID of lobby to join
		team_data: Dictionary containing team Pokemon data
	"""
	if not _is_connected:
		push_error("[BattleClient] Not connected to server")
		return

	if _current_lobby_id != 0:
		push_error("[BattleClient] Already in a lobby")
		return

	BattleServer.request_join_lobby.rpc_id(1, lobby_id, team_data)
	print("[BattleClient] Requesting to join lobby %d..." % lobby_id)


func set_ready(ready: bool) -> void:
	"""
	Set ready state in current lobby.

	Args:
		ready: Ready state
	"""
	if not _is_connected or _current_lobby_id == 0:
		push_error("[BattleClient] Not in a lobby")
		return

	BattleServer.set_player_ready.rpc_id(1, _current_lobby_id, ready)
	print("[BattleClient] Setting ready state: %s" % ready)


func submit_battle_action(action) -> void:
	"""
	Submit battle action to server.

	Args:
		action: BattleAction instance
	"""
	if not _is_connected or _current_lobby_id == 0:
		push_error("[BattleClient] Not in a battle")
		return

	var action_data = action.to_dict()
	BattleServer.submit_action.rpc_id(1, action_data)
	print("[BattleClient] Submitting action: %s" % NetworkProtocol.message_type_to_string(action.type))


func get_latency() -> int:
	"""Get current latency in milliseconds."""
	return _latency_ms


func is_connected_to_server() -> bool:
	"""Check if connected to server."""
	return _is_connected


func get_current_lobby() -> int:
	"""Get current lobby ID (0 if not in lobby)."""
	return _current_lobby_id


func get_player_number() -> int:
	"""Get player number in current lobby (1 or 2, 0 if not in lobby)."""
	return _player_number


## Signal handlers

func _on_connected_to_server() -> void:
	"""Handle successful server connection."""
	_is_connected = true
	print("[BattleClient] Connected to server")
	connected_to_server.emit()


func _on_connection_failed() -> void:
	"""Handle connection failure."""
	print("[BattleClient] Connection failed")
	_peer = null
	multiplayer.multiplayer_peer = null
	connection_failed.emit("Connection to server failed")


func _on_server_disconnected() -> void:
	"""Handle server disconnection."""
	print("[BattleClient] Server disconnected")
	_is_connected = false
	_current_lobby_id = 0
	_player_number = 0
	_peer = null
	multiplayer.multiplayer_peer = null
	disconnected_from_server.emit()


## RPC receivers (called by server)

@rpc("authority", "call_remote", "reliable")
func _rpc_send_packet(packet: Dictionary) -> void:
	"""
	Receive packet from server.

	Args:
		packet: Network packet from server
	"""
	if not NetworkProtocol.validate_packet(packet):
		push_error("[BattleClient] Received invalid packet")
		return

	var msg_type = packet["type"]
	var data = packet.get("data", {})

	match msg_type:
		NetworkProtocol.MessageType.LOBBY_LIST:
			_handle_lobby_list(data)

		NetworkProtocol.MessageType.LOBBY_CREATED:
			_handle_lobby_created(data)

		NetworkProtocol.MessageType.LOBBY_JOINED:
			_handle_lobby_joined(data)

		NetworkProtocol.MessageType.PLAYER_JOINED:
			_handle_player_joined(data)

		NetworkProtocol.MessageType.PLAYER_LEFT:
			_handle_player_left(data)

		NetworkProtocol.MessageType.READY_STATE_CHANGED:
			_handle_ready_state_changed(data)

		NetworkProtocol.MessageType.BATTLE_START:
			_handle_battle_start(data)

		NetworkProtocol.MessageType.BATTLE_STATE_UPDATE:
			_handle_battle_state_update(data)

		NetworkProtocol.MessageType.BATTLE_ENDED:
			_handle_battle_ended(data)

		NetworkProtocol.MessageType.ERROR:
			_handle_error(data)

		NetworkProtocol.MessageType.PONG:
			_handle_pong(data)

		_:
			push_warning("[BattleClient] Unknown message type: %s" % msg_type)


## Packet handlers

func _handle_lobby_list(data: Dictionary) -> void:
	"""Handle lobby list update."""
	var lobbies = data.get("lobbies", [])
	lobby_list_updated.emit(lobbies)
	print("[BattleClient] Lobby list updated: %d lobbies" % lobbies.size())


func _handle_lobby_created(data: Dictionary) -> void:
	"""Handle lobby creation confirmation."""
	_current_lobby_id = data["lobby_id"]
	_player_number = data["player_number"]
	lobby_created.emit(_current_lobby_id, _player_number)
	print("[BattleClient] Lobby %d created, you are player %d" % [_current_lobby_id, _player_number])


func _handle_lobby_joined(data: Dictionary) -> void:
	"""Handle lobby join confirmation."""
	_current_lobby_id = data["lobby_id"]
	_player_number = data["player_number"]
	lobby_joined.emit(_current_lobby_id, _player_number)
	print("[BattleClient] Joined lobby %d as player %d" % [_current_lobby_id, _player_number])


func _handle_player_joined(data: Dictionary) -> void:
	"""Handle notification of another player joining."""
	var player_id = data["player_id"]
	player_joined_lobby.emit(player_id)
	print("[BattleClient] Player %d joined lobby" % player_id)


func _handle_player_left(data: Dictionary) -> void:
	"""Handle notification of player leaving."""
	var player_id = data["player_id"]
	player_left_lobby.emit(player_id)
	print("[BattleClient] Player %d left lobby" % player_id)

	# Reset lobby state
	_current_lobby_id = 0
	_player_number = 0


func _handle_ready_state_changed(data: Dictionary) -> void:
	"""Handle ready state change notification."""
	var player_id = data["player_id"]
	var ready = data["ready"]
	ready_state_changed.emit(player_id, ready)
	print("[BattleClient] Player %d ready: %s" % [player_id, ready])


func _handle_battle_start(data: Dictionary) -> void:
	"""Handle battle start notification."""
	var battle_state = data["battle_state"]
	battle_started.emit(battle_state)
	print("[BattleClient] Battle started!")


func _handle_battle_state_update(data: Dictionary) -> void:
	"""Handle battle state update from server."""
	var battle_state = data["battle_state"]
	battle_state_updated.emit(battle_state)


func _handle_battle_ended(data: Dictionary) -> void:
	"""Handle battle end notification."""
	var winner = data["winner"]
	battle_ended.emit(winner)
	print("[BattleClient] Battle ended, winner: Player %d" % winner)


func _handle_error(data: Dictionary) -> void:
	"""Handle error from server."""
	var error_code = data["code"]
	var message = data["message"]
	error_received.emit(error_code, message)
	push_error("[BattleClient] Server error: %s" % message)


func _handle_pong(data: Dictionary) -> void:
	"""Handle ping response."""
	var current_time = Time.get_ticks_msec()
	_latency_ms = int((current_time - _last_ping_time) / 2.0)


func send_ping() -> void:
	"""Send ping to server for latency measurement."""
	if not _is_connected:
		return

	_last_ping_time = Time.get_ticks_msec()
	var ping_packet = NetworkProtocol.create_packet(NetworkProtocol.MessageType.PING, {})
	BattleServer._rpc_send_packet.rpc_id(1, ping_packet)
