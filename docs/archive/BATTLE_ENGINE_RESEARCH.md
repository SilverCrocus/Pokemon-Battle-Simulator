# Pokemon Battle Engine Research - Phase 1 Core Components

Research conducted: 2025-10-01
Focus: Gen 9 mechanics with Pokemon Showdown accuracy

## Table of Contents
1. [Battle Pokemon Instance Requirements](#1-battle-pokemon-instance-requirements)
2. [Stat Calculation Formulas](#2-stat-calculation-formulas)
3. [Damage Calculation Formula](#3-damage-calculation-formula)
4. [Turn Resolution Order](#4-turn-resolution-order)
5. [Implementation References](#5-implementation-references)

---

## 1. Battle Pokemon Instance Requirements

### 1.1 Runtime State Properties

A Pokemon instance during battle needs to track both **static species data** and **dynamic battle state**. Based on Pokemon Showdown's implementation (`sim/pokemon.ts`), the core runtime properties include:

#### Core Battle State
- **hp** (number): Current HP value (0 to maxhp)
- **maxhp** (number): Maximum HP (calculated from base stats, IVs, EVs, level)
- **status** (string | null): Non-volatile status condition
  - Values: 'psn' (poison), 'brn' (burn), 'par' (paralysis), 'slp' (sleep), 'frz' (freeze), 'tox' (badly poisoned)
  - Only one non-volatile status can be active at a time
  - Persists after switching out (unless Pokemon faints)

#### Stat Stages (BoostsTable)
- **boosts** (object): Stat stage modifications (-6 to +6 for each stat)
  - 'atk': Attack stage
  - 'def': Defense stage
  - 'spa': Special Attack stage
  - 'spd': Special Defense stage
  - 'spe': Speed stage
  - 'accuracy': Accuracy stage
  - 'evasion': Evasion stage
- Reset when Pokemon switches out or when Haze is used

#### Volatile Status Conditions
- **volatiles** (object): Map of active volatile conditions
  - Reset when Pokemon switches out
  - Examples: confusion, Taunt, Substitute, Leech Seed, Curse, etc.
  - Each volatile has an EffectState with:
    - `id`: string identifier
    - `duration`: number of turns remaining (optional)
    - Additional effect-specific properties

#### Identity Properties (Static)
- **species**: Pokemon species data (base stats, types, abilities)
- **level**: Pokemon's level (1-100)
- **ivs**: Individual Values object (6 stats, each 0-31)
- **evs**: Effort Values object (6 stats, each 0-252, total max 510)
- **nature**: Nature affecting stat multipliers
- **ability**: Current ability
- **item**: Held item
- **moves**: Array of move instances
- **gender**: 'M', 'F', or 'N'

### 1.2 Difference from Static Species Data

| Property Type | Static Species Data | Battle Pokemon Instance |
|--------------|---------------------|------------------------|
| **Base Stats** | Defined per species (e.g., Pikachu always has 35 HP base) | Not stored; used in calculations |
| **Types** | Defined per species (1-2 types) | Can change during battle (Terastallization in Gen 9) |
| **Abilities** | List of possible abilities | Specific ability instance (can change via Skill Swap, etc.) |
| **Moveset** | List of learnable moves | Specific 4 moves equipped |
| **IVs/EVs** | Not in species data | Individual to each Pokemon instance |
| **Current HP** | Not in species data | Runtime battle state |
| **Stat Stages** | Not in species data | Runtime battle state (resets on switch) |
| **Status** | Not in species data | Runtime battle state (persists on switch) |

---

## 2. Stat Calculation Formulas

### 2.1 Gen 9 Stat Formulas (Gen 3+ Formula)

All stat calculations use **floor/truncation** (round down) at specific points.

#### HP Calculation
```
HP = floor((2 × Base + IV + floor(EV ÷ 4)) × Level ÷ 100) + Level + 10
```

**Special case**: Shedinja always has 1 HP regardless of calculation.

#### Other Stats (Attack, Defense, Sp. Atk, Sp. Def, Speed)
```
Stat = floor((floor((2 × Base + IV + floor(EV ÷ 4)) × Level ÷ 100) + 5) × Nature)
```

### 2.2 Parameter Ranges and Validation

- **Base Stats**: Species-specific constants (typically 1-255)
- **IV (Individual Values)**: 0-31 for each stat
- **EV (Effort Values)**:
  - Per-stat maximum: 252 (increased from 255 in Gen 6+)
  - Total EV maximum: 510 across all 6 stats
  - Each 4 EVs = +1 stat point at level 100
- **Level**: 1-100
- **Nature Multiplier**: Applied after all other calculations

### 2.3 Nature Multipliers

Natures modify one stat by +10% and another by -10% (or are neutral).

| Nature Effect | Multiplier Value |
|--------------|------------------|
| Boosted stat | 1.1 |
| Lowered stat | 0.9 |
| Neutral stat | 1.0 |

**Implementation note**: The nature multiplier is applied AFTER the +5 is added, then the entire result is floored:
```
// Correct order of operations
temp = floor((2 × Base + IV + floor(EV ÷ 4)) × Level ÷ 100) + 5
Stat = floor(temp × Nature)
```

### 2.4 Stat Stage Multipliers (In-Battle Boosts)

During battle, stats can be modified by stages (-6 to +6). HP has no stages.

**Formula**: `multiplier = max(2, 2 + stage) / max(2, 2 - stage)`

| Stage | Numerator | Denominator | Multiplier | Percentage |
|-------|-----------|-------------|------------|------------|
| +6    | 8         | 2           | 4.0        | 400% |
| +5    | 7         | 2           | 3.5        | 350% |
| +4    | 6         | 2           | 3.0        | 300% |
| +3    | 5         | 2           | 2.5        | 250% |
| +2    | 4         | 2           | 2.0        | 200% |
| +1    | 3         | 2           | 1.5        | 150% |
| 0     | 2         | 2           | 1.0        | 100% |
| -1    | 2         | 3           | 0.667      | ~66.7% |
| -2    | 2         | 4           | 0.5        | 50% |
| -3    | 2         | 5           | 0.4        | 40% |
| -4    | 2         | 6           | 0.333      | ~33.3% |
| -5    | 2         | 7           | 0.286      | ~28.6% |
| -6    | 2         | 8           | 0.25       | 25% |

**Accuracy and Evasion stages**: Use a similar system but are combined (attacker's accuracy - defender's evasion) before the multiplier is applied. Minimum hit chance after all modifiers is 33%.

### 2.5 Minimum Stat Values

- **Minimum HP**: 11 (at level 1 with 0 base, 0 IV, 0 EV)
- **Minimum other stats**: 4 (at level 1 with 0 base, 0 IV, 0 EV, 0.9x nature)

---

## 3. Damage Calculation Formula

### 3.1 Gen 9 Core Damage Formula

```
Damage = floor(floor(floor(floor(2 × Level ÷ 5 + 2) × Power × A ÷ D) ÷ 50) + 2)
         × Modifiers
```

Where:
- **Level**: Attacker's level
- **Power**: Move's base power (after modifications)
- **A**: Attacker's effective Attack (physical) or Sp. Attack (special) stat
  - Includes stat stage multipliers
  - Affected by abilities, items, etc.
- **D**: Defender's effective Defense (physical) or Sp. Defense (special) stat
  - Includes stat stage multipliers
  - Affected by abilities, items, screens, etc.

### 3.2 Modifier Chain (Gen 9)

After base damage calculation, modifiers are applied in sequence:

```
Modifiers = Targets × PB × Weather × GlaiveRush × Critical × random
            × STAB × Type × Burn × other × ZMove × TeraShield
```

#### Individual Modifier Values

| Modifier | Value | Conditions |
|----------|-------|----------|
| **Targets** | 0.75 | Move hits multiple targets in Double/Triple battles |
|             | 0.5  | Move hits multiple targets in Battle Royals (Gen 7+) |
|             | 1.0  | Single target move |
| **PB** | 0.25 | Attacker is using Parental Bond (2nd hit only) |
|        | 1.0  | Otherwise |
| **Weather** | 1.5 | Water move in Rain, Fire move in Sun |
|             | 0.5 | Water move in Sun, Fire move in Rain |
|             | 1.0 | No weather effect |
| **GlaiveRush** | 2.0 | Target used Glaive Rush last turn |
|                | 1.0 | Otherwise |
| **Critical** | 1.5 | Critical hit (Gen 6+) |
|              | 1.0 | Normal hit |
| **random** | 0.85-1.0 | Random integer 85-100, then divide by 100 |
|            | 1.0  | Spit Up move (no variance) |
| **STAB** | 1.5 | Move type matches one of attacker's types |
|          | 2.0 | STAB with Adaptability ability |
|          | 2.0 | Terastallized into same type as original (Gen 9) |
|          | 1.0 | No STAB |
| **Type** | 0, 0.25, 0.5, 1, 2, 4 | Type effectiveness multiplier |
| **Burn** | 0.5 | Attacker is burned and using physical move (unless has Guts) |
|          | 1.0 | Otherwise |
| **TeraShield** | 0.2, 0.35, 0.75, 1.0 | Tera Raid boss shield mechanics (Gen 9) |

### 3.3 Critical Hit Mechanics (Gen 9)

#### Critical Hit Multiplier
- **Gen 6-9**: 1.5× damage (reduced from 2.0× in previous generations)

#### Critical Hit Stages and Probabilities

| Stage | Probability | How to Achieve |
|-------|------------|----------------|
| 0     | 1/24 (4.17%) | Default for most moves |
| +1    | 1/8 (12.5%)  | High crit ratio moves (Slash, Crabhammer, etc.) |
| +2    | 1/2 (50%)    | Stage +1 + Focus Energy/Dire Hit + Scope Lens/Razor Claw |
| +3    | Always crits | Stage +2 + Super Luck or stage +1 + Super Luck + Focus Energy + item |

**Critical Hit Bonuses**:
- Focus Energy / Dire Hit: +1 stage
- Scope Lens / Razor Claw: +1 stage
- Super Luck ability: +1 stage
- Leek (Farfetch'd/Sirfetch'd) / Lucky Punch (Chansey): +2 stages
- High crit ratio moves: Start at stage +1

**Critical Hit Effects**:
- Ignores target's positive Defense/Sp. Defense stat stages
- Ignores attacker's negative Attack/Sp. Attack stat stages
- Ignores Reflect, Light Screen, and Aurora Veil
- Cannot occur on certain moves (e.g., fixed damage moves)

### 3.4 Type Effectiveness Values

Type effectiveness is multiplicative:

- **Super Effective**: 2× per type (4× for double weakness)
- **Not Very Effective**: 0.5× per type (0.25× for double resistance)
- **No Effect**: 0× (move fails, deals no damage)
- **Neutral**: 1×

### 3.5 Rounding and Truncation Rules (Gen 9)

**Generation V+ rounding rules**:
1. **Flooring**: Round down (default for most operations)
2. **Round half down**: Round to nearest, 0.5 rounds down
3. **Round half up**: Round to nearest, 0.5 rounds up

**Default behavior**: Unless specified, all divisions and multiplications in the damage formula are **rounded to the nearest integer, with 0.5 rounding down**.

**Minimum damage**: If the final damage calculation results in 0, the move deals 1 HP damage (unless Type effectiveness is 0×).

### 3.6 Random Factor Implementation

The random factor introduces variance in damage:

```
random = (85 + randomInt(0, 15)) / 100
```

This creates a range of 85% to 100% of calculated damage, which is why the same move can deal slightly different damage each use.

**Implementation**:
```
randomValue = 85 + rand() % 16;  // Random integer 0-15
damage = damage * randomValue / 100;
damage = floor(damage);  // Truncate to integer
```

---

## 4. Turn Resolution Order

### 4.1 Turn Structure Overview

Each turn in a Pokemon battle follows this order:

1. **Pre-turn effects** (beginning of turn)
2. **Switches** (both players, speed order matters)
3. **Mega Evolution / Terastallization** (Gen 9)
4. **Move execution** (by priority, then speed)
5. **End of turn effects**

### 4.2 Priority System

Moves have hidden priority values ranging from **+5 to -7**. Most moves have priority 0.

**Priority Execution**:
- Higher priority moves ALWAYS execute before lower priority moves
- Within the same priority bracket, Speed determines order
- Priority is NOT affected by Trick Room (only speed order within a bracket is reversed)

**Common Priority Values**:
- **+5**: Helping Hand (Gen 9)
- **+4**: Protect, Detect, Endure, Magic Coat
- **+3**: Fake Out, Quick Guard, Wide Guard
- **+2**: Extreme Speed, Feint, Follow Me
- **+1**: Accelerock, Aqua Jet, Bullet Punch, Ice Shard, Mach Punch, Quick Attack, Vacuum Wave, Water Shuriken
- **0**: Most moves (default)
- **-1**: Vital Throw
- **-3**: Focus Punch
- **-4**: Avalanche, Revenge
- **-5**: Counter, Mirror Coat
- **-6**: Circle Throw, Dragon Tail, Roar, Whirlwind
- **-7**: Trick Room

### 4.3 Speed Resolution (Within Priority Bracket)

When multiple Pokemon use moves with the same priority:

1. **Compare Speed stats** (including stat stages and other modifiers)
2. **Dynamic Speed** (Gen 8+): Speed changes take effect immediately during the turn
3. **Speed tie**: If both Pokemon have identical Speed, winner is chosen randomly (50/50)

**Trick Room effect**: Reverses speed order within each priority bracket (slower moves first), but does NOT change priority order.

### 4.4 Switch Mechanics

Switching has special priority rules:

**Switch Priority**:
- Switches occur before any moves (except Pursuit under specific conditions)
- Switch priority is effectively **+6**
- When both players switch simultaneously, the player with the **faster Pokemon switches first**
  - This reveals speed tiers
  - Affects entry hazard damage order (e.g., Stealth Rock)
  - Affects ability activation order (e.g., Intimidate)

**Pursuit Exception**:
- Pursuit has priority +7 against a switching target
- Hits the target before it switches out
- Deals 2× damage when targeting a switching Pokemon

**Turn 1 Switches**:
- At battle start, both Pokemon enter simultaneously
- Speed order still matters for ability activation (e.g., Intimidate)

### 4.5 Move Selection Priority Order

When determining action order for the turn:

```
1. Switching (speed order if both switch)
2. Mega Evolution / Terastallization (happens after switching)
3. Pursuit (if targeting a switching Pokemon - priority +7)
4. Priority +5 moves
5. Priority +4 moves
   ...
6. Priority 0 moves (by speed)
   ...
7. Priority -7 moves (by speed)
```

### 4.6 Special Priority Modifiers

**Mycelium Might** (Gen 9 Ability):
- Pokemon with this ability using a **status move** always moves last within its priority bracket
- Multiple Mycelium Might users move in ascending Speed order (slowest first)

**Prankster** (Gen 5+ Ability):
- Status moves gain +1 priority
- In Gen 7+, Prankster moves fail against Dark-type targets

**Gale Wings** (Gen 6+ Ability):
- Flying-type moves gain +1 priority
- In Gen 7+, only works at full HP

### 4.7 Dynamic Speed Changes (Gen 8+)

**Critical difference from Gen 1-7**: In Generations 8 and 9, speed changes take effect **immediately** during the turn.

**Examples**:
- If Pokemon A uses Tailwind, Pokemon B (on the same side) benefits from the Speed boost immediately if it hasn't moved yet
- If a Pokemon's Speed is lowered/raised mid-turn, this affects move order for actions that haven't occurred yet

**Gen 1-7 behavior** (NOT used in Gen 9): Speed order was calculated at the start of the turn and didn't change mid-turn.

---

## 5. Implementation References

### 5.1 Pokemon Showdown Source Code

**Repository**: https://github.com/smogon/pokemon-showdown

**Key Files**:
- `sim/pokemon.ts`: Pokemon class definition with all battle state properties
- `sim/battle.ts`: Battle state management and turn execution
- `sim/SIM-PROTOCOL.md`: Documentation of battle protocol and state representation
- `data/abilities.ts`: Ability definitions and effects
- `data/moves.ts`: Move definitions with power, type, priority, etc.
- `sim/global-types.ts`: TypeScript type definitions for battle state

### 5.2 Bulbapedia References

**Damage Calculation**: https://bulbapedia.bulbagarden.net/wiki/Damage
- Complete damage formula with all modifiers
- Generation-specific differences
- Rounding rules and special cases

**Stat Calculation**: https://bulbapedia.bulbagarden.net/wiki/Stat
- Stat formulas for all generations
- Nature effects
- IV/EV mechanics

**Stat Modifiers**: https://bulbapedia.bulbagarden.net/wiki/Stat_modifier
- Stat stage mechanics
- Accuracy/evasion calculation
- Ability and item modifiers

**Priority**: https://bulbapedia.bulbagarden.net/wiki/Priority
- Complete list of priority values
- Special priority mechanics
- Generation differences

**Critical Hits**: https://bulbapedia.bulbagarden.net/wiki/Critical_hit
- Critical hit stages and probabilities
- Critical hit effects on damage
- Moves and abilities that affect critical hits

### 5.3 Community Resources

**Smogon University**: https://www.smogon.com/
- Competitive battling strategies
- Damage calculators
- Tier lists and usage statistics

**Pokemon Showdown Calculator**: https://calc.pokemonshowdown.com/
- Interactive damage calculator
- Supports all generations including Gen 9
- Shows damage ranges and KO probabilities

**Pikalytics**: https://www.pikalytics.com/
- VGC and singles usage statistics
- Damage calculator for Gen 9
- Common sets and movesets

### 5.4 Implementation Libraries

**poke-env** (Python): https://github.com/hsahovic/poke-env
- Python interface for Pokemon Showdown
- Battle state representation
- Useful for understanding battle state management

**Pokemon Showdown Client Protocol**: https://github.com/smogon/pokemon-showdown/blob/master/sim/SIM-PROTOCOL.md
- Message format for battle communication
- State updates and turn resolution
- Client-server interaction

---

## 6. Key Implementation Takeaways

### 6.1 Battle Pokemon Instance Must Track:

**Persistent State** (survives switching):
- Current HP
- Max HP
- Non-volatile status (burn, poison, etc.)
- IVs, EVs, Nature (used for stat calculation)
- Level, Species, Ability, Item, Moves

**Temporary Battle State** (resets on switch):
- Stat stage boosts (-6 to +6 for 5 stats + accuracy/evasion)
- Volatile status conditions (confusion, Taunt, Substitute, etc.)

**Calculated Stats** (computed from base + IV + EV + nature):
- HP, Attack, Defense, Sp. Attack, Sp. Defense, Speed

### 6.2 Critical Formula Details:

**Stat Calculation**:
- Use floor() at each division step
- Apply nature AFTER adding +5 to other stats
- HP formula is different (no nature, adds Level + 10)

**Damage Calculation**:
- Multiple floor() operations in base formula
- Modifiers applied in specific order
- Random factor: integer 85-100 divided by 100
- Minimum damage is 1 (unless type effectiveness is 0)

**Turn Order**:
- Priority first, then speed
- Switches happen before moves (except Pursuit)
- Speed ties are random
- Gen 8+ uses dynamic speed (changes apply immediately)

### 6.3 Validation Rules:

- IVs: 0-31 per stat (no total limit)
- EVs: 0-252 per stat, max 510 total
- Stat stages: -6 to +6 (clamped)
- HP: Cannot exceed maxhp, minimum 0
- Status: Only one non-volatile status at a time
- Level: 1-100

### 6.4 Gen 9 Specific Mechanics:

- Critical hits are 1.5× (not 2.0× like older gens)
- Terastallization changes STAB rules and type effectiveness
- Dynamic speed (speed changes apply mid-turn)
- Tera STAB: 2.0× when Terastallized into original type
- Some moves boosted to 60 base power when Terastallized

---

## Research Sources

1. Bulbapedia - Pokemon Stat Mechanics: https://bulbapedia.bulbagarden.net/wiki/Stat
2. Bulbapedia - Damage Calculation: https://bulbapedia.bulbagarden.net/wiki/Damage
3. Bulbapedia - Stat Modifiers: https://bulbapedia.bulbagarden.net/wiki/Stat_modifier
4. Bulbapedia - Priority: https://bulbapedia.bulbagarden.net/wiki/Priority
5. Bulbapedia - Critical Hit: https://bulbapedia.bulbagarden.net/wiki/Critical_hit
6. Pokemon Showdown GitHub: https://github.com/smogon/pokemon-showdown
7. Serebii.net - Statistics: https://www.serebii.net/games/stats.shtml
8. Serebii.net - Damage Calculation: https://serebii.net/games/damage.shtml
9. Serebii.net - Critical Hits: https://www.serebii.net/games/criticalhits.shtml
10. Dragon Fly Cave - Battle Mechanics: https://www.dragonflycave.com/mechanics/battle
11. Smogon University - Pokemon Showdown: https://www.smogon.com/sim/ps_guide
12. Pokemon Damage Calculator: https://calc.pokemonshowdown.com/

Research completed: 2025-10-01
