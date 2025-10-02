# Phase 3: Server-Authoritative Multiplayer - Implementation Strategy

**Project**: Pokemon Battle Simulator
**Phase**: 3 of 4 (Weeks 10-12)
**Duration**: 3 weeks
**Goal**: Working online PvP with server-authoritative architecture

---

## Executive Summary

Phase 3 transforms the single-player battle simulator into a fully functional online multiplayer game with server-authoritative architecture to prevent cheating. This document provides a detailed, day-by-day implementation plan with clear dependencies, technical decisions, and risk mitigation strategies.

**Key Deliverables**:
- Headless server build running BattleEngine
- Client build sending actions and receiving updates
- Lobby system for matchmaking
- Anti-cheat validation on server
- Stable multiplayer for 10+ concurrent battles

**Current Status**:
- Phase 2 complete: Full UI, team builder, battle system
- BattleEngine is headless and deterministic
- BattleController bridges engine and UI
- No networking code exists yet

---

## Table of Contents

1. [Week-by-Week Breakdown](#week-by-week-breakdown)
2. [Technical Architecture Decisions](#technical-architecture-decisions)
3. [File Creation Order](#file-creation-order)
4. [Testing Strategy](#testing-strategy)
5. [Risk Mitigation](#risk-mitigation)
6. [Success Metrics](#success-metrics)

---

## Week-by-Week Breakdown

### Week 10: Network Architecture & Server Foundation

**Goal**: Get server and client builds working, establish RPC communication

#### Day 1 (Monday): Export Presets & Feature Detection

**Tasks**:
1. Create headless server export preset
   - Disable display/audio
   - Set feature tag: `server`
   - Linux headless build
2. Create client export preset
   - Enable graphics/audio
   - Set feature tag: `client`
   - Windows/macOS builds
3. Add feature detection in main scene
4. Test local server and client builds

**Files to Create/Modify**:
- Modify `project.godot` (export presets)
- Create `scripts/Main.gd` (entry point with feature detection)

**Dependencies**: None
**Estimated Time**: 4-6 hours
**Risk**: Low - Godot 4 export system is well documented

**Acceptance Criteria**:
- Server build runs without graphics
- Client build runs with full UI
- Can launch both on same machine
- Feature tags work correctly

---

#### Day 2-3 (Tuesday-Wednesday): BattleServer Implementation

**Tasks**:
1. Create `BattleServer.gd` autoload
2. Implement peer connection handling
3. Create battle lobby data structure
4. Implement server-side BattleEngine instantiation
5. Add action validation logic
6. Create RPC methods for client→server communication
7. Write unit tests for validation logic

**Files to Create**:
- `scripts/networking/BattleServer.gd` (~400 lines)
- `scripts/networking/NetworkProtocol.gd` (~150 lines - constants/enums)
- `tests/test_battle_server.gd` (~200 lines)

**Dependencies**: Day 1 complete
**Estimated Time**: 12-16 hours
**Risk**: Medium - Complex state management

**Key Methods**:
```gdscript
# BattleServer.gd structure
- setup_network(port: int) -> void
- _on_peer_connected(peer_id: int) -> void
- _on_peer_disconnected(peer_id: int) -> void
- create_lobby(peer_id: int, team_data: Dictionary) -> int
- join_lobby(peer_id: int, lobby_id: int, team_data: Dictionary) -> bool
- start_battle(lobby_id: int) -> void
- @rpc("any_peer", "call_remote", "reliable") submit_action(battle_id: int, action_data: Dictionary)
- validate_action(battle_id: int, peer_id: int, action: BattleAction) -> bool
- execute_turn(battle_id: int) -> void
- @rpc("authority", "call_remote", "reliable") broadcast_battle_state(battle_id: int, state_data: Dictionary)
```

**Acceptance Criteria**:
- Server accepts peer connections
- Can create and manage lobbies
- Validates all client actions
- Executes BattleEngine turns authoritatively
- Unit tests pass for action validation

---

#### Day 4-5 (Thursday-Friday): BattleClient Implementation

**Tasks**:
1. Create `BattleClient.gd` autoload
2. Implement connection to server
3. Modify BattleController to use client when in multiplayer mode
4. Create RPC methods for server→client communication
5. Add network UI indicators (latency, connection status)
6. Handle disconnections and errors gracefully

**Files to Create**:
- `scripts/networking/BattleClient.gd` (~300 lines)
- `scripts/ui/NetworkStatusUI.gd` (~100 lines)

**Dependencies**: Day 2-3 complete
**Estimated Time**: 12-14 hours
**Risk**: Medium - Client-server synchronization

**Key Methods**:
```gdscript
# BattleClient.gd structure
- connect_to_server(ip: String, port: int) -> bool
- disconnect_from_server() -> void
- create_lobby(team_data: Dictionary) -> void
- join_lobby(lobby_id: int, team_data: Dictionary) -> void
- @rpc("any_peer", "call_remote", "reliable") submit_action_request(action_data: Dictionary)
- @rpc("authority", "call_remote", "reliable") receive_battle_state(state_data: Dictionary)
- @rpc("authority", "call_remote", "reliable") receive_turn_events(events: Array)
- @rpc("authority", "call_remote", "reliable") notify_error(message: String)
```

**Acceptance Criteria**:
- Client connects to server successfully
- Can send action requests
- Receives and displays battle state updates
- Handles disconnections without crashing
- Network status UI shows connection state

---

### Week 11: Lobby System & Matchmaking

**Goal**: Players can find each other and start battles

#### Day 6-7 (Monday-Tuesday): Lobby Scene & UI

**Tasks**:
1. Create lobby scene layout
2. Implement room creation UI
3. Add room browser (list of available lobbies)
4. Create "Join by code" functionality
5. Add team preview panel
6. Implement ready-up system
7. Add player list display

**Files to Create**:
- `scenes/lobby/LobbyScene.tscn`
- `scripts/ui/LobbyController.gd` (~350 lines)
- `scripts/ui/components/RoomListItem.gd` (~80 lines)
- `scripts/ui/components/PlayerListItem.gd` (~60 lines)

**Dependencies**: Week 10 complete
**Estimated Time**: 12-14 hours
**Risk**: Low - UI work similar to Phase 2

**Acceptance Criteria**:
- Can create a lobby with custom name
- Lobby browser shows available rooms
- Can join lobby by clicking or entering code
- Player list shows both players
- Ready button functional

---

#### Day 8-9 (Wednesday-Thursday): Server Lobby Management

**Tasks**:
1. Implement lobby state machine on server
2. Add lobby persistence (active lobbies list)
3. Create lobby broadcast system (when new lobby created)
4. Implement team validation on lobby join
5. Add auto-cleanup for abandoned lobbies
6. Handle edge cases (player disconnect, full lobby, etc.)

**Files to Modify**:
- `scripts/networking/BattleServer.gd` (+150 lines)
- Create `scripts/networking/LobbyManager.gd` (~250 lines)

**Dependencies**: Day 6-7 complete
**Estimated Time**: 12-14 hours
**Risk**: Medium - State synchronization

**Key Features**:
- Lobby lifecycle: WAITING → READY → IN_BATTLE → COMPLETED
- Automatic cleanup after 5 minutes inactive
- Team validation (6 Pokemon max, legal movesets, etc.)
- Handles disconnects gracefully

**Acceptance Criteria**:
- Server maintains accurate lobby list
- Lobbies are automatically cleaned up
- Team validation prevents illegal teams
- Lobby state is broadcast to all clients
- Edge cases handled gracefully

---

#### Day 10 (Friday): Basic Matchmaking

**Tasks**:
1. Implement quick match queue
2. Add matchmaking algorithm (simple FIFO for v1)
3. Create matchmaking UI (queue status)
4. Add estimated wait time display
5. Implement cancel queue functionality

**Files to Create**:
- `scripts/networking/Matchmaker.gd` (~200 lines)
- `scripts/ui/MatchmakingUI.gd` (~120 lines)

**Dependencies**: Day 8-9 complete
**Estimated Time**: 6-8 hours
**Risk**: Low - Simple implementation for Phase 3

**Acceptance Criteria**:
- Can queue for quick match
- Two players are matched within 30 seconds (if available)
- Can cancel queue
- UI shows queue status
- Auto-creates lobby when match found

---

### Week 12: Security, Testing & Polish

**Goal**: Secure server, stable multiplayer, production-ready

#### Day 11-12 (Monday-Tuesday): Security Hardening

**Tasks**:
1. Implement peer authentication (Godot 4 built-in)
2. Add rate limiting (max actions per second)
3. Validate all client data server-side
4. Add comprehensive server logging
5. Implement anti-spam measures
6. Test common exploit attempts

**Files to Create**:
- `scripts/networking/SecurityValidator.gd` (~300 lines)
- `scripts/networking/RateLimiter.gd` (~150 lines)
- `scripts/networking/ServerLogger.gd` (~100 lines)

**Dependencies**: Week 10-11 complete
**Estimated Time**: 12-16 hours
**Risk**: High - Security is critical

**Security Measures**:
- Team validation: Check for modified stats, illegal moves
- Action validation: Verify legality before execution
- Rate limiting: Max 10 actions/second per peer
- Authentication: Token-based peer verification
- Logging: All actions, errors, suspicious activity

**Acceptance Criteria**:
- Cannot submit illegal actions
- Cannot exceed rate limit
- All client data is validated
- Suspicious activity is logged
- Common exploits are blocked

---

#### Day 13-14 (Wednesday-Thursday): Integration Testing

**Tasks**:
1. Test 2-player battles on local network
2. Test multiple concurrent battles
3. Test edge cases (disconnects, lag, invalid actions)
4. Load testing (10+ concurrent battles)
5. Stress testing (rapid action submission)
6. Document all bugs found
7. Fix critical bugs

**Files to Create**:
- `tests/integration/test_multiplayer_battle.gd` (~300 lines)
- `tests/integration/test_lobby_system.gd` (~200 lines)
- `tests/stress/test_concurrent_battles.gd` (~150 lines)

**Dependencies**: Day 11-12 complete
**Estimated Time**: 12-16 hours
**Risk**: High - Unknown bugs may appear

**Test Scenarios**:
1. Normal battle (both players online, complete battle)
2. Player disconnect mid-battle
3. Invalid action submission
4. Simultaneous lobby creation
5. Network lag simulation
6. 10 concurrent battles
7. Rapid action submission (stress test)

**Acceptance Criteria**:
- All integration tests pass
- No desyncs in 100+ test battles
- Server handles 10+ concurrent battles
- Disconnects handled gracefully
- No critical bugs

---

#### Day 15 (Friday): Polish & Documentation

**Tasks**:
1. Add final UI polish
2. Improve error messages
3. Add reconnection logic (stretch goal)
4. Write network protocol documentation
5. Write server deployment guide
6. Create client connection troubleshooting guide
7. Final code review

**Files to Create**:
- `docs/NETWORK_PROTOCOL.md`
- `docs/SERVER_DEPLOYMENT.md`
- `docs/MULTIPLAYER_TROUBLESHOOTING.md`

**Dependencies**: Day 13-14 complete
**Estimated Time**: 6-8 hours
**Risk**: Low - Documentation and polish

**Acceptance Criteria**:
- All documentation complete
- Error messages are clear and helpful
- Code is well-commented
- Server deployment guide tested
- Phase 3 complete!

---

## Technical Architecture Decisions

### 1. Server Architecture

**Class: BattleServer (Autoload)**

```gdscript
# Hierarchy:
# BattleServer (Node, Autoload)
#   ├── ENetMultiplayerPeer (network peer)
#   ├── LobbyManager (manages lobbies)
#   ├── Matchmaker (quick match queue)
#   ├── SecurityValidator (validates actions)
#   └── ServerLogger (logs all activity)

# Data Structures:
var active_lobbies: Dictionary = {}  # lobby_id -> Lobby
var peer_to_lobby: Dictionary = {}  # peer_id -> lobby_id
var battle_engines: Dictionary = {}  # lobby_id -> BattleEngine

class Lobby:
    var id: int
    var name: String
    var player1_id: int
    var player2_id: int
    var player1_team: Array  # BattlePokemon
    var player2_team: Array  # BattlePokemon
    var state: LobbyState  # WAITING/READY/IN_BATTLE/COMPLETED
    var created_at: float
    var ready_states: Dictionary  # peer_id -> bool
```

**Key Methods**:

```gdscript
# Network Setup
func setup_network(port: int = 8910) -> void:
    """Initialize ENet server on specified port"""
    var peer = ENetMultiplayerPeer.new()
    var error = peer.create_server(port, 32)  # Max 32 players
    if error != OK:
        push_error("Failed to create server")
        return
    multiplayer.multiplayer_peer = peer
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

# Battle Management
func start_battle(lobby_id: int) -> void:
    """Initialize BattleEngine for lobby and start battle"""
    var lobby = active_lobbies[lobby_id]
    var engine = BattleEngine.new(randi())  # Random seed
    engine.initialize_battle(lobby.player1_team, lobby.player2_team)
    battle_engines[lobby_id] = engine
    lobby.state = LobbyState.IN_BATTLE

    # Notify both clients
    _broadcast_battle_start(lobby_id)

# Action Processing
func validate_action(battle_id: int, peer_id: int, action_data: Dictionary) -> bool:
    """Validate client action before execution"""
    # 1. Check battle exists
    # 2. Check player is in this battle
    # 3. Check action is legal (valid move index, has PP, etc.)
    # 4. Check rate limit
    # 5. Log action
    return SecurityValidator.validate(battle_id, peer_id, action_data)

# RPC Methods
@rpc("any_peer", "call_remote", "reliable")
func submit_action(battle_id: int, action_data: Dictionary) -> void:
    """Client submits action for validation and execution"""
    var peer_id = multiplayer.get_remote_sender_id()

    if not validate_action(battle_id, peer_id, action_data):
        notify_error.rpc_id(peer_id, "Invalid action")
        return

    # Store action and check if both players submitted
    _store_action(battle_id, peer_id, action_data)

    if _both_actions_ready(battle_id):
        execute_turn(battle_id)
```

---

### 2. Client Architecture

**Class: BattleClient (Autoload)**

```gdscript
# Hierarchy:
# BattleClient (Node, Autoload)
#   ├── ENetMultiplayerPeer (network peer)
#   └── NetworkStatusTracker (latency, connection state)

# State:
var is_connected: bool = false
var server_ip: String = ""
var server_port: int = 8910
var current_lobby_id: int = -1
var local_player_id: int = 1  # 1 or 2
var pending_action: BattleAction = null
```

**Key Methods**:

```gdscript
# Connection
func connect_to_server(ip: String, port: int = 8910) -> bool:
    """Connect to dedicated server"""
    var peer = ENetMultiplayerPeer.new()
    var error = peer.create_client(ip, port)
    if error != OK:
        return false

    multiplayer.multiplayer_peer = peer
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

    server_ip = ip
    server_port = port
    return true

# Action Submission
func submit_player_action(action: BattleAction) -> void:
    """Send action to server for validation"""
    if not is_connected:
        push_error("Not connected to server")
        return

    pending_action = action
    var action_data = _serialize_action(action)
    submit_action_request.rpc_id(1, current_lobby_id, action_data)

# RPC Methods (receive from server)
@rpc("authority", "call_remote", "reliable")
func receive_battle_state(state_data: Dictionary) -> void:
    """Receive full battle state from server"""
    BattleController.update_from_server_state(state_data)

@rpc("authority", "call_remote", "reliable")
func receive_turn_events(events: Array) -> void:
    """Receive turn execution events from server"""
    # Events like: MOVE_USED, DAMAGE_DEALT, POKEMON_FAINTED
    for event in events:
        BattleEvents.emit_event(event)

@rpc("authority", "call_remote", "reliable")
func notify_error(message: String) -> void:
    """Server rejected action or error occurred"""
    BattleController.handle_server_error(message)
    pending_action = null
```

---

### 3. BattleController Integration

**Modifications to BattleController.gd**:

```gdscript
# Add mode detection
enum BattleMode {
    LOCAL,      # Single player vs AI
    MULTIPLAYER # Online vs player
}

var battle_mode: BattleMode = BattleMode.LOCAL

# Modify submit_player_action
func submit_player_action(action: BattleAction) -> void:
    match battle_mode:
        BattleMode.LOCAL:
            # Original behavior - execute locally
            player_action = action
            opponent_action = _get_opponent_action()
            _execute_turn()

        BattleMode.MULTIPLAYER:
            # New behavior - send to server
            BattleClient.submit_player_action(action)
            # Wait for server response...

# Add server state handler
func update_from_server_state(state_data: Dictionary) -> void:
    """Update UI based on server state"""
    # Parse state_data
    # Update UI components
    # Trigger animations
    pass
```

---

### 4. Data Flow Diagrams

#### Client → Server → Client Communication

```
TURN EXECUTION FLOW:

1. Player 1 Action
   Client 1 → submit_action_request(action) → Server

2. Server Validation
   Server: validate_action() → Store action → Wait for P2

3. Player 2 Action
   Client 2 → submit_action_request(action) → Server

4. Server Execution
   Server: Both actions ready
       ↓
   BattleEngine.execute_turn(action1, action2)
       ↓
   Events emitted (MOVE_USED, DAMAGE_DEALT, etc.)
       ↓
   Serialize state + events

5. Broadcast to Clients
   Server → receive_turn_events(events) → Client 1
   Server → receive_turn_events(events) → Client 2

6. Client Animation
   Both clients animate events locally
```

#### Lobby Creation Flow

```
1. Player creates lobby
   Client → create_lobby(team_data) → Server

2. Server creates lobby
   Server: Generate lobby_id
       ↓
   Validate team_data
       ↓
   Create Lobby instance
       ↓
   Add to active_lobbies

3. Broadcast lobby list
   Server → update_lobby_list(lobbies) → All clients

4. Player 2 joins
   Client 2 → join_lobby(lobby_id, team_data) → Server

5. Server adds player
   Server: Validate team_data
       ↓
   Add player2 to lobby
       ↓
   Update lobby state

6. Notify lobby members
   Server → lobby_updated(lobby_data) → Client 1
   Server → lobby_updated(lobby_data) → Client 2
```

---

### 5. State Management

**What Lives on Server**:
- BattleEngine instances (one per active battle)
- BattleState (complete truth)
- Lobby management
- All validation logic
- RNG seeds for determinism

**What Lives on Client**:
- UI components
- Animation system
- Team builder
- Local action buffering
- Display state (synced from server)

**Key Principle**: Client is "dumb" - it only displays what server tells it and sends action requests. It never calculates damage, determines turn order, or validates actions.

---

## File Creation Order

### Critical Path (Must be Sequential)

1. **Day 1**: Export presets + Main.gd (foundation)
2. **Day 2-3**: BattleServer.gd (core server logic)
3. **Day 4-5**: BattleClient.gd (client communication)
4. **Day 6-7**: Lobby UI (depends on client)
5. **Day 8-9**: Server lobby management (depends on server)
6. **Day 10**: Matchmaking (depends on lobbies)
7. **Day 11-12**: Security (depends on all networking)
8. **Day 13-14**: Testing (depends on everything)

### Parallel Development Opportunities

**Can work simultaneously**:
- NetworkProtocol.gd (constants) - Day 2
- NetworkStatusUI.gd (UI component) - Day 4
- RoomListItem.gd + PlayerListItem.gd - Day 7
- SecurityValidator.gd + RateLimiter.gd - Day 11

**Cannot parallelize**:
- Server and client (client depends on server RPC signatures)
- Lobby UI and server lobby (need to agree on data format)
- Security and testing (security must be in place first)

---

## Testing Strategy

### Unit Tests

**BattleServer Validation Tests** (~200 lines)
```gdscript
# tests/test_battle_server.gd

func test_validate_legal_move_action():
    # Setup: Create mock battle with specific state
    # Action: Submit legal move action
    # Assert: validate_action returns true

func test_reject_invalid_move_index():
    # Setup: Create battle
    # Action: Submit move index 99 (invalid)
    # Assert: validate_action returns false

func test_reject_move_without_pp():
    # Setup: Pokemon with 0 PP on move 0
    # Action: Submit move 0
    # Assert: validate_action returns false

func test_reject_switch_to_fainted_pokemon():
    # Setup: Team with fainted Pokemon at index 2
    # Action: Submit switch to index 2
    # Assert: validate_action returns false

func test_rate_limiter():
    # Action: Submit 20 actions in 1 second
    # Assert: First 10 pass, rest rejected
```

**BattleClient Tests** (~150 lines)
```gdscript
# tests/test_battle_client.gd

func test_connection_success():
    # Setup: Mock server running
    # Action: connect_to_server("127.0.0.1", 8910)
    # Assert: is_connected == true

func test_connection_failure():
    # Setup: No server running
    # Action: connect_to_server("127.0.0.1", 8910)
    # Assert: is_connected == false, error emitted

func test_serialize_action():
    # Setup: Create BattleAction
    # Action: Serialize to Dictionary
    # Assert: All fields present and correct
```

---

### Integration Tests

**Multiplayer Battle Test** (~300 lines)
```gdscript
# tests/integration/test_multiplayer_battle.gd

func test_full_battle_flow():
    # 1. Start server
    var server = BattleServer.new()
    server.setup_network(8910)

    # 2. Connect two clients
    var client1 = BattleClient.new()
    var client2 = BattleClient.new()
    client1.connect_to_server("127.0.0.1", 8910)
    client2.connect_to_server("127.0.0.1", 8910)

    # 3. Create lobby
    client1.create_lobby(test_team1)
    await wait_for_signal(client1.lobby_created)

    # 4. Join lobby
    var lobby_id = client1.current_lobby_id
    client2.join_lobby(lobby_id, test_team2)
    await wait_for_signal(client2.lobby_joined)

    # 5. Start battle
    server.start_battle(lobby_id)
    await wait_for_signal(client1.battle_started)
    await wait_for_signal(client2.battle_started)

    # 6. Execute turn
    client1.submit_player_action(move_action(0))
    client2.submit_player_action(move_action(1))
    await wait_for_signal(client1.turn_completed)

    # 7. Assert: Both clients received same events
    assert_eq(client1.last_events, client2.last_events)

    # 8. Continue until battle ends
    # ...

    # 9. Cleanup
    server.cleanup()
    client1.disconnect()
    client2.disconnect()
```

**Lobby System Test** (~200 lines)
```gdscript
func test_lobby_creation_and_joining():
    # Test creating lobby, listing lobbies, joining lobby

func test_lobby_cleanup():
    # Test abandoned lobby is cleaned up after 5 minutes

func test_full_lobby_rejection():
    # Test third player cannot join 2-player lobby
```

---

### Manual Testing Checklist

**Pre-Launch Checklist**:
- [ ] Two players can complete a full battle
- [ ] Damage calculations match between server and client expectations
- [ ] Status effects work correctly
- [ ] Switching works correctly
- [ ] Battle ends when all Pokemon faint
- [ ] Winner is determined correctly
- [ ] Disconnection during battle handled gracefully
- [ ] Invalid actions are rejected with clear error messages
- [ ] Rate limiting prevents spam
- [ ] Modified client data is rejected
- [ ] Lobby system works reliably
- [ ] Matchmaking pairs players correctly
- [ ] No memory leaks after 10 battles
- [ ] Server remains stable under normal load

**Edge Cases**:
- [ ] Both players disconnect simultaneously
- [ ] Player submits action then immediately disconnects
- [ ] Network lag >500ms
- [ ] Invalid action submission
- [ ] Rapid connection/disconnection
- [ ] Lobby creation spam
- [ ] Modified team data (stat hacking attempt)

---

### Load Testing

**Test: 10 Concurrent Battles** (~150 lines)
```gdscript
# tests/stress/test_concurrent_battles.gd

func test_10_concurrent_battles():
    # 1. Start server
    var server = BattleServer.new()
    server.setup_network(8910)

    # 2. Create 20 clients (10 battles)
    var clients = []
    for i in range(20):
        var client = BattleClient.new()
        client.connect_to_server("127.0.0.1", 8910)
        clients.append(client)

    # 3. Create 10 lobbies
    for i in range(10):
        clients[i*2].create_lobby(random_team())
        await wait_for_signal(clients[i*2].lobby_created)
        var lobby_id = clients[i*2].current_lobby_id
        clients[i*2 + 1].join_lobby(lobby_id, random_team())

    # 4. Start all battles
    for i in range(10):
        var lobby_id = clients[i*2].current_lobby_id
        server.start_battle(lobby_id)

    # 5. Execute turns concurrently
    # Simulate 20 turns across all battles
    for turn in range(20):
        for i in range(20):
            clients[i].submit_player_action(random_action())

        # Wait for all turns to complete
        await wait_for_all_turns()

    # 6. Assert: All battles completed without errors
    # 7. Assert: Server performance metrics acceptable
    #    - Turn processing time < 100ms per turn
    #    - Memory usage < 500MB
    #    - No crashed battles
```

---

## Risk Mitigation

### Potential Blockers & Solutions

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|-------------------|
| **Network desync bugs** | HIGH - Breaks multiplayer | MEDIUM | Server-authoritative model, extensive testing, deterministic BattleEngine |
| **Godot 4 RPC changes** | HIGH - May require refactor | LOW | Use official docs, test early, fallback to Godot 3.x if needed |
| **Performance issues** | MEDIUM - Lag in battles | MEDIUM | Profile code, optimize hot paths, limit concurrent battles |
| **Security exploits** | HIGH - Cheating possible | MEDIUM | Comprehensive validation, rate limiting, logging, penetration testing |
| **Complex state sync** | MEDIUM - Hard to debug | HIGH | Detailed logging, replay determinism, unit tests for all edge cases |
| **Timeline too tight** | MEDIUM - Miss deadline | LOW | Daily progress tracking, cut matchmaking if needed, focus on core |

---

### Fallback Strategies

**If Week 10 falls behind**:
- Skip client export preset (test with editor only)
- Use localhost testing instead of LAN testing
- Defer security hardening to Week 12

**If Week 11 falls behind**:
- Simplify lobby UI (text-only, no fancy graphics)
- Skip matchmaking entirely (manual lobby joining only)
- Use hardcoded lobby IDs instead of dynamic

**If Week 12 falls behind**:
- Skip load testing (test with 2-3 battles only)
- Defer reconnection logic to Phase 4
- Launch with basic security, improve later

**Absolute Minimum for Phase 3 Success**:
1. Server accepts connections ✓
2. Two clients can battle ✓
3. Actions validated server-side ✓
4. No desyncs ✓

Everything else is polish.

---

### What to Cut if Timeline is Tight

**Priority 1 (Must Have)**:
- BattleServer.gd
- BattleClient.gd
- Basic lobby system (create/join)
- Action validation
- Turn execution

**Priority 2 (Should Have)**:
- Lobby browser
- Network status UI
- Security hardening
- Integration tests

**Priority 3 (Nice to Have)**:
- Matchmaking
- Load testing
- Reconnection logic
- Fancy lobby UI

**Cut Order** (if deadline approaches):
1. Matchmaking (can use manual lobbies)
2. Load testing (defer to Phase 4)
3. Reconnection (defer to Phase 4)
4. Lobby browser (use join by code only)

---

## Success Metrics

### Phase 3 Completion Criteria

#### Milestone 1: Server Foundation
- [ ] Headless server build runs without graphics
- [ ] Server accepts peer connections
- [ ] Server can instantiate BattleEngine
- [ ] Server validates actions correctly
- [ ] Unit tests pass (10+ tests)

**Measurement**: Can run server and connect 1 client

---

#### Milestone 2: Client Communication
- [ ] Client connects to server
- [ ] Client sends actions via RPC
- [ ] Client receives battle state updates
- [ ] Network status UI functional
- [ ] Disconnections handled gracefully

**Measurement**: Can send action from client and receive response

---

#### Milestone 3: Battle Execution
- [ ] Two clients can battle each other
- [ ] Server executes turns authoritatively
- [ ] Both clients see same battle state
- [ ] No desyncs in 10+ test battles
- [ ] Winner determined correctly

**Measurement**: Complete one full battle with no errors

---

#### Milestone 4: Lobby System
- [ ] Can create lobby
- [ ] Can join lobby
- [ ] Lobby browser shows lobbies
- [ ] Server manages lobby lifecycle
- [ ] Team validation works

**Measurement**: Two players can find each other and start battle

---

#### Milestone 5: Security & Stability
- [ ] Invalid actions rejected
- [ ] Rate limiting prevents spam
- [ ] Team data validated
- [ ] Server logging functional
- [ ] No critical exploits

**Measurement**: Cannot cheat or crash server with invalid data

---

### Acceptance Criteria for Each Milestone

**Week 10 Acceptance**:
```gdscript
# Can run this test successfully:
func test_week_10_complete():
    var server = BattleServer.new()
    server.setup_network(8910)

    var client = BattleClient.new()
    assert(client.connect_to_server("127.0.0.1", 8910))

    # Submit action
    client.submit_player_action(move_action(0))

    # Receive validation response
    await client.action_validated

    # Pass!
```

**Week 11 Acceptance**:
```gdscript
func test_week_11_complete():
    # Start server
    var server = BattleServer.new()
    server.setup_network(8910)

    # Two clients connect
    var c1 = BattleClient.new()
    var c2 = BattleClient.new()
    c1.connect_to_server("127.0.0.1", 8910)
    c2.connect_to_server("127.0.0.1", 8910)

    # Create and join lobby
    c1.create_lobby(team1)
    await c1.lobby_created
    c2.join_lobby(c1.current_lobby_id, team2)
    await c2.lobby_joined

    # Start battle
    server.start_battle(c1.current_lobby_id)

    # Execute one turn
    c1.submit_player_action(move_action(0))
    c2.submit_player_action(move_action(0))
    await c1.turn_completed

    # Pass!
```

**Week 12 Acceptance**:
```gdscript
func test_week_12_complete():
    # All integration tests pass
    run_all_tests("tests/integration/")

    # Security tests pass
    run_all_tests("tests/security/")

    # Can complete 10 battles without errors
    for i in range(10):
        complete_full_battle()

    # Pass!
```

---

### Quality Gates Before Phase 4

**Code Quality**:
- [ ] All classes documented with docstrings
- [ ] No compiler warnings
- [ ] Code follows GDScript style guide
- [ ] No hardcoded IPs/ports (use config)

**Testing**:
- [ ] 30+ unit tests passing
- [ ] 10+ integration tests passing
- [ ] No desyncs in 100+ test battles
- [ ] Load test completes (10 concurrent battles)

**Performance**:
- [ ] Server handles 10+ concurrent battles
- [ ] Turn execution < 100ms average
- [ ] Memory usage < 500MB with 10 battles
- [ ] Client FPS stable at 60

**Security**:
- [ ] All client data validated
- [ ] Rate limiting functional
- [ ] Exploit testing completed
- [ ] Server logging comprehensive

**Stability**:
- [ ] No crashes in 1-hour stress test
- [ ] Disconnects handled gracefully
- [ ] Error messages clear and helpful
- [ ] No memory leaks

**Documentation**:
- [ ] Network protocol documented
- [ ] Server deployment guide complete
- [ ] Troubleshooting guide complete
- [ ] Code comments thorough

---

## Implementation Checklist

### Pre-Week 10 Preparation
- [ ] Review Godot 4 high-level multiplayer API docs
- [ ] Review ENetMultiplayerPeer documentation
- [ ] Read Godot RPC best practices
- [ ] Set up test environment (two machines or VMs)
- [ ] Install network monitoring tools (Wireshark optional)

### Week 10 Deliverables
- [ ] Server build compiles and runs
- [ ] Client build compiles and runs
- [ ] BattleServer.gd complete (~400 lines)
- [ ] BattleClient.gd complete (~300 lines)
- [ ] NetworkProtocol.gd complete (~150 lines)
- [ ] Unit tests written and passing (~200 lines)
- [ ] Can connect client to server
- [ ] Can send and receive RPCs

### Week 11 Deliverables
- [ ] LobbyScene.tscn complete
- [ ] LobbyController.gd complete (~350 lines)
- [ ] LobbyManager.gd complete (~250 lines)
- [ ] Matchmaker.gd complete (~200 lines)
- [ ] Can create and join lobbies
- [ ] Can browse available lobbies
- [ ] Matchmaking pairs players

### Week 12 Deliverables
- [ ] SecurityValidator.gd complete (~300 lines)
- [ ] RateLimiter.gd complete (~150 lines)
- [ ] ServerLogger.gd complete (~100 lines)
- [ ] Integration tests complete (~500 lines)
- [ ] All security tests passing
- [ ] Documentation complete
- [ ] Phase 3 complete!

---

## Appendix: Reference Code Examples

### Example: BattleServer.gd Structure

```gdscript
extends Node

## BattleServer - Server-Authoritative Battle System
##
## Manages all multiplayer battles, lobbies, and client connections.
## All game logic runs on the server to prevent cheating.

# ==================== Constants ====================

const BattleEngineScript = preload("res://scripts/core/BattleEngine.gd")
const BattleActionScript = preload("res://scripts/core/BattleAction.gd")
const NetworkProtocol = preload("res://scripts/networking/NetworkProtocol.gd")

const MAX_PEERS = 32
const DEFAULT_PORT = 8910
const LOBBY_TIMEOUT = 300.0  # 5 minutes

# ==================== Enums ====================

enum LobbyState {
    WAITING,    # Waiting for second player
    READY,      # Both players present, waiting for start
    IN_BATTLE,  # Battle in progress
    COMPLETED   # Battle finished
}

# ==================== Data Structures ====================

class Lobby:
    var id: int
    var name: String
    var player1_id: int = -1
    var player2_id: int = -1
    var player1_team: Array = []
    var player2_team: Array = []
    var ready_states: Dictionary = {}  # peer_id -> bool
    var state: LobbyState = LobbyState.WAITING
    var created_at: float = 0.0

    func _init(p_id: int, p_name: String, p_player1_id: int):
        id = p_id
        name = p_name
        player1_id = p_player1_id
        created_at = Time.get_ticks_msec() / 1000.0

# ==================== State ====================

var active_lobbies: Dictionary = {}  # lobby_id -> Lobby
var peer_to_lobby: Dictionary = {}   # peer_id -> lobby_id
var battle_engines: Dictionary = {}  # lobby_id -> BattleEngine
var pending_actions: Dictionary = {} # lobby_id -> {player1: action, player2: action}

var next_lobby_id: int = 1

# ==================== Lifecycle ====================

func _ready() -> void:
    setup_network(DEFAULT_PORT)

func _process(delta: float) -> void:
    _cleanup_abandoned_lobbies()

# ==================== Network Setup ====================

func setup_network(port: int = DEFAULT_PORT) -> void:
    """Initialize ENet server on specified port"""
    var peer = ENetMultiplayerPeer.new()
    var error = peer.create_server(port, MAX_PEERS)

    if error != OK:
        push_error("[BattleServer] Failed to create server on port %d: %s" % [port, error])
        return

    multiplayer.multiplayer_peer = peer
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

    print("[BattleServer] Server started on port %d" % port)

# ==================== Peer Management ====================

func _on_peer_connected(peer_id: int) -> void:
    print("[BattleServer] Peer connected: %d" % peer_id)
    # TODO: Send server info to new peer

func _on_peer_disconnected(peer_id: int) -> void:
    print("[BattleServer] Peer disconnected: %d" % peer_id)
    _handle_peer_disconnect(peer_id)

func _handle_peer_disconnect(peer_id: int) -> void:
    """Handle player disconnect"""
    if not peer_to_lobby.has(peer_id):
        return

    var lobby_id = peer_to_lobby[peer_id]
    var lobby = active_lobbies[lobby_id]

    # TODO: Notify other player
    # TODO: End battle if in progress
    # TODO: Clean up lobby

# ==================== RPC Methods ====================

@rpc("any_peer", "call_remote", "reliable")
func create_lobby_request(lobby_name: String, team_data: Array) -> void:
    """Client requests to create a new lobby"""
    var peer_id = multiplayer.get_remote_sender_id()

    # Validate team data
    if not _validate_team_data(team_data):
        notify_error.rpc_id(peer_id, "Invalid team data")
        return

    # Create lobby
    var lobby_id = _create_lobby(peer_id, lobby_name, team_data)

    # Notify client
    lobby_created.rpc_id(peer_id, lobby_id)

    # Broadcast lobby list update
    _broadcast_lobby_list()

@rpc("any_peer", "call_remote", "reliable")
func join_lobby_request(lobby_id: int, team_data: Array) -> void:
    """Client requests to join existing lobby"""
    var peer_id = multiplayer.get_remote_sender_id()

    # Validate
    if not active_lobbies.has(lobby_id):
        notify_error.rpc_id(peer_id, "Lobby not found")
        return

    var lobby = active_lobbies[lobby_id]
    if lobby.state != LobbyState.WAITING:
        notify_error.rpc_id(peer_id, "Lobby not available")
        return

    if not _validate_team_data(team_data):
        notify_error.rpc_id(peer_id, "Invalid team data")
        return

    # Add player to lobby
    lobby.player2_id = peer_id
    lobby.player2_team = team_data
    lobby.state = LobbyState.READY
    peer_to_lobby[peer_id] = lobby_id

    # Notify both players
    lobby_joined.rpc_id(peer_id, lobby_id)
    player_joined.rpc_id(lobby.player1_id, peer_id)

    # Broadcast lobby list update
    _broadcast_lobby_list()

@rpc("any_peer", "call_remote", "reliable")
func submit_action(battle_id: int, action_data: Dictionary) -> void:
    """Client submits action for current turn"""
    var peer_id = multiplayer.get_remote_sender_id()

    # Validate
    if not _validate_action(battle_id, peer_id, action_data):
        notify_error.rpc_id(peer_id, "Invalid action")
        return

    # Store action
    _store_action(battle_id, peer_id, action_data)

    # Execute turn if both players submitted
    if _both_actions_ready(battle_id):
        _execute_turn(battle_id)

# ==================== Battle Management ====================

func _create_lobby(peer_id: int, lobby_name: String, team_data: Array) -> int:
    """Create a new lobby"""
    var lobby_id = next_lobby_id
    next_lobby_id += 1

    var lobby = Lobby.new(lobby_id, lobby_name, peer_id)
    lobby.player1_team = team_data

    active_lobbies[lobby_id] = lobby
    peer_to_lobby[peer_id] = lobby_id

    return lobby_id

func start_battle(lobby_id: int) -> void:
    """Initialize and start battle for lobby"""
    var lobby = active_lobbies[lobby_id]

    # Create battle engine
    var engine = BattleEngineScript.new(randi())
    engine.initialize_battle(
        _deserialize_team(lobby.player1_team),
        _deserialize_team(lobby.player2_team)
    )

    battle_engines[lobby_id] = engine
    lobby.state = LobbyState.IN_BATTLE
    pending_actions[lobby_id] = {}

    # Notify clients
    battle_started.rpc_id(lobby.player1_id, lobby_id)
    battle_started.rpc_id(lobby.player2_id, lobby_id)

func _execute_turn(battle_id: int) -> void:
    """Execute turn with both players' actions"""
    var engine = battle_engines[battle_id]
    var actions = pending_actions[battle_id]

    # Get both actions
    var action1 = _deserialize_action(actions["player1"])
    var action2 = _deserialize_action(actions["player2"])

    # Execute turn
    engine.execute_turn(action1, action2)

    # Collect events (emitted during turn)
    var events = _collect_turn_events()

    # Broadcast to both clients
    var lobby = active_lobbies[battle_id]
    receive_turn_events.rpc_id(lobby.player1_id, events)
    receive_turn_events.rpc_id(lobby.player2_id, events)

    # Clear pending actions
    pending_actions[battle_id] = {}

    # Check for battle end
    if engine.is_battle_over():
        _end_battle(battle_id)

# ==================== Validation ====================

func _validate_team_data(team_data: Array) -> bool:
    """Validate team composition"""
    if team_data.size() < 1 or team_data.size() > 6:
        return false

    # TODO: Check each Pokemon for:
    # - Legal stats (not modified)
    # - Legal moves (in learnset)
    # - Legal ability
    # - Legal item

    return true

func _validate_action(battle_id: int, peer_id: int, action_data: Dictionary) -> bool:
    """Validate action before execution"""
    # Check battle exists
    if not battle_engines.has(battle_id):
        return false

    # Check player is in this battle
    var lobby = active_lobbies[battle_id]
    if peer_id != lobby.player1_id and peer_id != lobby.player2_id:
        return false

    # Check action structure
    if not action_data.has("type"):
        return false

    # TODO: Validate specific action type
    # - Move: check index valid, has PP, etc.
    # - Switch: check index valid, not fainted

    return true

# ==================== Helper Methods ====================

func _both_actions_ready(battle_id: int) -> bool:
    """Check if both players have submitted actions"""
    var actions = pending_actions[battle_id]
    return actions.has("player1") and actions.has("player2")

func _store_action(battle_id: int, peer_id: int, action_data: Dictionary) -> void:
    """Store player's action for turn execution"""
    var lobby = active_lobbies[battle_id]

    if not pending_actions.has(battle_id):
        pending_actions[battle_id] = {}

    var player_key = "player1" if peer_id == lobby.player1_id else "player2"
    pending_actions[battle_id][player_key] = action_data

# ... (continues with serialization, cleanup, etc.)
```

---

## Conclusion

This implementation strategy provides a complete roadmap for Phase 3 development. The key success factors are:

1. **Server-authoritative architecture** prevents cheating
2. **Clear dependencies** enable efficient development
3. **Comprehensive testing** ensures stability
4. **Security-first approach** prevents exploits
5. **Fallback strategies** keep project on track

By following this plan day-by-day, Phase 3 will deliver a stable, secure multiplayer Pokemon battle simulator ready for Phase 4 polish and competitive features.

---

**Document Version**: 1.0
**Created**: 2025-10-02
**Last Updated**: 2025-10-02
**Status**: Ready for Implementation

---

*Implementation strategy created by Claude Code*
