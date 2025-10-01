# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a competitive Pokemon Battle Simulator built in Godot 4. The project implements accurate Gen 9 battle mechanics matching Pokemon Showdown, with support for online multiplayer battles.

**Current Status**: Phase 1 Week 4 - BattleEngine turn execution system is complete. The project has 4,606+ .tres resource files for Pokemon, moves, abilities, and items.

## Development Commands

### Running the Project
```bash
# Open Godot editor from project directory
godot --editor .

# Run test verification scene (current main scene)
godot --path . scenes/test_verification.tscn

# Run project (F5 in editor)
godot --path .
```

### Testing
Tests use the GUT (Godot Unit Testing) framework. Currently tests are located in `scripts/test_*.gd` files.

To run tests:
1. Open test scene in Godot editor
2. Press F6 to run the scene
3. Check Output panel for results

## Architecture

### Core Design Principles

1. **Decoupled Battle Engine**: Battle logic is completely separate from UI/presentation
2. **Server-Authoritative**: All game logic runs on server to prevent cheating
3. **Resource-Based Data**: Pokemon/move/ability/item data stored as Godot .tres files (not JSON at runtime)
4. **Event-Driven**: Engine emits signals, UI responds to events
5. **Deterministic Simulation**: Same inputs + seed = same outputs (enables battle replays)

### Directory Structure

```
godot_project/
├── autoloads/           # Singleton managers (always loaded)
│   ├── DataManager.gd       # Loads and caches Pokemon/move/ability/item data
│   ├── TypeChart.gd         # Type effectiveness calculations
│   └── BattleController.gd  # Battle coordination (stub, Phase 2)
├── scripts/
│   ├── core/            # Battle engine (pure GDScript, no Nodes)
│   │   ├── BattlePokemon.gd    # Runtime battle Pokemon instance
│   │   ├── BattleState.gd      # Complete battle state tracking
│   │   ├── StatCalculator.gd   # Gen 3-9 stat calculation formulas
│   │   ├── DamageCalculator.gd # Gen 5-9 damage calculation formulas
│   │   ├── BattleAction.gd     # Action representation (move/switch/forfeit)
│   │   ├── ActionQueue.gd      # Priority queue for turn-based execution
│   │   └── BattleEngine.gd     # Turn execution orchestrator
│   ├── data/            # Resource class templates
│   │   ├── PokemonData.gd      # Static Pokemon species data
│   │   ├── MoveData.gd         # Static move data
│   │   ├── AbilityData.gd      # Static ability data
│   │   └── ItemData.gd         # Static item data
│   ├── networking/      # Server/client code (Phase 3)
│   └── ui/              # UI controllers (Phase 2)
├── resources/           # Data files (.tres resources)
│   ├── pokemon/         # 1,302 Pokemon resources
│   ├── moves/           # 937 move resources
│   ├── abilities/       # 367 ability resources
│   └── items/           # 2,000 item resources
├── scenes/              # Game scenes (.tscn files)
└── tests/               # Unit & integration tests (Phase 1+)
```

### Key Classes

#### Data Resource Classes
- **PokemonData** (`scripts/data/PokemonData.gd`): Static species data (base stats, types, abilities, learnset)
- **MoveData** (`scripts/data/MoveData.gd`): Static move data (power, accuracy, type, effects)
- **AbilityData** (`scripts/data/AbilityData.gd`): Static ability data (effects, description)
- **ItemData** (`scripts/data/ItemData.gd`): Static item data (effects, category, flags)

#### Core Battle Classes
- **BattlePokemon** (`scripts/core/BattlePokemon.gd`): Runtime instance combining species data with IVs, EVs, nature, level, current HP, status conditions, stat stages, and moves
- **BattleState** (`scripts/core/BattleState.gd`): Complete battle state including both teams, active Pokemon, weather, terrain, turn count, and deterministic RNG
- **StatCalculator** (`scripts/core/StatCalculator.gd`): Gen 3-9 stat calculation formulas (HP, non-HP stats, nature modifiers, stat stages)
- **DamageCalculator** (`scripts/core/DamageCalculator.gd`): Gen 5-9 damage calculation (base damage, critical hits, STAB, type effectiveness, weather, burn, modifiers)

