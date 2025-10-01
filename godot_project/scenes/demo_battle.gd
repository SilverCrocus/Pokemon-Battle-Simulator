extends Node

## Demo Battle Scene
##
## Simple demo that loads the battle UI and starts an actual battle
## so you can see the ActionMenu and MoveSelectionUI in action.

const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")

func _ready() -> void:
	print("================================================================================")
	print("POKEMON BATTLE SIMULATOR - INTERACTIVE DEMO")
	print("================================================================================")
	print()

	# Load the battle scene
	var battle_scene = load("res://scenes/BattleScene.tscn").instantiate()
	add_child(battle_scene)

	# Wait for scene to be ready
	await get_tree().process_frame

	# Create test Pokemon (using IDs: Pikachu=25, Charizard=6)
	var player_pikachu = _create_test_pokemon(25)
	var opponent_charizard = _create_test_pokemon(6)

	if not player_pikachu or not opponent_charizard:
		print("✗ ERROR: Could not create Pokemon for demo")
		print("   Make sure data files are accessible")
		return

	print("[DEMO] Starting battle...")
	print("   Player: %s (Level %d)" % [player_pikachu.species.name, player_pikachu.level])
	print("   Opponent: %s (Level %d)" % [opponent_charizard.species.name, opponent_charizard.level])
	print()

	# Start the battle - THIS will trigger the ActionMenu to appear!
	battle_scene.start_battle(player_pikachu, opponent_charizard)

	await get_tree().create_timer(0.5).timeout

	print("================================================================================")
	print("DEMO READY")
	print("================================================================================")
	print("✓ Battle UI loaded")
	print("✓ You should now see:")
	print("  - Two Pokemon info panels (top-left and middle-right)")
	print("  - Battle log panel at the bottom")
	print("  - ActionMenu with Fight/Pokemon/Bag/Run buttons")
	print()
	print("Click 'Fight' to see the Move Selection UI with 4 type-colored move buttons!")
	print("================================================================================")


func _create_test_pokemon(species_id: int):
	"""Create a test Pokemon using DataManager."""
	# Load species data from DataManager
	var species_data = DataManager.get_pokemon(species_id)

	if not species_data:
		push_error("Could not find species ID: %d" % species_id)
		return null

	# Load moves from DataManager
	var tackle = DataManager.get_move(33)  # Tackle
	var thunderbolt = DataManager.get_move(85)  # Thunderbolt
	var flamethrower = DataManager.get_move(53)  # Flamethrower
	var air_slash = DataManager.get_move(403)  # Air Slash

	var moves = []
	if tackle: moves.append(tackle)
	if thunderbolt: moves.append(thunderbolt)
	if flamethrower: moves.append(flamethrower)
	if air_slash: moves.append(air_slash)

	if moves.is_empty():
		push_error("No moves available for species ID %d" % species_id)
		return null

	# Create BattlePokemon using the constructor
	return BattlePokemonScript.new(
		species_data,
		50,  # Level
		{"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},  # IVs
		{"hp": 4, "atk": 0, "def": 0, "spa": 252, "spd": 0, "spe": 252},  # EVs (total: 508)
		"Modest",  # Nature
		moves,
		"",  # Ability (empty for now)
		"",  # Item (empty for now)
		""   # Nickname (empty for now)
	)
