# Phase 3: Multiplayer Implementation Guide

## Quick Navigation

This phase has 3 comprehensive documents to guide your implementation:

### 1. [PHASE_3_QUICK_START.md](PHASE_3_QUICK_START.md) ← **START HERE**
- Quick overview and daily checklist
- Success criteria and what to cut if behind
- Common pitfalls and solutions
- **Read this first** (10 minutes)

### 2. [PHASE_3_IMPLEMENTATION_STRATEGY.md](PHASE_3_IMPLEMENTATION_STRATEGY.md)
- Complete day-by-day breakdown (15 days)
- Detailed file creation order
- Testing strategy (unit, integration, load)
- Risk mitigation and fallback plans
- **Your main implementation guide** (30 minutes)

### 3. [PHASE_3_ARCHITECTURE.md](PHASE_3_ARCHITECTURE.md)
- Visual system diagrams
- Data flow sequences
- Class hierarchies
- Network protocol specifications
- **Reference when coding** (20 minutes)

---

## At a Glance

**Timeline**: 3 weeks (15 working days)
**Goal**: Online multiplayer Pokemon battles
**Total New Code**: ~2,750 lines
**Key Files**: 8 new networking scripts + 3 test suites

---

## Phase 3 Overview

### What You're Building

Transform the single-player battle simulator into a multiplayer game where:
- Two players battle online in real-time
- Server runs all game logic (anti-cheat)
- Lobby system for finding opponents
- Matchmaking for quick matches
- Secure, stable, and scalable

### Technical Approach

**Server-Authoritative Model**:
- Server owns all BattleEngine instances
- Server validates every action
- Clients only display what server sends
- Impossible to cheat

---

## Week Breakdown

### Week 10: Foundation
**Days 1-5** | Build server and client communication

Files to create:
- `BattleServer.gd` (400 lines)
- `BattleClient.gd` (300 lines)
- `NetworkProtocol.gd` (150 lines)

Goal: Client can connect and submit actions

---

### Week 11: Lobby System
**Days 6-10** | Build lobby and matchmaking

Files to create:
- `LobbyScene.tscn` + `LobbyController.gd` (350 lines)
- `LobbyManager.gd` (250 lines)
- `Matchmaker.gd` (200 lines)

Goal: Two players can find each other and battle

---

### Week 12: Security & Testing
**Days 11-15** | Harden and test

Files to create:
- `SecurityValidator.gd` (300 lines)
- `RateLimiter.gd` (150 lines)
- Integration tests (500+ lines)

Goal: Secure, stable, production-ready

---

## Key Architecture Decisions

### 1. Server Authority
**Decision**: Server runs all BattleEngine logic
**Why**: Prevents cheating, enables deterministic replay
**Impact**: Clients are "dumb" display-only

### 2. ENetMultiplayerPeer
**Decision**: Use Godot's built-in ENet networking
**Why**: Reliable UDP, battle-tested, easy to use
**Impact**: No external dependencies

### 3. RPC-Based Communication
**Decision**: Use Godot RPC system
**Why**: Simple, type-safe, built into engine
**Impact**: Clean separation of client and server methods

### 4. Lobby-Based Matchmaking
**Decision**: Lobbies + optional matchmaking queue
**Why**: Flexible (can play friends or ranked)
**Impact**: Slightly more complex than pure matchmaking

### 5. Full State Sync
**Decision**: Server sends complete battle state after each turn
**Why**: Guarantees synchronization, simple to debug
**Impact**: ~2 KB per turn (acceptable for turn-based)

---

## Success Metrics

### Minimum Viable (Must Have)
- [ ] Two clients can complete a full battle
- [ ] Server validates all actions
- [ ] No desyncs in 10+ battles
- [ ] Disconnects handled gracefully

### Full Success (Should Have)
- [ ] Lobby system functional
- [ ] Matchmaking works
- [ ] Security prevents exploits
- [ ] 10 concurrent battles stable

### Excellence (Nice to Have)
- [ ] Reconnection logic
- [ ] Advanced matchmaking (ELO)
- [ ] Spectator mode
- [ ] Battle replay download

---

## Critical Path

**Must follow this order** (dependencies):

```
1. Export Presets
   ↓
2. BattleServer
   ↓
3. BattleClient
   ↓
4. Lobby UI
   ↓
5. Server Lobby
   ↓
6. Matchmaking
   ↓
7. Security
   ↓
8. Testing
```

**Do NOT skip ahead** - each depends on the previous.

---

## Resource Requirements

### Development
- 2 test machines (or VMs) for LAN testing
- Text editor / Godot IDE
- Git for version control
- ~40-50 hours total time

### Production (Server)
- VPS with 1GB RAM ($5-10/month)
- Linux OS (Ubuntu recommended)
- Open port 8910 (TCP/UDP)
- Static IP or dynamic DNS

---

## Common Questions

### Q: Do I need a dedicated server to test?
**A**: No. Test on localhost (127.0.0.1) during development. Deploy to dedicated server for production.

### Q: Can I skip matchmaking and just use lobbies?
**A**: Yes! Matchmaking is Priority 3. Lobbies alone work fine.

### Q: What if I fall behind schedule?
**A**: See "What to Cut" section in Quick Start guide. Minimum: Server/Client + Basic Lobby.