#### Battle Engine Classes (Phase 1 Week 4)
- **BattleAction** (`scripts/core/BattleAction.gd`): Represents player actions (move/switch/forfeit)
- **ActionQueue** (`scripts/core/ActionQueue.gd`): Priority queue implementing Pokemon Showdown turn order (switch > move by priority/speed > forfeit)
- **BattleEngine** (`scripts/core/BattleEngine.gd`): Orchestrates turn execution, damage calculation, status effects, and battle flow
- **BattleEvents** (`autoloads/BattleEvents.gd`): Central event bus for battle-related events (move_used, damage_dealt, pokemon_fainted, etc.)

#### Autoload Singletons
- **DataManager** (`autoloads/DataManager.gd`): Loads and caches resource data
  - `get_pokemon(id)`, `get_move(id)`, `get_ability(id)`, `get_item(id)`
- **TypeChart** (`autoloads/TypeChart.gd`): Type effectiveness system
  - `calculate_type_effectiveness(atk_type, def_types)` - Returns multiplier (0.0, 0.25, 0.5, 1.0, 2.0, 4.0)
- **BattleEvents** (`autoloads/BattleEvents.gd`): Event bus for decoupling battle engine from UI
  - Emits signals for all battle events (battle_started, move_used, damage_dealt, pokemon_fainted, etc.)

## Code Style Guidelines

### GDScript Conventions
- **Type hints**: Use type hints for clarity, but avoid using them with RefCounted classes that may not be in scope
  - Use: `var x: int = 0`, `func foo() -> void:`
  - Avoid: `var action: BattleAction` (use `var action  # BattleAction` comment instead)
  - Avoid: `:=` type inference operator (use `=` instead for compatibility)
- **Class documentation**: Use `##` for class-level and function docstrings
- **Naming**:
  - Classes: PascalCase
  - Functions/variables: snake_case
  - Constants: SCREAMING_SNAKE_CASE
  - Private functions: prefix with `_` (e.g., `_calculate_damage`)
- **Assertions**: Use `assert()` for precondition validation in all public functions

### Architecture Guidelines

1. **Battle Engine Purity**: Core battle logic (`scripts/core/`) must NEVER depend on Nodes, UI, or scene tree. Use pure GDScript RefCounted classes only.

2. **No UI in Logic**: Battle calculations should not access or manipulate UI elements. All UI updates happen via signals or explicit function calls from controller layer.

3. **Resource Usage**: At runtime, load data via DataManager autoload, not direct ResourceLoader. DataManager handles caching and validation.

4. **Deterministic RNG**: Battle-related randomness must use BattleState's internal RNG (`state.random_int()`, `state.random_float()`), not global `randi()` or `randf()`.

5. **Integer Math**: Pokemon formulas use integer math with explicit floor operations. Follow exact formulas from Pokemon Showdown:
   - HP Stat: `floor(((2 * Base + IV + floor(EV / 4)) * Level) / 100) + Level + 10`
   - Other Stats: `floor((floor(((2 * Base + IV + floor(EV / 4)) * Level) / 100) + 5) * Nature)`
   - Base Damage: `floor(floor(floor(floor(2 * Level / 5 + 2) * Power * A / D) / 50) + 2)`

6. **Validation**: All public functions must validate inputs with assertions. Check ranges, types, and state preconditions.

## Common Patterns

### Creating a Battle Pokemon
```gdscript
var species: PokemonData = DataManager.get_pokemon("charizard")
var move1: MoveData = DataManager.get_move("flamethrower")
var move2: MoveData = DataManager.get_move("dragon-claw")

var charizard = BattlePokemon.new(
    species,
    100,  # level
    {"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31},  # IVs
    {"spa": 252, "spe": 252, "hp": 4},  # EVs
    "Timid",  # nature
    [move1, move2],  # moves (1-4)
    "Blaze",  # ability
    "choice-specs",  # item
    "Charizard"  # nickname (optional)
)
```

### Setting Up a Battle
```gdscript
var state = BattleState.new(12345)  # seed for deterministic RNG
state.set_team1([pokemon1, pokemon2, pokemon3])
state.set_team2([pokemon4, pokemon5, pokemon6])
state.begin_battle()

var active_p1 = state.get_active_pokemon(1)
var active_p2 = state.get_active_pokemon(2)
```

