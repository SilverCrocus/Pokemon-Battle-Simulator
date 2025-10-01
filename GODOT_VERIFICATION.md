# Godot Project Verification Guide

## Step 1: Open the Godot Project

### Option A: Command Line (if `godot` is in PATH)
```bash
cd /Users/diyagamah/Documents/Pokemon-Battle-Simulator/godot_project
godot .
```

### Option B: Godot Application
1. Open Godot 4 application
2. Click "Import" button
3. Navigate to: `/Users/diyagamah/Documents/Pokemon-Battle-Simulator/godot_project/`
4. Select `project.godot`
5. Click "Import & Edit"

---

## Step 2: Verify Resources Loaded

### Check FileSystem Panel

The FileSystem panel should be in the bottom-left of Godot. Verify:

1. **Pokemon Resources** (`res://resources/pokemon/`)
   - Should contain 1,302 .tres files
   - Try opening `25.tres` (Pikachu)
   - In Inspector panel, verify:
     - name: "pikachu"
     - base_hp: 35
     - base_spe: 90
     - type1: "electric"

2. **Move Resources** (`res://resources/moves/`)
   - Should contain 937 .tres files
   - Try opening `1.tres` (Pound)

3. **Ability Resources** (`res://resources/abilities/`)
   - Should contain 367 .tres files

4. **Item Resources** (`res://resources/items/`)
   - Should contain 2,000 .tres files

---

## Step 3: Test DataManager (Script Console)

### Create a Test Script

1. In Godot, click "Script" at the top
2. Create new script: `File → New Script`
3. Name it: `test_resources.gd`
4. Add this code:

```gdscript
extends Node

func _ready():
    print("=== Testing DataManager ===")

    # Test Pokemon loading
    var pikachu = DataManager.get_pokemon(25)
    if pikachu:
        print("✓ Loaded Pikachu:")
        print("  Name: ", pikachu.name)
        print("  HP: ", pikachu.base_hp)
        print("  Speed: ", pikachu.base_spe)
        print("  Type: ", pikachu.type1)
        print("  Total Stats: ", pikachu.get_base_stat_total())
    else:
        print("✗ Failed to load Pikachu")

    # Test Move loading
    var thunderbolt = DataManager.get_move(85)
    if thunderbolt:
        print("\n✓ Loaded Thunderbolt:")
        print("  Name: ", thunderbolt.name)
        print("  Power: ", thunderbolt.power)
        print("  Type: ", thunderbolt.type)
        print("  Accuracy: ", thunderbolt.accuracy)
    else:
        print("✗ Failed to load Thunderbolt")

    # Test cache stats
    print("\n=== Cache Stats ===")
    var stats = DataManager.get_cache_stats()
    print("  Pokemon cached: ", stats.pokemon_cached)
    print("  Moves cached: ", stats.moves_cached)
```

5. Save the script
6. Attach it to a Node in the scene
7. Run the scene (F5)
8. Check the Output panel at the bottom

**Expected Output:**
```
=== Testing DataManager ===
✓ Loaded Pikachu:
  Name: pikachu
  HP: 35
  Speed: 90
  Type: electric
  Total Stats: 320

✓ Loaded Thunderbolt:
  Name: thunderbolt
  Power: 90
  Type: electric
  Accuracy: 100

=== Cache Stats ===
  Pokemon cached: 1
  Moves cached: 1
```

---

## Step 4: Test TypeChart

### Add TypeChart Tests to the Script

Add this to the `_ready()` function in `test_resources.gd`:

```gdscript
    print("\n=== Testing TypeChart ===")

    # Single type effectiveness
    var eff1 = TypeChart.get_effectiveness("electric", "water")
    print("Electric vs Water: ", eff1, "x (", TypeChart.get_effectiveness_text(eff1), ")")

    # Dual type effectiveness (quad damage)
    var eff2 = TypeChart.calculate_type_effectiveness("ice", ["grass", "dragon"])
    print("Ice vs Grass/Dragon: ", eff2, "x (", TypeChart.get_effectiveness_text(eff2), ")")

    # Immunity
    var eff3 = TypeChart.calculate_type_effectiveness("ground", ["flying"])
    print("Ground vs Flying: ", eff3, "x (", TypeChart.get_effectiveness_text(eff3), ")")

    # Neutral
    var eff4 = TypeChart.calculate_type_effectiveness("fire", ["grass", "water"])
    print("Fire vs Grass/Water: ", eff4, "x (", TypeChart.get_effectiveness_text(eff4), ")")
```

**Expected Output:**
```
=== Testing TypeChart ===
Electric vs Water: 2x (Super Effective)
Ice vs Grass/Dragon: 4x (Super Effective (4x))
Ground vs Flying: 0x (No Effect)
Fire vs Grass/Water: 1x (Neutral)
```

---

## Step 5: Verify Autoloads

1. Go to `Project → Project Settings`
2. Click "Autoload" tab
3. Verify these are listed:
   - DataManager: `res://autoloads/DataManager.gd`
   - TypeChart: `res://autoloads/TypeChart.gd`
   - BattleController: `res://autoloads/BattleController.gd`

---

## Troubleshooting

### Resources Not Loading?

**Check:**
1. Are .tres files in the right location?
   - `ls godot_project/resources/pokemon/ | wc -l` should show 1302
2. Did Godot import them?
   - Check `.godot/imported/` folder
3. Are there any errors in the Output panel?

### Script Errors?

**Common Issues:**
- Make sure script is attached to a Node
- Make sure autoloads are configured correctly
- Check that Resource classes are in the right paths

### Performance Issues?

**Note:** Loading 4,606 resources is a lot! Initial import may take 30-60 seconds.
- Godot will cache them in `.godot/` folder
- Subsequent opens will be much faster

---

## Success Criteria

You've successfully verified the Godot project when:

✅ All resource folders contain the correct number of files
✅ Pikachu loads with correct stats
✅ TypeChart calculates effectiveness correctly
✅ No errors in Output panel
✅ Autoloads are configured

---

## Next Steps

Once verification is complete:

1. **Take a break!** You've accomplished Phase 0 in 1 day (planned: 2 weeks)

2. **Begin Phase 1**: Battle Engine Core
   - Create `BattlePokemon.gd` class
   - Implement stat calculation system
   - Start building the battle simulator

3. **Optional**: Commit your progress
   ```bash
   git add .
   git commit -m "Complete Phase 0: Foundation & Data Acquisition

   - Downloaded 4,606 Pokemon resources from PokeAPI
   - Generated Godot .tres files for all data
   - Implemented TypeChart system
   - Created DataManager with lazy loading
   - Project structure complete and verified"
   ```

---

**Project Status**: Phase 0 ✅ COMPLETE (10% overall progress, 1 week ahead of schedule!)
