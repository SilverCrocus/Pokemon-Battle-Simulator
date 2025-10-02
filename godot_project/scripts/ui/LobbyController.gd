extends Control

## Lobby Controller - Multiplayer Lobby UI
##
## Handles lobby creation, browsing, joining, and ready-up system.
## Connects to BattleClient for network communication.

@onready var lobby_list_container = %LobbyListContainer
@onready var create_lobby_button = %CreateLobbyButton
@onready var join_code_input = %JoinCodeInput
@onready var join_code_button = %JoinCodeButton
@onready var lobby_name_input = %LobbyNameInput
@onready var player_list_container = %PlayerListContainer
@onready var ready_button = %ReadyButton
@onready var leave_button = %LeaveButton
@onready var team_preview_label = %TeamPreviewLabel
@onready var lobby_browser_panel = %LobbyBrowserPanel
@onready var lobby_room_panel = %LobbyRoomPanel
@onready var status_label = %StatusLabel

## Player's team data
var current_team_data: Dictionary = {}

## Current lobby state
var current_lobby_id: int = 0
var is_ready: bool = false
var is_host: bool = false

## Lobby list cache
var lobby_list: Array = []


func _ready() -> void:
	print("[LobbyController] Ready")

	# Connect UI signals
	create_lobby_button.pressed.connect(_on_create_lobby_pressed)
	join_code_button.pressed.connect(_on_join_code_pressed)
	ready_button.pressed.connect(_on_ready_pressed)
	leave_button.pressed.connect(_on_leave_pressed)

	# Connect to BattleClient signals
	BattleClient.lobby_created.connect(_on_lobby_created)
	BattleClient.lobby_joined.connect(_on_lobby_joined)
	BattleClient.lobby_list_updated.connect(_on_lobby_list_updated)
	BattleClient.player_joined_lobby.connect(_on_player_joined)
	BattleClient.player_left_lobby.connect(_on_player_left)
	BattleClient.ready_state_changed.connect(_on_ready_state_changed)
	BattleClient.battle_started.connect(_on_battle_started)
	BattleClient.error_received.connect(_on_error_received)
	BattleClient.disconnected_from_server.connect(_on_disconnected)

	# Initialize UI
	_show_lobby_browser()
	_update_status("Not connected to server")

	# Load test team for development
	_load_test_team()


func set_team_data(team_data: Dictionary) -> void:
	"""Set the player's team data for the lobby."""
	current_team_data = team_data
	_update_team_preview()


func _load_test_team() -> void:
	"""Load a test team for development."""
	# Create a simple test team
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

	current_team_data = {
		"pokemon": [pikachu.to_dict()]
	}

	_update_team_preview()


func connect_to_server(ip: String = "127.0.0.1") -> void:
	"""Connect to the battle server."""
	_update_status("Connecting to %s..." % ip)

	if BattleClient.connect_to_server(ip):
		_update_status("Connecting...")
	else:
		_update_status("Failed to initiate connection")


## UI Actions

func _on_create_lobby_pressed() -> void:
	"""Handle create lobby button press."""
	if not BattleClient.is_connected_to_server():
		_update_status("Not connected to server")
		return

	if current_team_data.is_empty():
		_update_status("No team loaded")
		return

	var lobby_name = lobby_name_input.text
	if lobby_name.is_empty():
		lobby_name = "Battle Lobby"

	BattleClient.create_lobby(current_team_data, lobby_name)
	_update_status("Creating lobby...")


func _on_join_code_pressed() -> void:
	"""Handle join by code button press."""
	if not BattleClient.is_connected_to_server():
		_update_status("Not connected to server")
		return

	if current_team_data.is_empty():
		_update_status("No team loaded")
		return

	var code = join_code_input.text
	if code.is_empty():
		_update_status("Enter lobby code")
		return

	var lobby_id = code.to_int()
	if lobby_id <= 0:
		_update_status("Invalid lobby code")
		return

	BattleClient.join_lobby(lobby_id, current_team_data)
	_update_status("Joining lobby %d..." % lobby_id)


func _on_lobby_item_pressed(lobby_id: int) -> void:
	"""Handle lobby list item click."""
	if current_team_data.is_empty():
		_update_status("No team loaded")
		return

	BattleClient.join_lobby(lobby_id, current_team_data)
	_update_status("Joining lobby %d..." % lobby_id)


func _on_ready_pressed() -> void:
	"""Handle ready button toggle."""
	is_ready = not is_ready
	BattleClient.set_ready(is_ready)

	if is_ready:
		ready_button.text = "Not Ready"
		_update_status("Ready! Waiting for opponent...")
	else:
		ready_button.text = "Ready"
		_update_status("In lobby - Not ready")