### Calculating Damage
```gdscript
var attacker = state.get_active_pokemon(1)
var defender = state.get_active_pokemon(2)
var move = attacker.moves[0]

var damage = DamageCalculator.calculate_damage({
    "level": attacker.level,
    "power": move.power,
    "attack": attacker.get_stat_with_stage("spa"),  # or "atk" for physical
    "defense": defender.get_stat_with_stage("spd"),  # or "def" for physical
    "move_type": move.type,
    "attacker_types": [attacker.species.type1, attacker.species.type2],
    "is_physical": move.damage_class == "physical",
    "type_effectiveness": TypeChart.calculate_type_effectiveness(
        move.type,
        [defender.species.type1, defender.species.type2]
    ),
    "weather": state.weather,
    "random_factor": DamageCalculator.get_random_damage_roll()
})
```

### Running a Battle (Phase 1 Week 4)
```gdscript
const BattleEngineScript = preload("res://scripts/core/BattleEngine.gd")
const BattleActionScript = preload("res://scripts/core/BattleAction.gd")

# Create and initialize battle
var engine = BattleEngineScript.new(12345)  # deterministic seed
(engine as RefCounted).call("initialize_battle", team1, team2)

# Subscribe to battle events
BattleEvents.move_used.connect(_on_move_used)
BattleEvents.damage_dealt.connect(_on_damage_dealt)
BattleEvents.pokemon_fainted.connect(_on_pokemon_fainted)
BattleEvents.battle_ended.connect(_on_battle_ended)

# Execute turns
var p1_action = BattleActionScript.new_move_action(0)  # Use first move
var p2_action = BattleActionScript.new_switch_action(1)  # Switch to second Pokemon

(engine as RefCounted).call("execute_turn", p1_action, p2_action)

# Check battle status
if (engine as RefCounted).call("is_battle_over"):
    var winner = (engine as RefCounted).call("get_winner")
    print("Winner: Player %d" % winner)
```

## Testing Strategy

1. **Unit Tests**: Test each calculation function independently with known Pokemon Showdown results
2. **Integration Tests**: Test full battle scenarios (turn resolution, KO handling, switches)
3. **Accuracy Tests**: Compare damage/stat calculations against Pokemon Showdown calculator results
4. **Determinism Tests**: Same RNG seed must produce identical battle outcomes

## Important Notes

- **Never modify .tres resource files directly in code**. These are static data, loaded and cached by DataManager.
- **Shedinja special case**: Always has 1 HP regardless of calculation (handled in BattlePokemon and StatCalculator)
- **Type effectiveness**: Use TypeChart.calculate_type_effectiveness() which handles dual types, immunities, and Gen 9 matchups
- **Status conditions**: Only one major status per Pokemon (burn, poison, badly_poison, paralysis, sleep, freeze, none)
- **Stat stages**: Range from -6 to +6, use BattlePokemon.get_stat_with_stage() to get modified values during battle
- **Move PP**: Track PP per-move in BattlePokemon.move_pp array, use use_move() to consume PP

## External References

- [Pokemon Showdown](https://github.com/smogon/pokemon-showdown) - Reference implementation for battle mechanics
- [Pokemon Damage Calculator](https://calc.pokemonshowdown.com/) - For verifying damage calculations
- [Godot Docs](https://docs.godotengine.org/en/stable/) - Godot 4 documentation
- [PokeAPI](https://pokeapi.co/) - Source for Pokemon data

## Project Status & Roadmap

**Current Phase**: Phase 1 Week 4 (BattleEngine Turn Execution - COMPLETE)

**Completed**:
- ✅ Phase 1 Week 1: Project setup and data pipeline (4,606 .tres resources)
- ✅ Phase 1 Week 2: Core data structures (BattlePokemon, BattleState)
- ✅ Phase 1 Week 3: Calculation systems (StatCalculator, DamageCalculator, TypeChart)
- ✅ Phase 1 Week 4: BattleEngine turn execution (ActionQueue, BattleAction, BattleEvents)

**Next Steps**:
- Phase 1 Week 5: Move effects, accuracy, critical hits, status conditions
- Phase 2: UI/UX Implementation (battle scene, team builder)
- Phase 3: Networking & Multiplayer
- Phase 4: Polish & Advanced Features

See `../PROJECT_PLAN.md` for complete development roadmap.
