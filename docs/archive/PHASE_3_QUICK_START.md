# Phase 3 Quick Start Guide

**Read this first**, then refer to [PHASE_3_IMPLEMENTATION_STRATEGY.md](PHASE_3_IMPLEMENTATION_STRATEGY.md) for detailed implementation.

---

## Overview

Transform the single-player Pokemon Battle Simulator into a multiplayer game with server-authoritative architecture in 3 weeks.

**Timeline**: Weeks 10-12 (15 working days)
**Goal**: Two players can battle online with anti-cheat

---

## Week-by-Week Summary

### Week 10: Foundation (Days 1-5)
**What**: Server and client builds, RPC communication
**Key Files**:
- `scripts/networking/BattleServer.gd` (400 lines)
- `scripts/networking/BattleClient.gd` (300 lines)
- Export presets for server and client

**Milestone**: Client can connect to server and submit actions

---

### Week 11: Lobbies (Days 6-10)
**What**: Lobby system and matchmaking
**Key Files**:
- `scenes/lobby/LobbyScene.tscn`
- `scripts/ui/LobbyController.gd` (350 lines)
- `scripts/networking/LobbyManager.gd` (250 lines)
- `scripts/networking/Matchmaker.gd` (200 lines)

**Milestone**: Two players can find each other and start battle

---

### Week 12: Security & Testing (Days 11-15)
**What**: Hardening, testing, documentation
**Key Files**:
- `scripts/networking/SecurityValidator.gd` (300 lines)
- `tests/integration/test_multiplayer_battle.gd` (300 lines)
- Documentation (3 files)

**Milestone**: Secure, stable multiplayer ready for launch

---

## Critical Path (Must Be Sequential)

```
Day 1: Export Presets
  ↓
Day 2-3: BattleServer
  ↓
Day 4-5: BattleClient
  ↓
Day 6-7: Lobby UI
  ↓
Day 8-9: Server Lobby Management
  ↓
Day 10: Matchmaking
  ↓
Day 11-12: Security
  ↓
Day 13-14: Testing
  ↓
Day 15: Documentation
```

**Do NOT skip ahead** - each step depends on the previous one.

---

## Architecture in 60 Seconds

### Server (BattleServer.gd)
- Runs headless (no graphics)
- Owns all BattleEngine instances
- Validates every client action
- Broadcasts results to clients

### Client (BattleClient.gd)
- Displays UI only
- Sends action requests to server
- Receives and animates events
- Never calculates damage or validates

### Key Principle
**Server is truth, client is display**

---

## Data Flow

```
1. Player clicks "Use Flamethrower"
   ↓
2. Client sends: submit_action_request(move_index: 0)
   ↓
3. Server validates: Is move legal? Has PP?
   ↓
4. Server waits for opponent action
   ↓
5. Server executes: BattleEngine.execute_turn(action1, action2)
   ↓
6. Server broadcasts: receive_turn_events([MOVE_USED, DAMAGE_DEALT, ...])
   ↓
7. Both clients animate events
```

---

## File Structure After Phase 3

```
scripts/networking/
├── BattleServer.gd         # Server-authoritative logic (400 lines)
├── BattleClient.gd         # Client communication (300 lines)
├── NetworkProtocol.gd      # Shared constants (150 lines)
├── LobbyManager.gd         # Lobby lifecycle (250 lines)
├── Matchmaker.gd           # Matchmaking queue (200 lines)
├── SecurityValidator.gd    # Action validation (300 lines)
├── RateLimiter.gd          # Anti-spam (150 lines)
└── ServerLogger.gd         # Activity logging (100 lines)

scenes/lobby/
└── LobbyScene.tscn         # Lobby UI

tests/integration/
├── test_multiplayer_battle.gd  # Full battle test (300 lines)
├── test_lobby_system.gd        # Lobby test (200 lines)
└── test_concurrent_battles.gd  # Load test (150 lines)

docs/
├── NETWORK_PROTOCOL.md
├── SERVER_DEPLOYMENT.md
└── MULTIPLAYER_TROUBLESHOOTING.md
```

**Total New Code**: ~2,750 lines

---

## Daily Checklist

### Day 1
- [ ] Create server export preset (headless, `server` tag)
- [ ] Create client export preset (full, `client` tag)
- [ ] Test both builds locally
- [ ] Create `Main.gd` with feature detection

### Day 2-3
- [ ] Write `BattleServer.gd` skeleton
- [ ] Implement `setup_network(port)`
- [ ] Add peer connection handlers
- [ ] Create lobby data structure
- [ ] Implement `validate_action()`
- [ ] Write RPC methods
- [ ] Write 10+ unit tests

### Day 4-5
- [ ] Write `BattleClient.gd` skeleton
- [ ] Implement `connect_to_server(ip, port)`
- [ ] Add RPC methods
- [ ] Integrate with BattleController
- [ ] Create NetworkStatusUI
- [ ] Test client-server communication

### Day 6-7
- [ ] Design lobby scene layout
- [ ] Create room browser UI
- [ ] Add join by code input
- [ ] Implement player list display
- [ ] Add ready-up button
- [ ] Test lobby UI

