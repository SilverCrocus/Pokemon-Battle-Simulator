extends Node

## Test script for Battle UI integration
##
## Tests the complete battle flow with UI:
## - Battle initialization
## - UI component display
## - Action/move selection
## - HP bar animations
## - Battle log messages
## - Turn execution

# ==================== Preloads ====================

const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")
const BattleScenePreload = preload("res://scenes/BattleScene.tscn")

# ==================== State ====================

var battle_scene = null
var test_passed := 0
var test_failed := 0

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize and run UI tests."""
	print("================================================================================")
	print("BATTLE UI INTEGRATION TEST - Phase 2 Week 6")
	print("================================================================================")
	print()

	# Run test scenarios
	await _test_battle_scene_loads()
	await _test_battle_initialization()
	await _test_ui_components_visible()
	await _test_action_menu_interaction()
	await _test_complete_battle_flow()

	# Print summary
	print()
	print("================================================================================")
	print("TEST SUMMARY")
	print("================================================================================")
	print("Passed: %d" % test_passed)
	print("Failed: %d" % test_failed)
	print("Total:  %d" % (test_passed + test_failed))
	if test_failed == 0:
		print("✓ ALL TESTS PASSED")
	else:
		print("✗ SOME TESTS FAILED")
	print("================================================================================")


# ==================== Test Scenarios ====================

func _test_battle_scene_loads() -> void:
	"""Test that BattleScene loads without errors."""
	print("[TEST] Battle Scene Loading")
	print("--------------------------------------------------------------------------------")

	battle_scene = BattleScenePreload.instantiate()
	add_child(battle_scene)

	await get_tree().process_frame

	if battle_scene and is_instance_valid(battle_scene):
		print("✓ PASS: Battle scene loaded successfully")
		test_passed += 1
	else:
		print("✗ FAIL: Battle scene failed to load")
		test_failed += 1

	print()


func _test_battle_initialization() -> void:
	"""Test battle initialization with Pokemon."""
	print("[TEST] Battle Initialization")
	print("--------------------------------------------------------------------------------")

	if not battle_scene:
		print("✗ FAIL: Battle scene not available")
		test_failed += 1
		print()
		return

	# Create test Pokemon
	var pikachu = _create_test_pokemon("pikachu")
	var charizard = _create_test_pokemon("charizard")

	if not pikachu or not charizard:
		print("✗ FAIL: Could not create test Pokemon")
		test_failed += 1
		print()
		return

	# Start battle
	battle_scene.start_battle(pikachu, charizard)

	await get_tree().create_timer(0.5).timeout

	# Check if battle controller is active
	if BattleController.is_battle_active:
		print("✓ PASS: Battle initialized successfully")
		test_passed += 1
	else:
		print("✗ FAIL: Battle controller not active")
		test_failed += 1

	print()


func _test_ui_components_visible() -> void:
	"""Test that UI components are visible."""
	print("[TEST] UI Component Visibility")
	print("--------------------------------------------------------------------------------")

	if not battle_scene:
		print("✗ FAIL: Battle scene not available")
		test_failed += 1
		print()
		return

	var components_visible := 0
	var components_checked := 0

	# Check opponent info panel
	if battle_scene.opponent_info_panel and battle_scene.opponent_info_panel.visible:
		components_visible += 1
	components_checked += 1

	# Check player info panel
	if battle_scene.player_info_panel and battle_scene.player_info_panel.visible:
		components_visible += 1
	components_checked += 1

	# Check battle log
	if battle_scene.battle_log and battle_scene.battle_log.visible:
		components_visible += 1
	components_checked += 1

	print("  Visible components: %d / %d" % [components_visible, components_checked])

	if components_visible == components_checked:
		print("✓ PASS: All required UI components visible")
		test_passed += 1
	else:
		print("✗ FAIL: Some UI components not visible")
		test_failed += 1

	print()


func _test_action_menu_interaction() -> void:
	"""Test action menu interaction."""
	print("[TEST] Action Menu Interaction")
	print("--------------------------------------------------------------------------------")

	if not battle_scene:
		print("✗ FAIL: Battle scene not available")
		test_failed += 1
		print()
		return

	# Wait for action menu to appear
	await get_tree().create_timer(1.0).timeout

	# Check if action menu is visible
	if battle_scene.action_menu and battle_scene.action_menu.visible:
		print("  Action menu visible: YES")
		print("✓ PASS: Action menu displayed")
		test_passed += 1
	else:
		print("  Action menu visible: NO")
		print("✗ FAIL: Action menu not displayed")
		test_failed += 1

	print()


func _test_complete_battle_flow() -> void:
	"""Test a complete battle turn."""
	print("[TEST] Complete Battle Turn Flow")
	print("--------------------------------------------------------------------------------")

	if not battle_scene or not BattleController.is_battle_active:
		print("✗ FAIL: Battle not active")
		test_failed += 1
		print()
		return

	# Get initial HP
	var player_pokemon = BattleController.get_player_pokemon()
	var opponent_pokemon = BattleController.get_opponent_pokemon()

	if not player_pokemon or not opponent_pokemon:
		print("✗ FAIL: Could not get Pokemon")
		test_failed += 1
		print()
		return

	var initial_opponent_hp = opponent_pokemon.current_hp
	print("  Initial opponent HP: %d" % initial_opponent_hp)

	# Simulate selecting "Fight" -> Move 0
	battle_scene._on_action_selected("fight")
	await get_tree().create_timer(0.2).timeout

	# Check if move selection is visible
	if battle_scene.move_selection_ui and battle_scene.move_selection_ui.visible:
		print("  Move selection displayed: YES")
	else:
		print("  Move selection displayed: NO")

	# Select first move
	battle_scene._on_move_selected(0)
	await get_tree().create_timer(1.0).timeout

	# Check if HP changed
	var final_opponent_hp = opponent_pokemon.current_hp
	print("  Final opponent HP: %d" % final_opponent_hp)

	if final_opponent_hp < initial_opponent_hp:
		print("  Damage dealt: %d" % (initial_opponent_hp - final_opponent_hp))
		print("✓ PASS: Complete battle turn executed")
		test_passed += 1
	else:
		print("✗ FAIL: No damage dealt or turn didn't execute")
		test_failed += 1

	print()


# ==================== Helper Methods ====================

func _create_test_pokemon(species_name: String) -> BattlePokemonScript:
	"""Create a test Pokemon with given species."""
	var species_data := DataManager.get_pokemon_by_name(species_name)

	if not species_data:
		push_error("Could not find species: %s" % species_name)
		return null

	# Get some moves
	var tackle := DataManager.get_move_by_name("tackle")
	var thunderbolt := DataManager.get_move_by_name("thunderbolt")
	var quick_attack := DataManager.get_move_by_name("quick-attack")
	var iron_tail := DataManager.get_move_by_name("iron-tail")

	var moves = []
	if tackle: moves.append(tackle)
	if thunderbolt: moves.append(thunderbolt)
	if quick_attack: moves.append(quick_attack)
	if iron_tail: moves.append(iron_tail)

	if moves.is_empty():
		push_error("No moves available")
		return null

	return BattlePokemonScript.new(
		species_data,
		50,
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},
		{"hp": 252, "atk": 252, "def": 0, "spa": 0, "spd": 0, "spe": 0},
		"Adamant",
		moves,
		"",
		"",
		""
	)
