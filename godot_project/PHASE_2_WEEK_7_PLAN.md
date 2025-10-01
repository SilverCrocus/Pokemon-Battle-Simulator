# Phase 2 Week 7: Team Builder UI - Implementation Plan

## Overview
Create a complete team building interface that allows players to:
- Browse all 1,302 Pokemon
- Create teams of up to 6 Pokemon
- Customize EVs, IVs, natures, moves, abilities, and held items
- Save and load teams to/from JSON files
- Validate team legality

## Target Completion
**Duration**: 4-5 days
**Lines of Code**: ~1,500-2,000 lines

## File Structure

```
godot_project/
├── scenes/
│   └── team_builder/
│       └── TeamBuilderScene.tscn
├── scripts/
│   ├── ui/
│   │   └── TeamBuilderController.gd (main controller, ~300 lines)
│   └── ui/components/
│       ├── PokemonBrowser.gd (~250 lines)
│       ├── PokemonCard.gd (~100 lines)
│       ├── PokemonEditor.gd (~400 lines)
│       ├── MoveSelector.gd (~200 lines)
│       ├── StatSliders.gd (~200 lines)
│       ├── TeamPreview.gd (~150 lines)
│       └── TeamSlot.gd (~100 lines)
└── data/
    └── teams/
        └── (saved team JSON files)
```

## Component Breakdown

### 1. TeamBuilderScene.tscn
**Layout**: Three-panel design
- **Left Panel (30%)**: Pokemon Browser
- **Center Panel (45%)**: Pokemon Editor
- **Right Panel (25%)**: Team Preview

### 2. PokemonBrowser Component
**Purpose**: Browse and search Pokemon

**Features**:
- Search bar (filter by name/ID)
- Type filter dropdown (19 types + "All")
- Generation filter (Gen 1-9 + "All")
- Tier filter (Showdown tiers: OU, UU, RU, etc.)
- Sort options (Name, Number, HP, Atk, Def, SpA, SpD, Spe)
- Scrollable grid of PokemonCard components

**UI Elements**:
- LineEdit for search
- OptionButton for filters
- GridContainer with PokemonCards
- ScrollContainer for vertical scrolling

**Data Source**: DataManager.get_all_pokemon()

### 3. PokemonCard Component
**Purpose**: Display Pokemon thumbnail in browser

**Shows**:
- Pokemon sprite placeholder (colored box by type for now)
- Pokemon name
- Pokemon number (#001-#1302)
- Type badges (1-2 types)

**Interaction**: Click to load in editor

### 4. PokemonEditor Component (Center Panel)
**Purpose**: Customize selected Pokemon

**Sections**:

**A) Basic Info**:
- Pokemon name display
- Base stats display (read-only)
- Level selector (default: 50)
- Nickname field (optional)
- Gender selector (if applicable)

**B) Nature Selector**:
- OptionButton with 25 natures
- Show stat changes (+10% / -10%)

**C) Ability Selector**:
- OptionButton with normal abilities (1-2)
- Checkbox for hidden ability

**D) Move Selector** (MoveSelector component):
- 4 move slots
- Click slot to open move picker
- Filter moves by learnset legality
- Show move type, power, accuracy, PP

**E) EV/IV Sliders** (StatSliders component):
- 6 sliders for HP/Atk/Def/SpA/SpD/Spe
- EV: 0-252 per stat, max 508 total
- IV: 0-31 per stat (default 31)
- Preset buttons: 252/252/4, 252/0/0, etc.

**F) Item Selector**:
- OptionButton with competitive items
- Filter: Held items only

**G) Action Buttons**:
- "Add to Team" button
- "Clear" button

### 5. MoveSelector Component
**Purpose**: Select 4 moves for Pokemon

**Features**:
- 4 move slot buttons
- Move picker dialog when clicking slot
- Filter by:
  - Legal moves only (from learnset)
  - Move type
  - Move category (Physical/Special/Status)
- Search bar
- Move details panel:
  - Name, Type, Category
  - Power, Accuracy, PP
  - Effect description

**Validation**:
- Only allow moves the Pokemon can learn
- No duplicate moves

### 6. StatSliders Component
**Purpose**: Set EVs and IVs with validation

**EV Sliders**:
- 6 HSlider controls (HP, Atk, Def, SpA, SpD, Spe)
- Range: 0-252
- Total counter showing sum (max 508)
- Prevent going over 508 total
- Preset buttons:
  - Offensive: 252 Atk/SpA, 252 Spe, 4 HP
  - Defensive: 252 HP, 252 Def/SpD, 4 Spe
  - Balanced: 170/170/170

**IV Sliders**:
- 6 HSlider controls
- Range: 0-31
- Default: 31 (perfect IVs)
- Button to set all to 31
- Button to set all to 0 (for trick room/speed control)

**Real-time Stat Calculation**:
- Show calculated stats based on:
  - Base stats
  - IVs
  - EVs
  - Nature
  - Level

### 7. TeamPreview Component
**Purpose**: Show current team roster

