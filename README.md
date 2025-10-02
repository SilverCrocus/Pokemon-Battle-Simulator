# Pokemon Battle Simulator

A competitive Pokemon battle simulator built in Godot 4 with online multiplayer support.

> **⚠️ Legal Notice**: This is an educational project using **original creature designs and assets**. All Pokemon names, designs, and game mechanics are property of Nintendo/Game Freak/The Pokemon Company. This simulator uses publicly available battle mechanics for educational purposes only.

---

## 🎮 Features

### ✅ Implemented (Phases 1-3)
- ⚔️ **Accurate Battle Engine**: Gen 9 damage calculations and stat formulas
- 🎯 **Type System**: Complete type chart with 19 types
- 📊 **Pokemon Data**: 1,302 Pokemon, 937 moves, 367 abilities, 2,000 items
- 🌐 **Online Multiplayer**: Server-authoritative PvP battles
- 🔒 **Security**: Comprehensive validation and anti-cheat
- 🧪 **Testing**: 117 tests with 100% pass rate
- 🏰 **Lobby System**: Create/join lobbies with team validation
- 🔧 **Team Builder**: Create teams with EVs, IVs, natures, and moves
- 🎨 **Battle UI**: Complete battle interface with animations
- 🎵 **Audio System**: Music and sound effects

### 🚧 In Progress (Phase 4)
- ✅ **Move Effects**: 70+ competitive moves with 12 effect types
- 📝 **Abilities**: Implementing 50+ competitive abilities
- ✅ **Advanced Mechanics**: Weather, terrain, entry hazards

### 📋 Planned
- 🎬 **Battle Replays**: Record and share battles
- 🏆 **Ranked Ladder**: ELO-based matchmaking system

---

## 🚀 Project Status

**Current Phase**: Phase 4 - Polish & Competitive Features
**Overall Progress**: 87% (Week 13 of 14)
**Target Launch**: December 2025

**Phase 4 Week 1 (Move Effects) - ✅ COMPLETE**
- 🎉 Pluggable move effect framework with 12 effect types
- ⚔️ 70+ competitive moves configured (status, stats, recoil, drain, etc.)
- 🌦️ Weather, terrain, and entry hazard systems
- 🎯 Pokemon Showdown accuracy with deterministic RNG

See [PROJECT_PLAN.md](PROJECT_PLAN.md) for the complete roadmap.
See [PHASE_4_WEEK_1_SUMMARY.md](PHASE_4_WEEK_1_SUMMARY.md) for Week 1 details.
See [PHASE_3_SUMMARY.md](PHASE_3_SUMMARY.md) for Phase 3 details.

---

## 🛠️ Technology Stack

