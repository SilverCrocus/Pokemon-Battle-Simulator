extends Node

## Battle Server - Server-Authoritative Multiplayer
##
## Manages peer connections, lobbies, and server-side battle execution.
## All game logic runs on the server to prevent cheating.

const NetworkProtocol = preload("res://scripts/networking/NetworkProtocol.gd")
const BattleEngineScript = preload("res://scripts/core/BattleEngine.gd")
const BattleActionScript = preload("res://scripts/core/BattleAction.gd")
const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")

## Lobby data structure
class Lobby:
	var id: int
	var state: NetworkProtocol.LobbyState
	var player1_id: int = -1
	var player2_id: int = -1
	var player1_team: Array = []  # Array of BattlePokemon
	var player2_team: Array = []  # Array of BattlePokemon
	var player1_ready: bool = false
	var player2_ready: bool = false
	var battle_engine = null  # BattleEngine instance
	var created_at: float = 0.0
	var last_activity: float = 0.0

	func _init(lobby_id: int):
		id = lobby_id
		state = NetworkProtocol.LobbyState.WAITING
		created_at = Time.get_unix_time_from_system()
		last_activity = created_at

	func is_full() -> bool:
		return player1_id != -1 and player2_id != -1

	func has_player(peer_id: int) -> bool:
		return player1_id == peer_id or player2_id == peer_id

	func get_player_number(peer_id: int) -> int:
		if player1_id == peer_id:
			return 1
		elif player2_id == peer_id:
			return 2
		return 0

	func update_activity() -> void:
		last_activity = Time.get_unix_time_from_system()

	func is_timed_out() -> bool:
		var elapsed = Time.get_unix_time_from_system() - last_activity
		return elapsed > NetworkProtocol.LOBBY_TIMEOUT_SECONDS

## Active lobbies (lobby_id -> Lobby)
var _lobbies: Dictionary = {}

## Next lobby ID
var _next_lobby_id: int = 1

## Peer to lobby mapping (peer_id -> lobby_id)
var _peer_to_lobby: Dictionary = {}

## Network peer
var _peer: ENetMultiplayerPeer = null

## Is server running
var _is_running: bool = false


func _ready() -> void:
	# Only run if this is a dedicated server
	if not OS.has_feature("dedicated_server"):
		return

	print("[BattleServer] Initializing dedicated server...")
	setup_network(NetworkProtocol.DEFAULT_PORT)


func setup_network(port: int) -> void:
	"""
	Setup server network and start listening for connections.

	Args:
		port: Port number to listen on
	"""
	_peer = ENetMultiplayerPeer.new()
	var error = _peer.create_server(port, NetworkProtocol.MAX_LOBBIES * 2)

	if error != OK:
		push_error("[BattleServer] Failed to create server on port %d: %s" % [port, error])
		return

	multiplayer.multiplayer_peer = _peer
	_is_running = true

	# Connect signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("[BattleServer] Server started on port %d" % port)


func _on_peer_connected(peer_id: int) -> void:
	"""Handle new peer connection."""
	print("[BattleServer] Peer connected: %d" % peer_id)

	# Send welcome message
	var welcome_packet = NetworkProtocol.create_packet(
		NetworkProtocol.MessageType.LOBBY_LIST,
		{"lobbies": _get_lobby_list()}
	)
	_send_to_peer(peer_id, welcome_packet)


func _on_peer_disconnected(peer_id: int) -> void:
	"""Handle peer disconnection."""
	print("[BattleServer] Peer disconnected: %d" % peer_id)

	# Check if peer was in a lobby
	if _peer_to_lobby.has(peer_id):
		var lobby_id = _peer_to_lobby[peer_id]
		var lobby = _lobbies.get(lobby_id)

		if lobby:
			_handle_player_leave(lobby, peer_id)

		_peer_to_lobby.erase(peer_id)


