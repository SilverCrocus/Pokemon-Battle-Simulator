# Godot Project Verification Steps

Follow these steps to verify the Pokemon Battle Simulator is set up correctly.

## Step 1: Verify Resources in FileSystem

1. In Godot's **FileSystem** panel (bottom-left), expand the `resources/` folder
2. You should see 4 subfolders:
   - `pokemon/` - Should contain 1,302 .tres files
   - `moves/` - Should contain 937 .tres files
   - `abilities/` - Should contain 367 .tres files
   - `items/` - Should contain 2,000 .tres files
3. **Total: 4,606 resource files**

### Test: Click on `resources/pokemon/25.tres` (Pikachu)

In the **Inspector** panel (right side), verify:
- `name` = "pikachu"
- `base_hp` = 35
- `base_spe` = 90
- `type1` = "electric"
- `type2` = "" (empty)
- `abilities` = ['static']
- `hidden_ability` = "lightning-rod"

## Step 2: Verify Autoloads

1. Go to **Project → Project Settings**
2. Click the **Autoload** tab
3. Verify these 3 autoloads are enabled:
   - `DataManager` → `res://autoloads/DataManager.gd`
   - `TypeChart` → `res://autoloads/TypeChart.gd`
   - `BattleController` → `res://autoloads/BattleController.gd`

## Step 3: Run Verification Test

1. In the **FileSystem** panel, navigate to `scenes/test_verification.tscn`
2. Double-click to open the scene
3. Press **F6** (or click the "Run Current Scene" button) to run the test
4. Check the **Output** panel (bottom) for test results

### Expected Output:

```
============================================================
POKEMON BATTLE SIMULATOR - VERIFICATION TEST
============================================================

[TypeChart] Initialized with 19 types and 171 matchups

[TEST] TypeChart Effectiveness Calculations
------------------------------------------------------------
  Electric vs Water: 2.0x ⚡
  Electric vs Grass: 0.5x 🛡️
  Electric vs Ground: 0.0x 🚫
  Ice vs Dragon/Flying: 4.0x ⚡⚡
  Fire vs Water/Rock: 0.25x 🛡️🛡️
  ✓ All TypeChart tests passed!

[TEST] DataManager - Loading Pokemon
------------------------------------------------------------
  ✓ Loaded: pikachu (#25)
    Type: electric
    Base Stats: HP=35 Atk=55 Def=40 SpA=50 SpD=50 Spe=90 (Total: 320)
    Abilities: static
    Hidden Ability: lightning-rod
    Learnset size: [number] moves

  ✓ Loaded: charizard (#6)
    Type: fire/flying

  ✓ Caching works correctly

[TEST] DataManager - Loading Moves
------------------------------------------------------------
  ✓ Loaded: thunderbolt (ID [number])
    Type: electric
    Power: 90 | Accuracy: 100 | PP: 15
    Damage Class: special
    Priority: +0

[TEST] DataManager - Loading Abilities
------------------------------------------------------------
  ✓ Loaded: static (ID [number])
    Effect: [description]

[TEST] DataManager - Loading Items
------------------------------------------------------------
  ✓ Loaded: leftovers (ID [number])
    Effect: [description]

============================================================
VERIFICATION COMPLETE
============================================================
```

## Step 4: Manual Spot Checks (Optional)

### Check a few more Pokemon:

1. `resources/pokemon/6.tres` - Charizard
   - `type1` = "fire", `type2` = "flying"
   - `base_spe` = 100

2. `resources/pokemon/1.tres` - Bulbasaur
   - `type1` = "grass", `type2` = "poison"
   - `base_hp` = 45

3. `resources/pokemon/150.tres` - Mewtwo
   - `type1` = "psychic"
   - `is_legendary` = true

### Check a few moves:

1. `resources/moves/` - Find "thunderbolt.tres"
   - `power` = 90
   - `accuracy` = 100
   - `type` = "electric"

## Troubleshooting

### If resources are missing:
```bash
cd data_pipeline
uv run python scripts/transform_to_godot.py
```

### If autoloads aren't working:
- Verify in Project Settings → Autoload
- Make sure "Enable" checkbox is checked for each
- Restart Godot

### If test fails:
- Check the **Output** panel for error messages
- Verify resource files exist in FileSystem
- Check that all autoloads are enabled

## What's Next?

Once verification is complete:
1. Update `PROGRESS.md` to mark Phase 0 as 100% complete
2. Begin **Phase 1: Battle Engine Core**
   - Create `BattlePokemon.gd` (runtime battle instance)
   - Create `BattleState.gd` (complete battle state)
   - Implement stat calculations
   - Implement damage calculations
   - Create turn resolution system
