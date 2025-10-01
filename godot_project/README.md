# Pokemon Battle Simulator - Godot Project

This is the main Godot 4 project for the Pokemon Battle Simulator.

## Project Structure

```
godot_project/
├── project.godot          # Godot project configuration
├── scenes/                # Game scenes (.tscn files)
│   ├── battle/           # Battle scene
│   ├── team_builder/     # Team builder scene
│   ├── menu/             # Main menu
│   └── components/       # Reusable UI components
├── scripts/               # GDScript code
│   ├── core/             # Battle engine (headless logic)
│   ├── data/             # Data Resource classes
│   ├── ui/               # UI controllers & components
│   └── utils/            # Utility scripts (StatCalculator, etc.)
├── resources/             # Pokemon/move data (.tres files)
│   ├── pokemon/          # Pokemon resources (~1000+ files)
│   ├── moves/            # Move resources (~900 files)
│   ├── abilities/        # Ability resources (~300 files)
│   └── items/            # Item resources (~1000+ files)
├── autoloads/             # Singleton managers
│   ├── DataManager.gd    # Data loading/caching
│   ├── TypeChart.gd      # Type effectiveness
│   ├── BattleController.gd # Battle coordination
│   ├── BattleEvents.gd   # Event bus system
│   └── AudioManager.gd   # Audio system
└── tests/                 # Unit & integration tests
```

## Current Status

**Phase 0**: Foundation & Data Acquisition - ✅ **COMPLETE**
**Phase 1**: Battle Engine Core - ✅ **COMPLETE**
**Phase 2**: UI & Client Implementation - ✅ **COMPLETE**

### ✅ Phase 2 Complete (Weeks 6-9)

**Week 6: Battle Scene & UI**
- Battle scene layout with Gen 5 aesthetic
- 11 UI components (1,467 lines)
- Pokemon HUD, moves panel, battle log, action menu
- Animated HP bars with Tweens
- Status condition indicators

**Week 7: Team Builder UI**
- Pokemon browser (151 Gen 1 Pokemon)
- Search and type/generation filters
- EV/IV customization with validation
- Move selector with 6 presets
- Nature selector (25 natures)
- Save/load team system

**Week 8: Main Menu & Navigation**
- Main menu with navigation
- Team Builder integration
- Quick Battle mode
- Game flow state management

**Week 9: AI, Results & Audio**
- AI opponent system (Random, Basic, Intermediate difficulty)
- Battle results screen with navigation
- Audio system infrastructure (11 integration points)
- Nature stat modifiers with visual indicators
- Stat calculator utility

**Total Phase 2 Code:** ~4,115 lines

### 🎮 Game Features (Current)

**Complete Single-Player Experience:**
```
Main Menu → Team Builder → Quick Battle (vs AI) → Battle → Results → [Menu/Rematch]
```

**Systems Implemented:**
- ✅ Turn-based battle engine
- ✅ AI opponents with type-effectiveness
- ✅ Team building with EV/IV/nature customization
- ✅ Move selection with legal move filtering
- ✅ Battle results with statistics
- ✅ Audio system (ready for audio files)
- ✅ Gen 5 authentic UI theme

### 🔊 Audio System

**Architecture:**
```
AudioManager (autoload)
├── Music Player (fade in/out, looping)
├── SFX Pool (8 concurrent sounds)
├── Volume Control (Master, Music, SFX)
└── 11 UI Integration Points
```

**Ready for audio files:**
- Music: main_menu.ogg, battle.ogg, victory.ogg, defeat.ogg
- SFX: button_press.wav, move sounds, pokemon_faint.wav

### 📊 Code Statistics

**Phase 1 (Battle Engine):** ~2,800 lines
- BattleEngine, BattleState, BattlePokemon
- DamageCalculator, StatCalculator, ActionQueue
- TypeChart, StatusEffects, MoveEffects

**Phase 2 (UI & Client):** ~4,115 lines
- Battle UI (11 components, 1,467 lines)
- Team Builder (3 components, 1,359 lines)
- Main Menu (210 lines)
- AI System (240 lines)
- Results Screen (200 lines)
- Audio System (370 lines)
- Stat Calculator (280 lines)

**Total Project:** ~6,915 lines of GDScript + 4,606 resource files

### ⏳ Next Steps (Phase 3)

**Phase 3: Multiplayer (Weeks 10-13)**
- Server-authoritative architecture
- Client-server communication
- Lobby system
- Matchmaking
- Replay system

**Polish & Assets:**
- Add audio files (.ogg music, .wav SFX)
- Add Pokemon sprites
- Battle animations
- More AI difficulty levels
- Battle statistics tracking

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

**Features:**
- Battle initialization with teams
- Turn execution coordination
- AI opponent integration
- Event signal management
- Battle state queries

### AudioManager
Centralized audio system for music and sound effects.

**Features:**
- Music playback with fade transitions
- SFX pool (8 concurrent sounds)
- Volume control per bus
- Audio file loading system

### StatCalculator
Utility for stat calculations and nature modifiers.

**Features:**
- 25 Pokemon natures with modifiers
- HP and stat calculation formulas
- EV/IV validation
- Visual display utilities (colors, arrows)

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

## How to Run

### Single-Player (Current)
1. Open project in Godot 4.5+
2. Run project (F5) - starts at Main Menu
3. Click "Team Builder" to create a team
4. Save team and return to menu
5. Click "Quick Battle" to fight AI opponent

### Controls
- **Mouse**: Navigate menus, select moves
- **ESC**: Return to previous menu

## Resources

- [Godot Docs](https://docs.godotengine.org/en/stable/)
- [Pokemon Showdown](https://github.com/smogon/pokemon-showdown)
- [PokeAPI](https://pokeapi.co/)
- [Phase 2 Complete Documentation](PHASE_2_COMPLETE.md)
- [Week 9 Summary](PHASE_2_WEEK_9_COMPLETE.md)

---

*Last Updated: October 2, 2025*
*Version: 0.2.0*
*Phase: 2 Complete - Ready for Phase 3*

🤖 Generated with Claude Code
