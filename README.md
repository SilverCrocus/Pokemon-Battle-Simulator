# Pokemon Battle Simulator

A competitive Pokemon battle simulator built in Godot 4 with online multiplayer support.

> **⚠️ Legal Notice**: This is an educational project using **original creature designs and assets**. All Pokemon names, designs, and game mechanics are property of Nintendo/Game Freak/The Pokemon Company. This simulator uses publicly available battle mechanics for educational purposes only.

---

## 🎮 Features

### Current (Phase 0)
- 🏗️ Project structure and planning
- 📊 Data pipeline for Pokemon battle data

### Planned
- ⚔️ **Accurate Battle Simulation**: Damage calculations matching competitive standards
- 🌐 **Online Multiplayer**: Server-authoritative PvP battles
- 🔧 **Team Builder**: Create competitive teams with EVs, IVs, moves, and abilities
- 📊 **Competitive Data**: Top movesets and strategies from Pokemon Showdown stats
- 🎬 **Battle Replays**: Record and share battles
- 🏆 **Ranked Ladder**: ELO-based matchmaking system

---

## 🚀 Project Status

**Current Phase**: Phase 0 - Foundation & Data Acquisition
**Overall Progress**: 2% (Week 2 of 14)
**Target Launch**: January 2026

See [PROJECT_PLAN.md](PROJECT_PLAN.md) for the complete roadmap.
See [PROGRESS.md](PROGRESS.md) for current progress tracking.

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

### Phase 0: Foundation (Weeks 1-2) - **CURRENT**
- ✅ Project setup and documentation
- 🟡 Python data pipeline
- 🔴 Data transformation to Godot resources
- 🔴 Type chart and constants

### Phase 1: Battle Engine (Weeks 3-5)
- Headless battle simulator
- Damage calculations
- Turn resolution system
- 100+ unit tests

### Phase 2: UI & Client (Weeks 6-8)
- Battle scene and animations
- Team builder
- AI opponent
- Single-player mode

### Phase 3: Multiplayer (Weeks 9-11)
- Server-authoritative networking
- Lobby and matchmaking
- Online PvP battles

### Phase 4: Polish (Weeks 12-14)
- 200+ moves, 50+ abilities, 30+ items
- Battle replay system
- Ranked ladder
- Final polish and launch

See [PROJECT_PLAN.md](PROJECT_PLAN.md) for detailed milestones.

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

- **Unit Tests**: GUT (Godot Unit Testing) framework
- **Target Coverage**: 80%+
- **Integration Tests**: Full battle scenarios
- **Validation**: Results compared to Pokemon Showdown

```bash
# Run tests (once implemented)
godot --path godot_project -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

---

## 📚 Documentation

- [**PROJECT_PLAN.md**](PROJECT_PLAN.md) - Complete 14-week development plan
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

*Last Updated: October 1, 2025*