- **Game Engine**: Godot 4.x
- **Programming Language**: GDScript
- **Data Sources**:
  - [PokeAPI](https://pokeapi.co/) - Pokemon game data
  - [Pokemon Showdown Stats](https://www.smogon.com/stats/) - Competitive metadata
- **Networking**: Godot High-Level Multiplayer API
- **Data Pipeline**: Python 3.x with [uv](https://github.com/astral-sh/uv)

---

## 📁 Project Structure

```
pokemon-battle-simulator/
├── docs/                      # Documentation
│   ├── architecture.md        # System architecture
│   ├── battle_mechanics.md    # Pokemon battle rules
│   └── api_reference.md       # Code documentation
├── data_pipeline/             # Python data acquisition
│   ├── scripts/               # Download & transformation scripts
│   ├── cache/                 # Cached JSON data
│   └── pyproject.toml         # uv project file
├── godot_project/             # Main Godot 4 project
│   ├── scenes/                # Game scenes
│   ├── scripts/               # GDScript code
│   │   ├── core/              # Battle engine (headless)
│   │   ├── data/              # Data management
│   │   ├── networking/        # Server/client code
│   │   └── ui/                # UI controllers
│   ├── resources/             # Pokemon/move data (.tres files)
│   ├── autoloads/             # Singleton managers
│   └── tests/                 # Unit & integration tests
└── README.md                  # This file
```

---

## 🏃 Getting Started

### Prerequisites

- **Godot 4.x** - [Download](https://godotengine.org/download)
- **Python 3.11+** - [Download](https://www.python.org/downloads/)
- **uv** - Python package manager ([Install](https://github.com/astral-sh/uv))

### Setup (Phase 0 - Data Pipeline)

1. **Clone the repository**
   ```bash
   cd pokemon-battle-simulator
   ```

2. **Set up Python environment with uv**
   ```bash
   cd data_pipeline
   uv init
   uv add requests httpx ratelimit
   ```

3. **Download Pokemon data**
   ```bash
   uv run python scripts/download_pokeapi.py
   uv run python scripts/download_showdown_stats.py
   ```
   ⏱️ *This takes 2-3 hours with rate limiting*

4. **Transform data to Godot resources**
   ```bash
   uv run python scripts/transform_to_godot.py
   ```

5. **Open Godot project**
   ```bash
   cd ../godot_project
   godot .
   ```

---

## 🎯 Development Roadmap

### ✅ Phase 0: Foundation (Weeks 1-2) - **COMPLETE**
- ✅ Project setup and documentation
- ✅ Python data pipeline (4,606 resources generated)
- ✅ Data transformation to Godot resources
- ✅ Type chart and constants

### ✅ Phase 1: Battle Engine (Weeks 3-5) - **COMPLETE**
- ✅ Headless battle simulator
- ✅ Damage calculations (Gen 5-9 formulas)
- ✅ Turn resolution system with ActionQueue
- ✅ BattleEngine with event system

### ✅ Phase 2: UI & Client (Weeks 6-9) - **COMPLETE**
- ✅ Battle scene and animations
- ✅ Team builder with IV/EV/nature customization
- ✅ Battle UI with health bars and animations
- ✅ Audio system (music and SFX)

### ✅ Phase 3: Multiplayer (Weeks 10-12) - **COMPLETE**
- ✅ Server-authoritative networking
- ✅ Lobby and team validation system
- ✅ Online PvP battles
- ✅ Security validation (100% test coverage)
- ✅ Load testing (2,222 turns/second)

### 🚧 Phase 4: Polish (Weeks 13-14) - **IN PROGRESS**
- ✅ Week 1: Move effect framework (70+ competitive moves, 12 effect types)
- 🔴 Week 2: Ability system (50+ competitive abilities)
- 🔴 Week 3: Item effects (held items and battle items)
- 🔴 Week 4: Advanced mechanics and final polish

See [PROJECT_PLAN.md](PROJECT_PLAN.md) for detailed milestones.
See [PHASE_4_WEEK_1_SUMMARY.md](PHASE_4_WEEK_1_SUMMARY.md) for Week 1 completion details.
See [PHASE_3_SUMMARY.md](PHASE_3_SUMMARY.md) for Phase 3 completion details.

---

## 🏗️ Architecture

### Core Design Principles

1. **Decoupled Battle Engine**: Logic completely separate from UI
2. **Server-Authoritative**: All game logic on server to prevent cheating
3. **Deterministic Simulation**: Same inputs + seed = same outputs (enables replays)
4. **Resource-Based Data**: Godot .tres files for optimal performance
5. **Event-Driven**: Engine emits signals, UI responds

### System Flow

```
Data Pipeline (Python) → Godot Resources (.tres)
                              ↓
                    Battle Engine (Pure GDScript)
                              ↓
                    Battle Controller (Autoload)
                         ↙         ↘
                      UI Layer    Network Layer
```

---

## 🧪 Testing

**Test Coverage**: 100% (117/117 tests passing)

### Test Suites
- **Security Tests** (54 tests): Input validation, anti-cheat, injection prevention
- **Integration Tests** (53 tests): Complete battle flow from data loading to victory
- **Load Tests** (10 concurrent battles): Performance and stability validation

### Running Tests
```bash
# Security tests
godot --headless --path godot_project tests/test_security.tscn

# Integration tests
godot --headless --path godot_project tests/test_integration.tscn

# Load tests
godot --headless --path godot_project tests/test_load.tscn
```

### Performance Metrics
- **Throughput**: 2,222 turns/second
- **Success Rate**: 100%
- **Zero** desyncs or critical bugs

---

## 📚 Documentation

- [**PROJECT_PLAN.md**](PROJECT_PLAN.md) - Complete 14-week development plan
- [**PHASE_4_WEEK_1_SUMMARY.md**](PHASE_4_WEEK_1_SUMMARY.md) - Move effects framework completion
- [**PHASE_3_SUMMARY.md**](PHASE_3_SUMMARY.md) - Multiplayer system completion
- [**PROGRESS.md**](PROGRESS.md) - Current progress and tracking
- **docs/architecture.md** - System architecture (TBD)
- **docs/battle_mechanics.md** - Pokemon mechanics reference (TBD)

---

## 🤝 Contributing

This is currently a solo development project. Contributions may be accepted after the initial release (Phase 4 completion).

---

## 📝 License

This project is for educational purposes only. All Pokemon-related intellectual property belongs to Nintendo/Game Freak/The Pokemon Company.

The code in this repository is available under the MIT License (see LICENSE file).

---

## 🙏 Acknowledgments

- **Pokemon Showdown** - Reference implementation and battle mechanics
- **Smogon University** - Competitive battle strategies and data
- **PokeAPI** - Comprehensive Pokemon data API
- **Godot Engine** - Amazing open-source game engine

---

## 📞 Contact

- **Developer**: diyagamah
- **Email**: hivin.diyagama@tabcorp.com.au
- **GitHub**: [@diyagamah](https://github.com/diyagamah)

---

## 🗺️ Quick Navigation

- [View Project Plan](PROJECT_PLAN.md) - See the full roadmap
- [Track Progress](PROGRESS.md) - Current status and metrics
- [Report Issues](https://github.com/diyagamah/pokemon-battle-simulator/issues) - Bug reports (TBD)

---

*Last Updated: October 2, 2025*