### Q: How do I handle disconnections?
**A**: Server detects via `peer_disconnected` signal, forfeits the battle for disconnected player, notifies opponent.

### Q: Can the client calculate damage for preview?
**A**: NO. Client never calculates anything. Server is the only source of truth.

### Q: How many concurrent battles can the server handle?
**A**: ~100+ on a 1GB VPS. Each battle uses ~3.5 MB RAM.

### Q: What happens if both players disconnect?
**A**: Battle is automatically cleaned up after 5 minutes (lobby timeout).

---

## Testing Strategy

### Unit Tests (Day 2-3, Day 11-12)
- Test validation logic in isolation
- Mock BattleState and actions
- ~30 tests total

### Integration Tests (Day 13-14)
- Full battle flow (create lobby → battle → end)
- Disconnection scenarios
- Invalid action handling
- ~10 scenarios

### Load Tests (Day 14)
- 10 concurrent battles
- Stress test (rapid actions)
- Memory leak detection

### Manual Tests (Day 15)
- LAN testing with 2 machines
- Edge cases (lag, disconnects)
- Security exploits

---

## What Can Go Wrong

| Problem | Likelihood | Solution |
|---------|-----------|----------|
| **RPC signature mismatch** | Medium | Match exactly between client/server |
| **Desync bugs** | Low | Server is truth - client never calculates |
| **Network firewall** | Medium | Use 127.0.0.1 for testing, configure firewall for prod |
| **Performance issues** | Low | Profile with Godot profiler, optimize hot paths |
| **Timeline slip** | Medium | Cut Priority 3 features, focus on core |

---

## Daily Time Estimates

| Day | Task | Hours | Complexity |
|-----|------|-------|------------|
| 1 | Export Presets | 4-6 | Low |
| 2-3 | BattleServer | 12-16 | High |
| 4-5 | BattleClient | 12-14 | Medium |
| 6-7 | Lobby UI | 12-14 | Low |
| 8-9 | Server Lobby | 12-14 | Medium |
| 10 | Matchmaking | 6-8 | Low |
| 11-12 | Security | 12-16 | High |
| 13-14 | Testing | 12-16 | Medium |
| 15 | Documentation | 6-8 | Low |
| **Total** | | **88-112** | |

**Average**: ~7.5 hours/day for 15 days

---

## Next Steps

1. **Read PHASE_3_QUICK_START.md** (10 min)
   - Get daily checklist
   - Understand success criteria

2. **Skim PHASE_3_IMPLEMENTATION_STRATEGY.md** (30 min)
   - Understand full plan
   - Review Week 10 details

3. **Bookmark PHASE_3_ARCHITECTURE.md** (reference)
   - Use while coding
   - Refer to diagrams

4. **Start Day 1**: Export presets
   - Follow Quick Start checklist
   - Test both builds locally

5. **Continue day-by-day**
   - Check off tasks
   - Test continuously
   - Ask for help if stuck

---

## Support Resources

### Official Documentation
- [Godot Networking](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- [ENetMultiplayerPeer](https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html)
- [RPCs](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#remote-procedure-calls)

### Project Documentation
- [PROJECT_PLAN.md](PROJECT_PLAN.md) - Overall roadmap
- [PROGRESS.md](PROGRESS.md) - Current status
- [README.md](README.md) - Project overview

### Community
- [Godot Discord](https://discord.gg/godotengine) - #networking channel
- [Godot Forums](https://forum.godotengine.org/) - Networking section
- [r/godot](https://reddit.com/r/godot) - Reddit community

---

## Checklist Before Starting

- [ ] Read PHASE_3_QUICK_START.md
- [ ] Skim PHASE_3_IMPLEMENTATION_STRATEGY.md
- [ ] Review PHASE_3_ARCHITECTURE.md diagrams
- [ ] Phase 2 is complete (UI working)
- [ ] BattleEngine is stable
- [ ] Have 2 machines for testing (or 1 + VM)
- [ ] Understand server-authoritative model
- [ ] Ready to commit 40-50 hours over 3 weeks
- [ ] Git repository is clean

---

## Document Structure

```
PHASE_3_README.md              ← You are here
├── Quick navigation
├── Week summaries
├── Key decisions
├── Success metrics
└── Getting started

PHASE_3_QUICK_START.md         ← Start here
├── Daily checklist
├── Success criteria
├── Common pitfalls
└── What to cut if behind

PHASE_3_IMPLEMENTATION_STRATEGY.md  ← Main guide
├── Day-by-day breakdown
├── File creation order
├── Testing strategy
├── Risk mitigation
└── Code examples

PHASE_3_ARCHITECTURE.md        ← Reference
├── System diagrams
├── Data flow sequences
├── Class hierarchies
└── Network protocol
```

---

## Version History

- **v1.0** (2025-10-02): Initial release
  - 3 comprehensive documents
  - 15-day implementation plan
  - ~100 pages of documentation

---

## Ready to Start?

1. Open **PHASE_3_QUICK_START.md**
2. Follow Day 1 checklist
3. Test export presets
4. Move to Day 2

Good luck building multiplayer Pokemon battles!

---

*Phase 3 documentation created 2025-10-02*
*Total documentation: 4 files, ~80 KB, ~100 pages*
