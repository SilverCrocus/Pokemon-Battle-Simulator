extends Control

## Connection Screen Controller
##
## Handles server connection UI for multiplayer battles.
## Allows users to connect to a dedicated server by IP/port.

# ==================== Node References ====================

@onready var server_ip_input: LineEdit = $CenterContainer/ConnectionPanel/MarginContainer/VBoxContainer/ServerIPContainer/ServerIPInput
@onready var server_port_input: LineEdit = $CenterContainer/ConnectionPanel/MarginContainer/VBoxContainer/ServerPortContainer/ServerPortInput
@onready var localhost_button: Button = $CenterContainer/ConnectionPanel/MarginContainer/VBoxContainer/LocalhostButton
@onready var connect_button: Button = $CenterContainer/ConnectionPanel/MarginContainer/VBoxContainer/ActionButtons/ConnectButton
@onready var back_button: Button = $CenterContainer/ConnectionPanel/MarginContainer/VBoxContainer/ActionButtons/BackButton
@onready var status_label: Label = $CenterContainer/ConnectionPanel/MarginContainer/VBoxContainer/StatusLabel

# ==================== Constants ====================

const DEFAULT_IP = "127.0.0.1"
const DEFAULT_PORT = 7777
const CONNECTION_TIMEOUT = 5.0

# ==================== State ====================

