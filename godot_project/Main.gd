extends Node

## Main entry point with server/client feature detection
## This node detects if running as headless server or client and launches appropriate mode

func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		_launch_server()
	else:
		_launch_client()

func _launch_server() -> void:
	"""Launch headless server mode."""
	print("=== POKEMON BATTLE SIMULATOR SERVER ===")
	print("Server mode detected - launching headless server...")
	print("Godot version: %s" % Engine.get_version_info().string)
	print("Server starting on port 9999...")

	# TODO: Initialize BattleServer autoload (will create in Day 2-3)
	# BattleServer.setup_network(9999)

	print("Server ready - waiting for client connections...")

func _launch_client() -> void:
	"""Launch client mode with full UI."""
	print("=== POKEMON BATTLE SIMULATOR CLIENT ===")
	print("Client mode detected - loading main menu...")

	# Load existing main menu scene (Phase 2)
	# Use call_deferred to avoid scene tree errors
	get_tree().change_scene_to_file.call_deferred("res://scenes/menu/MainMenuScene.tscn")
