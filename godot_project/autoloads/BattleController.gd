extends Node

## BattleController - Battle Coordination System
##
## Bridges between the headless battle engine and UI layer.
## Manages battle flow, turn execution, and animations.
## Loaded as an autoload singleton.

# Signals for battle events
signal turn_started
signal turn_resolved(events: Array)
signal battle_ended(winner: int)
signal animation_finished
signal battle_state_changed(new_state)

# Battle engine instance (will be created in Phase 1)
var engine = null  # TODO: Create BattleEngine class

# Current battle state
var is_battle_active: bool = false


func _ready() -> void:
	"""Initialize on game start."""
	print("[BattleController] Ready")


func start_battle(team1: Array, team2: Array) -> void:
	"""
	Start a new battle with two teams.
	TODO: Implement after BattleEngine is created in Phase 1.
	"""
	print("[BattleController] Starting battle...")
	is_battle_active = true
	turn_started.emit()


func submit_action(player_id: int, action: Dictionary) -> void:
	"""
	Submit a player action (move or switch).
	TODO: Implement after BattleEngine is created in Phase 1.
	"""
	pass


func end_battle() -> void:
	"""
	End the current battle.
	"""
	is_battle_active = false
	print("[BattleController] Battle ended")