### Day 8-9
- [ ] Implement server lobby management
- [ ] Add lobby lifecycle (WAITING → READY → IN_BATTLE → COMPLETED)
- [ ] Create lobby broadcast system
- [ ] Add team validation
- [ ] Implement auto-cleanup (5 min timeout)
- [ ] Test lobby creation/joining

### Day 10
- [ ] Implement matchmaking queue
- [ ] Add FIFO matching algorithm
- [ ] Create matchmaking UI
- [ ] Add cancel queue button
- [ ] Test matchmaking

### Day 11-12
- [ ] Implement SecurityValidator
- [ ] Add rate limiting (10 actions/sec max)
- [ ] Create ServerLogger
- [ ] Test exploit attempts
- [ ] Validate all edge cases

### Day 13-14
- [ ] Write integration tests (3+ scenarios)
- [ ] Test 10 concurrent battles
- [ ] Test disconnections
- [ ] Test invalid actions
- [ ] Fix all critical bugs

### Day 15
- [ ] Write network protocol docs
- [ ] Write server deployment guide
- [ ] Write troubleshooting guide
- [ ] Final code review
- [ ] Phase 3 complete!

---

## Success Criteria

### Minimum Viable Multiplayer
- [ ] Two players can complete a full battle
- [ ] Server validates all actions
- [ ] No desyncs
- [ ] Disconnects handled gracefully

### Full Phase 3 Success
- [ ] Lobby system works reliably
- [ ] Matchmaking pairs players
- [ ] Security prevents common exploits
- [ ] 10+ concurrent battles stable
- [ ] All integration tests pass

---

## What Can Go Wrong (And Solutions)

| Problem | Solution |
|---------|----------|
| **Can't connect to server** | Check firewall, use 127.0.0.1 for testing |
| **Actions not executing** | Check RPC signatures match server/client |
| **Desyncs appearing** | Server is truth - client must display exactly what server sends |
| **Performance issues** | Profile with Godot profiler, optimize hot paths |
| **Running out of time** | Cut matchmaking, use manual lobbies only |

---

## What to Cut if Behind Schedule

**Priority 1 (Must Have)**:
- Server/client RPC communication ✓
- Basic lobby (create/join) ✓
- Action validation ✓

**Priority 2 (Should Have)**:
- Lobby browser
- Security hardening
- Integration tests

**Priority 3 (Nice to Have)**:
- Matchmaking
- Load testing
- Reconnection logic

**If running late**: Skip Priority 3, deliver Priority 1+2 minimum.

---

## Key Godot 4 APIs to Know

### ENetMultiplayerPeer
```gdscript
# Server
var peer = ENetMultiplayerPeer.new()
peer.create_server(port, max_peers)
multiplayer.multiplayer_peer = peer

# Client
var peer = ENetMultiplayerPeer.new()
peer.create_client(ip, port)
multiplayer.multiplayer_peer = peer
```

### RPC Calls
```gdscript
# Server → Client (broadcast)
@rpc("authority", "call_remote", "reliable")
func receive_battle_state(data: Dictionary):
    pass

# Client → Server
@rpc("any_peer", "call_remote", "reliable")
func submit_action(action_data: Dictionary):
    var peer_id = multiplayer.get_remote_sender_id()
    # Process...

# Call RPC
receive_battle_state.rpc_id(peer_id, data)  # To specific peer
receive_battle_state.rpc(data)  # To all peers
```

---

## Testing Approach

### Unit Tests (Day 2-3)
Test validation logic in isolation:
- Legal move acceptance
- Illegal move rejection
- Rate limiting
- Team validation

### Integration Tests (Day 13-14)
Test full workflows:
- Complete battle (2 players)
- Lobby creation/joining
- Disconnection handling
- Invalid action submission

### Load Tests (Day 14)
Stress test:
- 10 concurrent battles
- Rapid action submission
- Memory leak detection

---

## Common Pitfalls

1. **Client calculates damage** → Server desyncs
   - Solution: Only server calculates, client animates

2. **Missing RPC validation** → Security vulnerability
   - Solution: Validate every RPC parameter

3. **Not handling disconnects** → Server crashes
   - Solution: Always clean up peer data on disconnect

4. **Hardcoded IP addresses** → Can't change server
   - Solution: Use config file or UI input

5. **No rate limiting** → DDoS attacks possible
   - Solution: Implement RateLimiter early

---

## Resources

### Official Docs
- [Godot High-Level Multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- [ENetMultiplayerPeer](https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html)
- [RPCs](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#remote-procedure-calls)

### Project Files
- [PHASE_3_IMPLEMENTATION_STRATEGY.md](PHASE_3_IMPLEMENTATION_STRATEGY.md) - Detailed plan
- [PROJECT_PLAN.md](PROJECT_PLAN.md) - Overall roadmap
- [PROGRESS.md](PROGRESS.md) - Current status

---

## Next Steps

1. Read [PHASE_3_IMPLEMENTATION_STRATEGY.md](PHASE_3_IMPLEMENTATION_STRATEGY.md)
2. Start Day 1: Export presets
3. Follow daily checklist
4. Test continuously
5. Ship Phase 3!

---

**Questions?** Refer to detailed strategy document or Godot networking docs.

**Stuck?** Check troubleshooting section in strategy document.

**Behind schedule?** Review "What to Cut" section above.

---

*Quick start guide created 2025-10-02*
