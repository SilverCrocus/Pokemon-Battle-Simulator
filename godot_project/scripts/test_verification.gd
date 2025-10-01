extends Node

## Verification script for Pokemon Battle Simulator setup
##
## This script tests that:
## 1. All autoloads are working (DataManager, TypeChart)
## 2. Resources can be loaded (Pokemon, moves, abilities, items)
## 3. Type effectiveness calculations work correctly

func _ready():
	print("\n" + "=".repeat(60))
	print("POKEMON BATTLE SIMULATOR - VERIFICATION TEST")
	print("=".repeat(60))

	test_type_chart()
	test_data_manager_pokemon()
	test_data_manager_moves()
	test_data_manager_abilities()
	test_data_manager_items()

	print("=".repeat(60))
	print("VERIFICATION COMPLETE")
	print("=".repeat(60) + "\n")


func test_type_chart():
	print("\n[TEST] TypeChart Effectiveness Calculations")
	print("-".repeat(60))

	# Test super effective
	var eff1 = TypeChart.calculate_type_effectiveness("electric", ["water"])
	print("  Electric vs Water: %.1fx %s" % [eff1, _get_eff_emoji(eff1)])
	assert(eff1 == 2.0, "Electric should be 2x effective vs Water")

	# Test not very effective
	var eff2 = TypeChart.calculate_type_effectiveness("electric", ["grass"])
	print("  Electric vs Grass: %.1fx %s" % [eff2, _get_eff_emoji(eff2)])
	assert(eff2 == 0.5, "Electric should be 0.5x effective vs Grass")

	# Test immune
	var eff3 = TypeChart.calculate_type_effectiveness("electric", ["ground"])
	print("  Electric vs Ground: %.1fx %s" % [eff3, _get_eff_emoji(eff3)])
	assert(eff3 == 0.0, "Electric should be 0x effective vs Ground")

	# Test dual type (4x weakness)
	var eff4 = TypeChart.calculate_type_effectiveness("ice", ["dragon", "flying"])
	print("  Ice vs Dragon/Flying: %.1fx %s" % [eff4, _get_eff_emoji(eff4)])
	assert(eff4 == 4.0, "Ice should be 4x effective vs Dragon/Flying")

	# Test dual type (quad resistance)
	var eff5 = TypeChart.calculate_type_effectiveness("fire", ["water", "rock"])
	print("  Fire vs Water/Rock: %.2fx %s" % [eff5, _get_eff_emoji(eff5)])
	assert(eff5 == 0.25, "Fire should be 0.25x effective vs Water/Rock")

	print("  ✓ All TypeChart tests passed!")


func test_data_manager_pokemon():
	print("\n[TEST] DataManager - Loading Pokemon")
	print("-".repeat(60))

	# Test loading Pikachu (ID 25)
	var pikachu = DataManager.get_pokemon(25)
	if pikachu:
		print("  ✓ Loaded: %s (#%d)" % [pikachu.name, pikachu.national_dex_number])
		print("    Type: %s%s" % [pikachu.type1, "/" + pikachu.type2 if not pikachu.type2.is_empty() else ""])
		print("    Base Stats: HP=%d Atk=%d Def=%d SpA=%d SpD=%d Spe=%d (Total: %d)" % [
			pikachu.base_hp, pikachu.base_atk, pikachu.base_def,
			pikachu.base_spa, pikachu.base_spd, pikachu.base_spe,
			pikachu.get_base_stat_total()
		])
		print("    Hidden Ability: %s" % pikachu.hidden_ability)
		print("    Learnset size: %d moves" % pikachu.learnset.size())

		assert(pikachu.name == "pikachu", "Name should be pikachu")
		assert(pikachu.base_hp == 35, "Pikachu's base HP should be 35")
		assert(pikachu.base_spe == 90, "Pikachu's base Speed should be 90")
		assert(pikachu.type1 == "electric", "Pikachu should be Electric type")
	else:
		print("  ✗ FAILED: Could not load Pikachu (ID 25)")
		return

	# Test loading Charizard (ID 6)
	var charizard = DataManager.get_pokemon(6)
	if charizard:
		print("\n  ✓ Loaded: %s (#%d)" % [charizard.name, charizard.national_dex_number])
		print("    Type: %s/%s" % [charizard.type1, charizard.type2])
		assert(charizard.type1 == "fire" and charizard.type2 == "flying", "Charizard should be Fire/Flying")
	else:
		print("  ✗ FAILED: Could not load Charizard (ID 6)")
		return

	# Test caching
	var pikachu_cached = DataManager.get_pokemon(25)
	assert(pikachu == pikachu_cached, "DataManager should return cached instance")
	print("\n  ✓ Caching works correctly")


func test_data_manager_moves():
	print("\n[TEST] DataManager - Loading Moves")
	print("-".repeat(60))

	# Test loading Thunderbolt by ID (move #85)
	var thunderbolt = DataManager.get_move(85)
	if thunderbolt:
		print("  ✓ Loaded: %s (ID %d)" % [thunderbolt.name, thunderbolt.move_id])
		print("    Type: %s" % thunderbolt.type)
		print("    Power: %d | Accuracy: %d | PP: %d" % [thunderbolt.power, thunderbolt.accuracy, thunderbolt.pp])
		print("    Damage Class: %s" % thunderbolt.damage_class)
		print("    Priority: %+d" % thunderbolt.priority)

		assert(thunderbolt.name == "thunderbolt", "Move #85 should be Thunderbolt")
		assert(thunderbolt.type == "electric", "Thunderbolt should be Electric type")
		assert(thunderbolt.power == 90, "Thunderbolt should have 90 power")
		assert(thunderbolt.is_special(), "Thunderbolt should be special")
		print("  ✓ All move tests passed!")
	else:
		print("  ✗ FAILED: Could not load move #85 (Thunderbolt)")


func test_data_manager_abilities():
	print("\n[TEST] DataManager - Loading Abilities")
	print("-".repeat(60))

	# Test loading Static by ID (ability #9)
	var static_ability = DataManager.get_ability(9)
	if static_ability:
		print("  ✓ Loaded: %s (ID %d)" % [static_ability.name, static_ability.ability_id])
		print("    Effect: %s" % static_ability.short_effect)
		assert(static_ability.name == "static", "Ability #9 should be Static")
	else:
		print("  ✗ FAILED: Could not load ability #9 (Static)")


func test_data_manager_items():
	print("\n[TEST] DataManager - Loading Items")
	print("-".repeat(60))

	# Test loading Leftovers by ID (item #211)
	var leftovers = DataManager.get_item(211)
	if leftovers:
		print("  ✓ Loaded: %s (ID %d)" % [leftovers.name, leftovers.item_id])
		print("    Effect: %s" % leftovers.short_effect)
		assert(leftovers.name == "leftovers", "Item #211 should be Leftovers")
		print("  ✓ All item tests passed!")
	else:
		print("  ✗ FAILED: Could not load item #211 (Leftovers)")


func _get_eff_emoji(multiplier: float) -> String:
	if multiplier == 0.0:
		return "🚫"
	elif multiplier == 0.25:
		return "🛡️🛡️"
	elif multiplier == 0.5:
		return "🛡️"
	elif multiplier == 1.0:
		return "⚪"
	elif multiplier == 2.0:
		return "⚡"
	elif multiplier == 4.0:
		return "⚡⚡"
	return "?"