var is_connecting: bool = false

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the connection screen."""
	_setup_styling()
	_connect_signals()
	_load_defaults()

	print("[ConnectionScreen] Ready")


func _setup_styling() -> void:
	"""Apply Gen 5 visual styling to connection screen."""
	# Panel background
	var panel = $CenterContainer/ConnectionPanel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = BattleTheme.BG_MEDIUM
	style_box.border_width_left = 3
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.border_color = BattleTheme.BORDER_LIGHT
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style_box)

	# Title styling
	var title = $CenterContainer/ConnectionPanel/MarginContainer/VBoxContainer/Title
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", BattleTheme.TEXT_WHITE)

	# Subtitle
	var subtitle = $CenterContainer/ConnectionPanel/MarginContainer/VBoxContainer/Subtitle
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", BattleTheme.TEXT_GRAY)

	# Status label
	status_label.add_theme_font_size_override("font_size", 14)

	# Style buttons
	_style_buttons()


func _style_buttons() -> void:
	"""Apply styling to all buttons."""
	var buttons = [localhost_button, connect_button, back_button]

	for button in buttons:
		button.add_theme_font_size_override("font_size", 16)

		# Normal state
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = BattleTheme.BTN_NORMAL
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
		normal_style.border_color = BattleTheme.BORDER_LIGHT
		normal_style.corner_radius_top_left = 4
		normal_style.corner_radius_top_right = 4
		normal_style.corner_radius_bottom_left = 4
		normal_style.corner_radius_bottom_right = 4
		button.add_theme_stylebox_override("normal", normal_style)

		# Hover state
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = BattleTheme.BTN_HOVER
		hover_style.border_width_left = 2
		hover_style.border_width_top = 2
		hover_style.border_width_right = 2
		hover_style.border_width_bottom = 2
		hover_style.border_color = BattleTheme.BORDER_LIGHT
		hover_style.corner_radius_top_left = 4
		hover_style.corner_radius_top_right = 4
		hover_style.corner_radius_bottom_left = 4
		hover_style.corner_radius_bottom_right = 4
		button.add_theme_stylebox_override("hover", hover_style)

		# Pressed state
		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = BattleTheme.BTN_PRESSED
		pressed_style.border_width_left = 2
		pressed_style.border_width_top = 2
		pressed_style.border_width_right = 2
		pressed_style.border_width_bottom = 2
		pressed_style.border_color = BattleTheme.BORDER_DARK
		pressed_style.corner_radius_top_left = 4
		pressed_style.corner_radius_top_right = 4
		pressed_style.corner_radius_bottom_left = 4
		pressed_style.corner_radius_bottom_right = 4
		button.add_theme_stylebox_override("pressed", pressed_style)


func _connect_signals() -> void:
	"""Connect button signals and BattleClient events."""
	localhost_button.pressed.connect(_on_localhost_pressed)
	connect_button.pressed.connect(_on_connect_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Connect to BattleClient signals
	BattleClient.connected_to_server.connect(_on_connected_to_server)
	BattleClient.connection_failed.connect(_on_connection_failed)
	BattleClient.disconnected_from_server.connect(_on_disconnected_from_server)


func _load_defaults() -> void:
	"""Load default connection values."""
	server_ip_input.text = DEFAULT_IP
	server_port_input.text = str(DEFAULT_PORT)


# ==================== Event Handlers ====================

func _on_localhost_pressed() -> void:
	"""Quick connect to localhost."""
	print("[ConnectionScreen] Quick connect to localhost")
	server_ip_input.text = DEFAULT_IP
	server_port_input.text = str(DEFAULT_PORT)
	_attempt_connection()


func _on_connect_pressed() -> void:
	"""Connect to server with entered IP/port."""
	print("[ConnectionScreen] Connect button pressed")
	_attempt_connection()


func _on_back_pressed() -> void:
	"""Return to main menu."""
	print("[ConnectionScreen] Returning to main menu")

	# Disconnect if connected
	if BattleClient.is_connected_to_server():
		BattleClient.disconnect_from_server()

	get_tree().change_scene_to_file("res://scenes/menu/MainMenuScene.tscn")


# ==================== Connection Logic ====================

func _attempt_connection() -> void:
	"""Attempt to connect to the server."""
	if is_connecting:
		print("[ConnectionScreen] Already connecting...")
		return

	# Validate inputs
	var ip = server_ip_input.text.strip_edges()
	var port_text = server_port_input.text.strip_edges()

	if ip.is_empty():
		_update_status("Please enter a server IP", Color.RED)
		return

	if port_text.is_empty():
		_update_status("Please enter a port", Color.RED)
		return

	if not port_text.is_valid_int():
		_update_status("Port must be a number", Color.RED)
		return

	var port = int(port_text)
	if port < 1 or port > 65535:
		_update_status("Port must be between 1 and 65535", Color.RED)
		return

	# Disable buttons during connection
	is_connecting = true
	connect_button.disabled = true
	localhost_button.disabled = true

	_update_status("Connecting to %s:%d..." % [ip, port], Color.YELLOW)

	print("[ConnectionScreen] Attempting connection to %s:%d" % [ip, port])

	# Attempt connection
	var success = BattleClient.connect_to_server(ip, port)

	if not success:
		_on_connection_failed()
		return

	# Wait for connection result with timeout
	await get_tree().create_timer(CONNECTION_TIMEOUT).timeout

	if not BattleClient.is_connected_to_server() and is_connecting:
		_on_connection_failed()


func _on_connected_to_server() -> void:
	"""Called when successfully connected to server."""
	print("[ConnectionScreen] Successfully connected to server!")

	is_connecting = false
	_update_status("Connected! Loading lobby...", Color.GREEN)

	# Wait a moment to show success message
	await get_tree().create_timer(0.5).timeout

	# Transition to lobby scene
	get_tree().change_scene_to_file("res://scenes/lobby/LobbyScene.tscn")


func _on_connection_failed() -> void:
	"""Called when connection fails."""
	print("[ConnectionScreen] Connection failed")

	is_connecting = false
	connect_button.disabled = false
	localhost_button.disabled = false

	_update_status("Connection failed. Check server is running.", Color.RED)


func _on_disconnected_from_server() -> void:
	"""Called when disconnected from server."""
	if is_connecting:
		_on_connection_failed()


# ==================== Helper Methods ====================

func _update_status(message: String, color: Color = Color.WHITE) -> void:
	"""Update the status label with a message and color."""
	status_label.text = message
	status_label.add_theme_color_override("font_color", color)
	print("[ConnectionScreen] Status: %s" % message)