@rpc("any_peer", "call_remote", "reliable")
func request_create_lobby(team_data: Dictionary, lobby_name: String = "") -> void:
	"""
	Client requests to create a new lobby.

	Args:
		team_data: Dictionary containing team Pokemon data
		lobby_name: Optional lobby name
	"""
	var peer_id = multiplayer.get_remote_sender_id()

	# Check if player already in a lobby
	if _peer_to_lobby.has(peer_id):
		_send_error(peer_id, NetworkProtocol.ErrorCode.ALREADY_IN_LOBBY)
		return

	# Validate team
	var team = _validate_and_create_team(team_data)
	if team.is_empty():
		_send_error(peer_id, NetworkProtocol.ErrorCode.INVALID_TEAM)
		return

	# Create lobby
	var lobby_id = _create_lobby(peer_id, team)

	# Send confirmation
	var response = NetworkProtocol.create_packet(
		NetworkProtocol.MessageType.LOBBY_CREATED,
		{"lobby_id": lobby_id, "player_number": 1}
	)
	_send_to_peer(peer_id, response)

	print("[BattleServer] Lobby %d created by peer %d" % [lobby_id, peer_id])


@rpc("any_peer", "call_remote", "reliable")
func request_join_lobby(lobby_id: int, team_data: Dictionary) -> void:
	"""
	Client requests to join an existing lobby.

	Args:
		lobby_id: ID of lobby to join
		team_data: Dictionary containing team Pokemon data
	"""
	var peer_id = multiplayer.get_remote_sender_id()

	# Check if player already in a lobby
	if _peer_to_lobby.has(peer_id):
		_send_error(peer_id, NetworkProtocol.ErrorCode.ALREADY_IN_LOBBY)
		return

	# Check if lobby exists
	if not _lobbies.has(lobby_id):
		_send_error(peer_id, NetworkProtocol.ErrorCode.LOBBY_NOT_FOUND)
		return

	var lobby: Lobby = _lobbies[lobby_id]

	# Check if lobby is full
	if lobby.is_full():
		_send_error(peer_id, NetworkProtocol.ErrorCode.LOBBY_FULL)
		return

	# Validate team
	var team = _validate_and_create_team(team_data)
	if team.is_empty():
		_send_error(peer_id, NetworkProtocol.ErrorCode.INVALID_TEAM)
		return

	# Add player to lobby
	lobby.player2_id = peer_id
	lobby.player2_team = team
	lobby.state = NetworkProtocol.LobbyState.READY
	lobby.update_activity()

	_peer_to_lobby[peer_id] = lobby_id

	# Notify both players
	var join_response = NetworkProtocol.create_packet(
		NetworkProtocol.MessageType.LOBBY_JOINED,
		{"lobby_id": lobby_id, "player_number": 2}
	)
	_send_to_peer(peer_id, join_response)

	var player_joined = NetworkProtocol.create_packet(
		NetworkProtocol.MessageType.PLAYER_JOINED,
		{"lobby_id": lobby_id, "player_id": peer_id}
	)
	_send_to_peer(lobby.player1_id, player_joined)

	print("[BattleServer] Peer %d joined lobby %d" % [peer_id, lobby_id])


@rpc("any_peer", "call_remote", "reliable")
func set_player_ready(lobby_id: int, ready: bool) -> void:
	"""
	Client sets their ready state.

	Args:
		lobby_id: Lobby ID
		ready: Ready state
	"""
	var peer_id = multiplayer.get_remote_sender_id()

	if not _lobbies.has(lobby_id):
		_send_error(peer_id, NetworkProtocol.ErrorCode.LOBBY_NOT_FOUND)
		return

	var lobby: Lobby = _lobbies[lobby_id]

	if not lobby.has_player(peer_id):
		return

	# Update ready state
	if lobby.player1_id == peer_id:
		lobby.player1_ready = ready
	elif lobby.player2_id == peer_id:
		lobby.player2_ready = ready

	lobby.update_activity()

	# Broadcast ready state change
	var ready_packet = NetworkProtocol.create_packet(
		NetworkProtocol.MessageType.READY_STATE_CHANGED,
		{
			"lobby_id": lobby_id,
			"player_id": peer_id,
			"ready": ready
		}
	)
	_broadcast_to_lobby(lobby, ready_packet)

	# Start battle if both ready
	if lobby.player1_ready and lobby.player2_ready:
		_start_battle(lobby)