**Features**:
- 6 TeamSlot components
- Drag-to-reorder functionality
- Click slot to edit Pokemon
- Remove button per slot
- Team type coverage visualization
- Team stats summary (avg Speed, total HP, etc.)

### 8. TeamSlot Component
**Purpose**: Display one Pokemon in team

**Shows**:
- Pokemon sprite placeholder
- Pokemon name
- Level
- 4 move names (abbreviated)
- Remove button (X)

**Interactions**:
- Click to edit in center panel
- Drag to reorder

## Data Structures

### Team JSON Format
```json
{
  "name": "My Team",
  "format": "OU",
  "pokemon": [
    {
      "species_id": 25,
      "nickname": "Sparky",
      "level": 50,
      "gender": "M",
      "nature": "Jolly",
      "ability": "Lightning Rod",
      "item": "Life Orb",
      "moves": [33, 85, 98, 231],
      "evs": {"hp": 4, "atk": 252, "def": 0, "spa": 0, "spd": 0, "spe": 252},
      "ivs": {"hp": 31, "atk": 31, "def": 31, "spa": 31, "spd": 31, "spe": 31}
    }
  ]
}
```

### BattlePokemon Integration
Team Builder creates `BattlePokemon` instances using:
```gdscript
var pokemon = BattlePokemon.new(
    species_data,
    level,
    ivs,
    evs,
    nature,
    moves,
    ability,
    item,
    nickname
)
```

## Implementation Steps

### Day 1: Core Structure & Browser
- [x] Create TeamBuilderScene.tscn with 3-panel layout
- [ ] Implement TeamBuilderController.gd
- [ ] Create PokemonBrowser component
- [ ] Create PokemonCard component
- [ ] Implement search and filter logic
- [ ] Test browsing all 1,302 Pokemon

### Day 2: Pokemon Editor (Part 1)
- [ ] Create PokemonEditor component
- [ ] Implement basic info section
- [ ] Add nature selector
- [ ] Add ability selector
- [ ] Add item selector
- [ ] Test data binding

### Day 3: Pokemon Editor (Part 2) & Moves
- [ ] Create MoveSelector component
- [ ] Implement move picker dialog
- [ ] Add learnset validation
- [ ] Create StatSliders component
- [ ] Implement EV/IV sliders with validation
- [ ] Add preset buttons

### Day 4: Team Management
- [ ] Create TeamPreview component
- [ ] Create TeamSlot component
- [ ] Implement "Add to Team" functionality
- [ ] Add drag-to-reorder
- [ ] Implement team validation
- [ ] Add remove Pokemon functionality

### Day 5: Save/Load & Polish
- [ ] Implement team save to JSON
- [ ] Implement team load from JSON
- [ ] Add team name editor
- [ ] Add format selector (OU, VGC, etc.)
- [ ] Create main menu integration
- [ ] Add keyboard shortcuts
- [ ] Bug fixes and polish

## Testing Checklist

### Functionality Tests
- [ ] Can browse all 1,302 Pokemon
- [ ] Search filters work correctly
- [ ] Type/Gen/Tier filters work
- [ ] Can select and edit Pokemon
- [ ] Nature changes stat calculations
- [ ] EV validation (max 252 per stat, 508 total)
- [ ] IV sliders work (0-31)
- [ ] Move selection validates learnset
- [ ] Can add 6 Pokemon to team
- [ ] Cannot add 7th Pokemon
- [ ] Can remove Pokemon from team
- [ ] Can reorder team
- [ ] Can save team to JSON
- [ ] Can load team from JSON
- [ ] Stat calculation is accurate

### Edge Cases
- [ ] Empty team handling
- [ ] Illegal move selection blocked
- [ ] EV total > 508 prevented
- [ ] Duplicate move prevented
- [ ] Save with empty team
- [ ] Load corrupted JSON

### UI/UX Tests
- [ ] Responsive layout
- [ ] Smooth scrolling
- [ ] Clear visual feedback
- [ ] Intuitive navigation
- [ ] Helpful error messages

## Integration Points

### With Existing Systems
- **DataManager**: Load Pokemon, moves, items, abilities
- **StatCalculator**: Calculate stats from EVs/IVs/nature
- **BattlePokemon**: Create instances for battles
- **BattleController**: Start battle with saved team

### Future Integration (Phase 2 Week 8)
- AI opponent can use saved teams
- Import from Pokemon Showdown paste
- Export team code for sharing
- Team validation for specific formats

## Success Criteria

✅ **Phase 2 Week 7 Complete When:**
1. Can create a full team of 6 Pokemon
2. All customization options work (moves, EVs, IVs, nature, ability, item)
3. Team validation works (legal moves, EV limits)
4. Can save/load teams from JSON
5. UI is functional and intuitive
6. No critical bugs
7. Integration with BattleController works

## Next Steps (Phase 2 Week 8)
After Week 7, we'll implement:
- AI opponent system
- Main menu & game flow
- Audio system
- Visual polish