func _on_leave_pressed() -> void:
	"""Handle leave lobby button press."""
	# TODO: Implement leave lobby RPC
	_leave_lobby()


## Network Signal Handlers

func _on_lobby_created(lobby_id: int, player_number: int) -> void:
	"""Handle lobby creation confirmation."""
	current_lobby_id = lobby_id
	is_host = (player_number == 1)

	_show_lobby_room()
	_update_status("Lobby created! Code: %d" % lobby_id)
	_update_player_list()

	print("[LobbyController] Lobby %d created, host: %s" % [lobby_id, is_host])


func _on_lobby_joined(lobby_id: int, player_number: int) -> void:
	"""Handle lobby join confirmation."""
	current_lobby_id = lobby_id
	is_host = (player_number == 1)

	_show_lobby_room()
	_update_status("Joined lobby %d" % lobby_id)
	_update_player_list()

	print("[LobbyController] Joined lobby %d" % lobby_id)


func _on_lobby_list_updated(lobbies: Array) -> void:
	"""Handle lobby list update."""
	lobby_list = lobbies
	_refresh_lobby_list()

	print("[LobbyController] Lobby list updated: %d lobbies" % lobbies.size())


func _on_player_joined(player_id: int) -> void:
	"""Handle another player joining."""
	_update_status("Player joined!")
	_update_player_list()

	print("[LobbyController] Player %d joined lobby" % player_id)


func _on_player_left(player_id: int) -> void:
	"""Handle player leaving."""
	_update_status("Player left lobby")
	_leave_lobby()

	print("[LobbyController] Player %d left lobby" % player_id)


func _on_ready_state_changed(player_id: int, ready: bool) -> void:
	"""Handle ready state change."""
	_update_player_list()

	var status = "ready" if ready else "not ready"
	_update_status("Player %d is %s" % [player_id, status])


func _on_battle_started(battle_state_data: Dictionary) -> void:
	"""Handle battle start."""
	print("[LobbyController] Battle starting...")
	_update_status("Battle starting!")

	# Switch to battle scene
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")


func _on_error_received(error_code: int, message: String) -> void:
	"""Handle server error."""
	_update_status("Error: %s" % message)
	print("[LobbyController] Server error: %s" % message)


func _on_disconnected() -> void:
	"""Handle server disconnection."""
	_update_status("Disconnected from server")
	_leave_lobby()


## UI Updates

func _show_lobby_browser() -> void:
	"""Show lobby browser panel."""
	lobby_browser_panel.visible = true
	lobby_room_panel.visible = false


func _show_lobby_room() -> void:
	"""Show lobby room panel."""
	lobby_browser_panel.visible = false
	lobby_room_panel.visible = true
	is_ready = false
	ready_button.text = "Ready"


func _leave_lobby() -> void:
	"""Leave current lobby and return to browser."""
	current_lobby_id = 0
	is_host = false
	is_ready = false

	_show_lobby_browser()
	_update_status("Left lobby")


func _refresh_lobby_list() -> void:
	"""Refresh the lobby list display."""
	# Clear existing items
	for child in lobby_list_container.get_children():
		child.queue_free()

	# Add lobby items
	for lobby_data in lobby_list:
		var item = _create_lobby_item(lobby_data)
		lobby_list_container.add_child(item)


func _create_lobby_item(lobby_data: Dictionary) -> Control:
	"""Create a lobby list item."""
	var item = Button.new()
	item.text = "Lobby %d (1/2 players)" % lobby_data["id"]
	item.pressed.connect(_on_lobby_item_pressed.bind(lobby_data["id"]))
	return item


func _update_player_list() -> void:
	"""Update the player list display."""
	# Clear existing items
	for child in player_list_container.get_children():
		child.queue_free()

	# Add player items
	var label1 = Label.new()
	label1.text = "Player 1 (You)" if is_host else "Player 1"
	player_list_container.add_child(label1)

	if current_lobby_id > 0:
		var label2 = Label.new()
		label2.text = "Player 2 (You)" if not is_host else "Player 2"
		player_list_container.add_child(label2)


func _update_team_preview() -> void:
	"""Update team preview display."""
	if current_team_data.is_empty():
		team_preview_label.text = "No team loaded"
		return

	var pokemon_count = current_team_data.get("pokemon", []).size()
	team_preview_label.text = "Team: %d Pokemon" % pokemon_count


func _update_status(message: String) -> void:
	"""Update status label."""
	status_label.text = message