@rpc("any_peer", "call_remote", "reliable")
func submit_action(action_data: Dictionary) -> void:
	"""
	Client submits a battle action.

	Args:
		action_data: Serialized BattleAction data
	"""
	var peer_id = multiplayer.get_remote_sender_id()

	if not _peer_to_lobby.has(peer_id):
		_send_error(peer_id, NetworkProtocol.ErrorCode.LOBBY_NOT_FOUND)
		return

	var lobby_id = _peer_to_lobby[peer_id]
	var lobby: Lobby = _lobbies[lobby_id]

	if lobby.state != NetworkProtocol.LobbyState.IN_BATTLE:
		return

	if not lobby.battle_engine:
		return

	# Create action from data
	var action = BattleActionScript.from_dict(action_data)
	var player_num = lobby.get_player_number(peer_id)

	# Validate action
	if not _validate_action(lobby, player_num, action):
		_send_error(peer_id, NetworkProtocol.ErrorCode.INVALID_ACTION)
		return

	# Store action and check if we have both
	if player_num == 1:
		lobby.battle_engine._pending_player1_action = action
	else:
		lobby.battle_engine._pending_player2_action = action

	# Execute turn if both players submitted
	if lobby.battle_engine._pending_player1_action and lobby.battle_engine._pending_player2_action:
		_execute_turn(lobby)


func _create_lobby(peer_id: int, team: Array) -> int:
	"""Create a new lobby with player 1."""
	var lobby_id = _next_lobby_id
	_next_lobby_id += 1

	var lobby = Lobby.new(lobby_id)
	lobby.player1_id = peer_id
	lobby.player1_team = team

	_lobbies[lobby_id] = lobby
	_peer_to_lobby[peer_id] = lobby_id

	return lobby_id


func _start_battle(lobby: Lobby) -> void:
	"""Start battle in a lobby."""
	lobby.state = NetworkProtocol.LobbyState.IN_BATTLE
	lobby.update_activity()

	# Create battle engine
	var rng_seed = randi()
	lobby.battle_engine = BattleEngineScript.new(rng_seed)
	lobby.battle_engine._pending_player1_action = null
	lobby.battle_engine._pending_player2_action = null

	# Initialize battle
	lobby.battle_engine.call("initialize_battle", lobby.player1_team, lobby.player2_team)

	# Send battle start to both players
	var battle_start = NetworkProtocol.create_packet(
		NetworkProtocol.MessageType.BATTLE_START,
		{
			"lobby_id": lobby.id,
			"rng_seed": rng_seed,
			"battle_state": lobby.battle_engine.call("get_battle_state").to_dict()
		}
	)
	_broadcast_to_lobby(lobby, battle_start)

	print("[BattleServer] Battle started in lobby %d" % lobby.id)


func _execute_turn(lobby: Lobby) -> void:
	"""Execute a battle turn."""
	var engine = lobby.battle_engine
	var p1_action = engine._pending_player1_action
	var p2_action = engine._pending_player2_action

	# Execute turn
	engine.call("execute_turn", p1_action, p2_action)

	# Clear pending actions
	engine._pending_player1_action = null
	engine._pending_player2_action = null

	# Get updated state
	var state = engine.call("get_battle_state")

	# Broadcast state update
	var state_update = NetworkProtocol.create_packet(
		NetworkProtocol.MessageType.BATTLE_STATE_UPDATE,
		{"battle_state": state.to_dict()}
	)
	_broadcast_to_lobby(lobby, state_update)

	# Check if battle ended
	if engine.call("is_battle_over"):
		_handle_battle_end(lobby)


