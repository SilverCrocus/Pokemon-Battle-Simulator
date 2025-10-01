# Pokemon Battle Simulator - Godot Project

This is the main Godot 4 project for the Pokemon Battle Simulator.

## Project Structure

```
godot_project/
├── project.godot          # Godot project configuration
├── scenes/                # Game scenes (.tscn files)
│   ├── battle/           # Battle scene
│   ├── team_builder/     # Team builder scene
│   └── menu/             # Main menu
├── scripts/               # GDScript code
│   ├── core/             # Battle engine (headless logic)
│   ├── data/             # Data Resource classes
│   ├── networking/       # Server/client code
│   └── ui/               # UI controllers
├── resources/             # Pokemon/move data (.tres files)
│   ├── pokemon/          # Pokemon resources (~1000+ files)
│   ├── moves/            # Move resources (~900 files)
│   ├── abilities/        # Ability resources (~300 files)
│   └── items/            # Item resources (~1000+ files)
├── autoloads/             # Singleton managers
│   ├── DataManager.gd    # Data loading/caching
│   ├── TypeChart.gd      # Type effectiveness
│   └── BattleController.gd # Battle coordination
└── tests/                 # Unit & integration tests
```

## Current Status

**Phase 0**: Foundation & Data Acquisition - ✅ COMPLETE

✅ Completed:
- Godot project structure
- Resource class templates (PokemonData, MoveData, AbilityData, ItemData)
- Autoload singletons (DataManager, TypeChart, BattleController)
- TypeChart implementation with all Gen 9 type matchups
- PokeAPI data downloaded (1,302 Pokemon, 937 moves, 367 abilities, 2,000 items)
- Showdown stats downloaded (5 tiers, 3 rating cutoffs)
- Transformation complete: 4,606 .tres resource files generated
- Verification test scene created

⏳ Next:
- Run verification test in Godot
- Begin Phase 1: Battle Engine Core

## Resource Classes

### PokemonData
Static Pokemon species data (base stats, types, abilities, learnset).

**Properties:**
- `pokemon_id`, `name`, `form`
- Base stats: `base_hp`, `base_atk`, `base_def`, `base_spa`, `base_spd`, `base_spe`
- Types: `type1`, `type2`
- Abilities: `abilities`, `hidden_ability`
- `learnset`, `generation`
- Flags: `is_legendary`, `is_mythical`

### MoveData
Static move data (power, accuracy, type, effects).

**Properties:**
- `move_id`, `name`, `type`
- Mechanics: `power`, `accuracy`, `pp`, `priority`, `damage_class`
- Effects: `effect_description`, `effect_chance`
- Flags: `makes_contact`, `is_sound_move`, etc.

### AbilityData
Static ability data (effects, description).

**Properties:**
- `ability_id`, `name`
- `effect_description`, `short_effect`
- `generation`

### ItemData
Static item data (effects, category).

**Properties:**
- `item_id`, `name`, `category`
- `effect_description`
- Flags: `is_holdable`, `is_consumable`, `is_usable_in_battle`

## Autoloads

### DataManager
Manages loading and caching of Pokemon/move/ability/item data.

**Key Methods:**
- `get_pokemon(id)` - Get Pokemon by ID
- `get_move(id)` - Get move by ID
- `get_ability(id)` - Get ability by ID
- `get_item(id)` - Get item by ID
- `clear_cache()` - Free memory

### TypeChart
Type effectiveness calculation system.

**Key Methods:**
- `get_effectiveness(atk_type, def_type)` - Get multiplier for single type
- `calculate_type_effectiveness(atk_type, def_types)` - Calculate for dual types
- `is_super_effective(multiplier)` - Check if SE
- `is_immune(multiplier)` - Check if immune

**Example:**
```gdscript
var effectiveness = TypeChart.calculate_type_effectiveness("fire", ["grass", "ice"])
# Returns 4.0 (quad effective!)
```

### BattleController
Coordinates battles between engine and UI.

**Status:** Stub implementation (will be completed in Phase 1)

## Next Steps

### 1. Run Verification Test
In Godot editor:
1. Open `scenes/test_verification.tscn`
2. Press **F6** to run the test scene
3. Check Output panel for test results

See `../VERIFICATION_STEPS.md` for detailed instructions.

### 2. Begin Phase 1: Battle Engine
Once verification passes, start implementing the headless battle engine:
- `BattlePokemon.gd` - Runtime battle Pokemon instance
- `BattleState.gd` - Complete battle state tracking
- `StatCalculator.gd` - Stat calculation formulas
- `DamageCalculator.gd` - Damage calculation formulas
- `BattleEngine.gd` - Turn resolution system
- Write 100+ unit tests

See `../PROJECT_PLAN.md` for complete Phase 1 milestones.

## Development Guidelines

### Code Style
- Use GDScript for all game logic
- Static typing (`var x: int = 0`)
- Document public functions with docstrings
- Follow Godot naming conventions

### Architecture Principles
1. **Separation of Concerns**: Battle engine is pure logic, no UI dependencies
2. **Event-Driven**: Engine emits signals, UI responds
3. **Server-Authoritative**: All logic on server for multiplayer
4. **Resource-Based Data**: Use `.tres` files, not JSON at runtime

### Testing
- Write unit tests for all core mechanics
- Use GUT (Godot Unit Testing) framework
- Test against Pokemon Showdown results for accuracy

## Resources

- [Godot Docs](https://docs.godotengine.org/en/stable/)
- [Pokemon Showdown](https://github.com/smogon/pokemon-showdown)
- [PokeAPI](https://pokeapi.co/)
- [Project Plan](../PROJECT_PLAN.md)

---

*Last Updated: October 1, 2025*