func _handle_battle_end(lobby: Lobby) -> void:
	"""Handle battle completion."""
	lobby.state = NetworkProtocol.LobbyState.COMPLETED

	var winner = lobby.battle_engine.call("get_winner")

	var battle_end = NetworkProtocol.create_packet(
		NetworkProtocol.MessageType.BATTLE_ENDED,
		{"winner": winner}
	)
	_broadcast_to_lobby(lobby, battle_end)

	print("[BattleServer] Battle ended in lobby %d, winner: Player %d" % [lobby.id, winner])


func _handle_player_leave(lobby: Lobby, peer_id: int) -> void:
	"""Handle player leaving lobby."""
	var other_player = lobby.player1_id if lobby.player2_id == peer_id else lobby.player2_id

	lobby.state = NetworkProtocol.LobbyState.ABANDONED

	if other_player != -1:
		var leave_packet = NetworkProtocol.create_packet(
			NetworkProtocol.MessageType.PLAYER_LEFT,
			{"lobby_id": lobby.id, "player_id": peer_id}
		)
		_send_to_peer(other_player, leave_packet)

		# Remove other player from mappings
		_peer_to_lobby.erase(other_player)

	# Clean up lobby
	_lobbies.erase(lobby.id)


func _validate_and_create_team(team_data: Dictionary) -> Array:
	"""Validate team data and create BattlePokemon instances."""
	if not team_data.has("pokemon"):
		return []

	var pokemon_array = team_data["pokemon"]
	if pokemon_array.size() < 1 or pokemon_array.size() > 6:
		return []

	var team: Array = []
	for pokemon_data in pokemon_array:
		var pokemon = BattlePokemonScript.from_dict(pokemon_data)
		if not pokemon:
			return []
		team.append(pokemon)

	return team


func _validate_action(lobby: Lobby, player_num: int, action) -> bool:
	"""Validate a battle action."""
	var state = lobby.battle_engine.call("get_battle_state")
	var active_pokemon = state.get_active_pokemon(player_num)

	if action.type == BattleActionScript.ActionType.MOVE:
		# Validate move index
		if action.move_index < 0 or action.move_index >= active_pokemon.moves.size():
			return false
		# Check PP
		if active_pokemon.move_pp[action.move_index] <= 0:
			return false
		return true

	elif action.type == BattleActionScript.ActionType.SWITCH:
		var team = state.get_team(player_num)
		# Validate switch target
		if action.switch_target < 0 or action.switch_target >= team.size():
			return false
		# Check if target is fainted or already active
		if team[action.switch_target].is_fainted():
			return false
		if action.switch_target == (state.active1_index if player_num == 1 else state.active2_index):
			return false
		return true

	elif action.type == BattleActionScript.ActionType.FORFEIT:
		return true

	return false


func _get_lobby_list() -> Array:
	"""Get list of available lobbies."""
	var lobby_list = []
	for lobby_id in _lobbies:
		var lobby: Lobby = _lobbies[lobby_id]
		if lobby.state == NetworkProtocol.LobbyState.WAITING:
			lobby_list.append({
				"id": lobby_id,
				"player_count": 1,
				"state": lobby.state
			})
	return lobby_list


func _send_to_peer(peer_id: int, packet: Dictionary) -> void:
	"""Send packet to specific peer."""
	_rpc_send_packet.rpc_id(peer_id, packet)


func _broadcast_to_lobby(lobby: Lobby, packet: Dictionary) -> void:
	"""Broadcast packet to all players in lobby."""
	if lobby.player1_id != -1:
		_send_to_peer(lobby.player1_id, packet)
	if lobby.player2_id != -1:
		_send_to_peer(lobby.player2_id, packet)


func _send_error(peer_id: int, error_code: NetworkProtocol.ErrorCode, message: String = "") -> void:
	"""Send error packet to peer."""
	var error_packet = NetworkProtocol.create_error_packet(error_code, message)
	_send_to_peer(peer_id, error_packet)


@rpc("authority", "call_remote", "reliable")
func _rpc_send_packet(packet: Dictionary) -> void:
	"""RPC method to send packet to client."""
	pass  # Implementation on client side
