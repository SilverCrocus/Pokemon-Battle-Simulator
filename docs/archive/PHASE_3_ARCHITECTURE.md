# Phase 3: Multiplayer Architecture

Visual diagrams and technical architecture for server-authoritative Pokemon battles.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         GAME CLIENTS                            │
│                                                                 │
│  ┌──────────────────┐              ┌──────────────────┐        │
│  │   Player 1 PC    │              │   Player 2 PC    │        │
│  │                  │              │                  │        │
│  │  ┌────────────┐  │              │  ┌────────────┐  │        │
│  │  │Battle UI   │  │              │  │Battle UI   │  │        │
│  │  │Team Builder│  │              │  │Team Builder│  │        │
│  │  │Lobby UI    │  │              │  │Lobby UI    │  │        │
│  │  └────────────┘  │              │  └────────────┘  │        │
│  │        ↑         │              │        ↑         │        │
│  │        │         │              │        │         │        │
│  │  ┌─────▼──────┐  │              │  ┌─────▼──────┐  │        │
│  │  │BattleClient│  │              │  │BattleClient│  │        │
│  │  │ (Autoload) │  │              │  │ (Autoload) │  │        │
│  │  └─────┬──────┘  │              │  └─────┬──────┘  │        │
│  └────────┼─────────┘              └────────┼─────────┘        │
│           │                                  │                  │
│           │  RPC: submit_action()           │                  │
│           │  RPC: create_lobby()            │                  │
│           └──────────────┬───────────────────┘                  │
│                          │                                      │
└──────────────────────────┼──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DEDICATED SERVER                           │
│                      (Headless Build)                           │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    BattleServer (Autoload)                │ │
│  │                                                           │ │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │ │
│  │  │LobbyManager │  │ Matchmaker   │  │SecurityValidator│ │
│  │  │             │  │              │  │                │  │ │
│  │  │- Lobbies    │  │- Queue       │  │- Validation    │  │ │
│  │  │- Teams      │  │- Matching    │  │- Rate Limit    │  │ │
│  │  └─────────────┘  └──────────────┘  └────────────────┘  │ │
│  │                                                           │ │
│  │  ┌────────────────────────────────────────────────────┐  │ │
│  │  │         Active Battle Engines                      │  │ │
│  │  │                                                    │  │ │
│  │  │  Battle 1 (Lobby #42)    Battle 2 (Lobby #43)     │  │ │
│  │  │  ┌───────────────┐       ┌───────────────┐        │  │ │
│  │  │  │ BattleEngine  │       │ BattleEngine  │        │  │ │
│  │  │  │   (headless)  │       │   (headless)  │        │  │ │
│  │  │  └───────────────┘       └───────────────┘        │  │ │
│  │  │                                                    │  │ │
│  │  │  ... (up to 10+ concurrent battles)               │  │ │
│  │  └────────────────────────────────────────────────────┘  │ │
│  │                          │                                │ │
│  │                          ▼                                │ │
│  │                  RPC: receive_battle_state()              │ │
│  │                  RPC: receive_turn_events()               │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Battle Flow Sequence

### 1. Lobby Creation & Joining

```
Player 1                  Server                    Player 2
   │                         │                          │
   │  create_lobby_request() │                          │
   ├────────────────────────>│                          │
   │                         │                          │
   │                         │ Create Lobby #42         │
   │                         │ Validate team            │
   │                         │                          │
   │    lobby_created(42)    │                          │
   │<────────────────────────┤                          │
   │                         │                          │
   │                         │ Broadcast lobby list     │
   │                         ├─────────────────────────>│
   │                         │                          │
   │                         │   join_lobby_request(42) │
   │                         │<─────────────────────────┤
   │                         │                          │
   │                         │ Add Player 2 to lobby    │
   │                         │ Validate team            │
   │                         │                          │
   │  player_joined(P2)      │     lobby_joined(42)     │
   │<────────────────────────┼─────────────────────────>│
   │                         │                          │
   │  Ready!                 │                  Ready!  │
   │                         │                          │
```

---

### 2. Battle Start

```
Player 1                  Server                    Player 2
   │                         │                          │
   │  Both players ready     │                          │
   │                         │                          │
   │                         │ Create BattleEngine      │
   │                         │ engine = new(seed)       │
   │                         │ initialize_battle(       │
   │                         │   team1, team2)          │
   │                         │                          │
   │   battle_started(42)    │    battle_started(42)    │
   │<────────────────────────┼─────────────────────────>│
   │                         │                          │
   │ Display battle UI       │              Display UI  │
   │ Show opponent's Pokemon │     Show opponent's Mon  │
   │                         │                          │
```

---

### 3. Turn Execution

```
Player 1                  Server                    Player 2
   │                         │                          │
   │ Click "Flamethrower"    │                          │
   │                         │                          │
   │  submit_action(MOVE,0)  │                          │
   ├────────────────────────>│                          │
   │                         │                          │
   │                         │ Validate action          │
   │                         │ ✓ Legal move             │
   │                         │ ✓ Has PP                 │
   │                         │ ✓ Not rate limited       │
   │                         │                          │
   │                         │ Store P1 action          │
   │                         │ Wait for P2...           │
   │                         │                          │
   │                         │      Click "Aqua Jet"    │
   │                         │  submit_action(MOVE,2)   │
   │                         │<─────────────────────────┤
   │                         │                          │
   │                         │ Validate action          │
   │                         │ ✓ Legal                  │
   │                         │                          │
   │                         │ Both ready - execute!    │
   │                         │                          │
   │                         │ engine.execute_turn(     │
   │                         │   action1, action2)      │
   │                         │                          │
   │                         │ Priority resolution:     │
   │                         │ 1. Aqua Jet (priority+1) │
   │                         │ 2. Flamethrower (normal) │
   │                         │                          │
   │                         │ Events emitted:          │
   │                         │ - MOVE_USED (Aqua Jet)   │
   │                         │ - DAMAGE_DEALT (45 HP)   │
   │                         │ - MOVE_USED (Flamethrower)│
   │                         │ - DAMAGE_DEALT (90 HP)   │
   │                         │ - POKEMON_FAINTED        │
   │                         │                          │
   │  receive_turn_events([  │  receive_turn_events([   │
   │    MOVE_USED,           │    MOVE_USED,            │
   │    DAMAGE_DEALT,        │    DAMAGE_DEALT,         │
   │    ...                  │    ...                   │
   │  ])                     │  ])                      │
   │<────────────────────────┼─────────────────────────>│
   │                         │                          │
   │ Animate events          │              Animate     │
   │ - Show Aqua Jet         │              - Show move │
   │ - HP bar animation      │              - HP bar    │
   │ - Show Flamethrower     │              - Faint     │
   │ - Pokemon faints        │                          │
   │                         │                          │
```

---

### 4. Disconnection Handling

```
Player 1                  Server                    Player 2
   │                         │                          │
   │ Battle in progress      │                          │
   │                         │                          │
   │                         │                    X CONNECTION LOST
   │                         │<─────────────────────────┤
   │                         │
   │                         │ peer_disconnected(P2)
   │                         │
   │                         │ Check battle state
   │                         │ - Battle in progress
   │                         │ - Forfeit for P2
   │                         │
   │  battle_ended(          │
   │    winner: P1,          │
   │    reason: "disconnect")│
   │<────────────────────────┤
   │                         │
   │ Show victory screen     │
   │ "Opponent disconnected" │
   │                         │
```

---

## Class Hierarchy

### Server Classes

```
Node (BattleServer - Autoload)
├── Properties
│   ├── active_lobbies: Dictionary<lobby_id, Lobby>
│   ├── peer_to_lobby: Dictionary<peer_id, lobby_id>
│   ├── battle_engines: Dictionary<lobby_id, BattleEngine>
│   └── pending_actions: Dictionary<lobby_id, {player1, player2}>
│
├── Methods
│   ├── setup_network(port: int)
│   ├── create_lobby(peer_id, name, team_data) -> lobby_id
│   ├── join_lobby(peer_id, lobby_id, team_data) -> bool
│   ├── start_battle(lobby_id)
│   ├── validate_action(battle_id, peer_id, action) -> bool
│   └── execute_turn(battle_id)
│
└── RPC Methods (from clients)
    ├── @rpc create_lobby_request(name, team_data)
    ├── @rpc join_lobby_request(lobby_id, team_data)
    └── @rpc submit_action(battle_id, action_data)

RefCounted (LobbyManager)
├── Properties
│   ├── lobbies: Dictionary
│   └── lobby_timeout: float = 300.0
├── Methods
│   ├── create_lobby(player_id, name) -> Lobby
│   ├── cleanup_abandoned_lobbies()
│   └── get_available_lobbies() -> Array

RefCounted (Matchmaker)
├── Properties
│   ├── queue: Array<peer_id>
│   └── queue_times: Dictionary<peer_id, timestamp>
├── Methods
│   ├── join_queue(peer_id, team_data)
│   ├── leave_queue(peer_id)
│   ├── try_match() -> {player1, player2} or null
│   └── get_estimated_wait_time() -> float

RefCounted (SecurityValidator)
├── Methods
│   ├── validate_team(team_data) -> bool
│   ├── validate_action(battle_state, action) -> bool
│   ├── check_rate_limit(peer_id) -> bool
│   └── log_suspicious_activity(peer_id, reason)
```

---

### Client Classes

```
Node (BattleClient - Autoload)
├── Properties
│   ├── is_connected: bool
│   ├── server_ip: String
│   ├── current_lobby_id: int
│   ├── local_player_id: int
│   └── pending_action: BattleAction
│
├── Methods
│   ├── connect_to_server(ip, port) -> bool
│   ├── disconnect_from_server()
│   ├── create_lobby(team_data)
│   ├── join_lobby(lobby_id, team_data)
│   └── submit_player_action(action)
│
└── RPC Methods (from server)
    ├── @rpc lobby_created(lobby_id)
    ├── @rpc lobby_joined(lobby_id)
    ├── @rpc battle_started(battle_id)
    ├── @rpc receive_battle_state(state_data)
    ├── @rpc receive_turn_events(events)
    └── @rpc notify_error(message)
```

---

## Data Structures

### Lobby Structure

```gdscript
class Lobby:
    var id: int                     # Unique lobby ID
    var name: String                # Display name ("Epic Battle")
    var player1_id: int             # ENet peer ID
    var player2_id: int = -1        # -1 if waiting for player
    var player1_team: Array         # [BattlePokemon, ...]
    var player2_team: Array = []    # Empty until player 2 joins
    var ready_states: Dictionary = {
        # peer_id -> bool
        # Used for ready-up system
    }
    var state: LobbyState
    var created_at: float           # Timestamp for cleanup
```

### Battle Action Serialization

```gdscript
# Client sends:
{
    "type": "MOVE",          # or "SWITCH", "FORFEIT"
    "move_index": 0,         # 0-3
    "target_index": 0,       # Always 0 in singles
    "timestamp": 12345.67    # For replay
}

# Server validates and converts to BattleAction object
var action = BattleAction.new(
    ActionType.MOVE,
    move_index,
    target_index,
    -1  # switch_index
)
```

### Battle State Sync

Server sends snapshot after each turn:

```gdscript
{
    "turn": 5,
    "weather": "rain",
    "weather_turns": 3,
    "player1_active": {
        "species": "charizard",
        "level": 100,
        "current_hp": 156,
        "max_hp": 297,
        "status": "none",
        "stat_stages": {"atk": 0, "def": 0, ...}
    },
    "player2_active": {
        "species": "blastoise",
        "level": 100,
        "current_hp": 268,
        "max_hp": 298,
        "status": "burn",
        "stat_stages": {"atk": 0, "def": -1, ...}
    }
}
```

Client uses this to update UI - never calculates on its own.

---

## Security Model

### Validation Pipeline

```
Client Action
     │
     ▼
┌──────────────────────────┐
│  1. Rate Limit Check     │  Max 10 actions/second
│     - Check timestamps   │
│     - Reject if exceeded │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  2. Battle Existence     │  Does battle exist?
│     - Check battle_id    │  Is player in this battle?
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  3. Action Structure     │  Valid JSON structure?
│     - Has required fields│  Correct types?
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  4. Game State Check     │  Is it player's turn?
│     - Is battle active?  │  Waiting for this player?
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  5. Action Legality      │  Move: Valid index? Has PP?
│     - Type-specific      │  Switch: Valid slot? Not fainted?
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  6. Log & Accept         │  All checks passed
│     - Log to server      │  Store for execution
└──────────────────────────┘
```

### Anti-Cheat Measures

1. **Team Validation on Join**
   - Check stat totals match formula
   - Verify moves are in learnset
   - Check ability is legal
   - Validate item exists

2. **Action Validation Every Turn**
   - Move index in range (0-3)
   - Move has PP remaining
   - Switch target not fainted
   - No duplicate actions

3. **Rate Limiting**
   - Max 10 actions/second per peer
   - Prevents spam/DDoS

4. **Server-Side Calculation**
   - Client never calculates damage
   - Client never determines turn order
   - Client only displays server results

5. **Logging**
   - All actions logged
   - Suspicious activity flagged
   - Replay available for review

---

## Network Protocol

### Connection Flow

```
1. Client → Server: TCP Handshake (ENet)
2. Server → Client: Connection Accepted
3. Client → Server: create_lobby_request(team_data)
4. Server validates team_data
5. Server → Client: lobby_created(lobby_id) OR notify_error(message)
```

### RPC Signatures

**Client → Server**:
```gdscript
@rpc("any_peer", "call_remote", "reliable")
func create_lobby_request(lobby_name: String, team_data: Array) -> void

@rpc("any_peer", "call_remote", "reliable")
func join_lobby_request(lobby_id: int, team_data: Array) -> void

@rpc("any_peer", "call_remote", "reliable")
func ready_up(lobby_id: int) -> void

@rpc("any_peer", "call_remote", "reliable")
func submit_action(battle_id: int, action_data: Dictionary) -> void
```

**Server → Client**:
```gdscript
@rpc("authority", "call_remote", "reliable")
func lobby_created(lobby_id: int) -> void

@rpc("authority", "call_remote", "reliable")
func lobby_joined(lobby_id: int) -> void

@rpc("authority", "call_remote", "reliable")
func lobby_updated(lobby_data: Dictionary) -> void

@rpc("authority", "call_remote", "reliable")
func battle_started(battle_id: int) -> void

@rpc("authority", "call_remote", "reliable")
func receive_battle_state(state_data: Dictionary) -> void

@rpc("authority", "call_remote", "reliable")
func receive_turn_events(events: Array) -> void

@rpc("authority", "call_remote", "reliable")
func battle_ended(winner: int, reason: String) -> void

@rpc("authority", "call_remote", "reliable")
func notify_error(message: String) -> void
```

---

## Deployment Architecture

### Development Environment

```
┌────────────────────────────────────────────┐
│         Developer Machine                  │
│                                            │
│  ┌──────────────┐    ┌──────────────┐     │
│  │ Server Build │    │ Client Build │     │
│  │ (localhost:  │    │ (connects to │     │
│  │  8910)       │    │  127.0.0.1)  │     │
│  └──────────────┘    └──────────────┘     │
│                                            │
│  Testing: Same machine, two windows        │
└────────────────────────────────────────────┘
```

### Production Environment

```
┌─────────────────────────────────────────────────────────┐
│                  Cloud Server (VPS/AWS/etc)             │
│                                                         │
│  ┌────────────────────────────────────────────────┐    │
│  │  Dedicated Server Process                      │    │
│  │  - Headless build                              │    │
│  │  - Port 8910 open                              │    │
│  │  - Screen/tmux session                         │    │
│  │  - Auto-restart on crash                       │    │
│  └────────────────────────────────────────────────┘    │
│                        ▲                                │
│                        │                                │
└────────────────────────┼────────────────────────────────┘
                         │
                         │ Internet
                         │
         ┌───────────────┴───────────────┐
         │                               │
    ┌────▼─────┐                   ┌────▼─────┐
    │ Player 1 │                   │ Player 2 │
    │  Client  │                   │  Client  │
    └──────────┘                   └──────────┘
```

---

## Performance Considerations

### Server Capacity Planning

**Per Battle Resource Usage**:
- BattleEngine: ~2 MB RAM
- Lobby data: ~1 MB RAM
- Network buffers: ~0.5 MB
- **Total per battle**: ~3.5 MB

**10 Concurrent Battles**:
- Memory: ~35 MB
- CPU: Low (turn-based, minimal computation)
- Network: ~1 Mbps total (event broadcasts)

**Recommendation**: Start with small VPS ($5-10/month)
- 1 GB RAM supports 100+ battles
- 1 CPU core sufficient for turn-based
- Scale up as player count grows

---

## State Synchronization

### When Server Sends Updates

1. **After Turn Execution**
   - Send `receive_turn_events()` to both players
   - Contains: [MOVE_USED, DAMAGE_DEALT, STATUS_APPLIED, ...]
   - Client animates sequentially

2. **After Pokemon Faint**
   - Send switch request to affected player
   - Other player sees "Waiting for opponent..."

3. **On Battle End**
   - Send `battle_ended()` with winner
   - Both clients show results screen

### Client Display Rules

**Golden Rule**: Client displays only what server sends

**Never Client-Side**:
- Damage calculation
- Turn order determination
- Status effect application
- Weather/terrain effects
- Stat stage changes

**Always Client-Side**:
- UI animations
- Sound effects
- Particle effects
- HP bar smoothing (visual only)

---

## Testing Matrix

| Test Case | Client 1 | Server | Client 2 | Expected Result |
|-----------|----------|--------|----------|-----------------|
| **Normal Battle** | Submit move 0 | Validate both | Submit move 1 | Both receive events, battle continues |
| **Disconnect** | Disconnect | Detect disconnect | In battle | P2 gets victory via forfeit |
| **Invalid Move** | Submit move 99 | Validate | Waiting | Error sent to P1, turn not executed |
| **No PP** | Submit move with 0 PP | Validate | Waiting | Error sent to P1 |
| **Rate Limit** | Send 20 actions | Count actions | Waiting | First 10 pass, rest rejected |
| **Modified Stats** | Send hacked team | Validate team | Waiting | Lobby join rejected |
| **Concurrent Battles** | 10 battles | Track all | 10 battles | All execute independently |

---

## Debugging Tips

### Server Logging

```gdscript
# Add to BattleServer._process()
func _log_server_state() -> void:
    print("=== Server State ===")
    print("Active Lobbies: %d" % active_lobbies.size())
    print("Active Battles: %d" % battle_engines.size())
    print("Connected Peers: %d" % multiplayer.get_peers().size())

    for lobby_id in active_lobbies:
        var lobby = active_lobbies[lobby_id]
        print("  Lobby %d: %s (%s)" % [
            lobby_id,
            lobby.name,
            LobbyState.keys()[lobby.state]
        ])
```

### Client Debug UI

```gdscript
# Add to BattleClient
var debug_label: Label

func _ready():
    debug_label = Label.new()
    add_child(debug_label)

func _process(delta):
    debug_label.text = "Connected: %s\nLatency: %d ms\nLobby: %d" % [
        is_connected,
        get_latency(),
        current_lobby_id
    ]
```

---

## Conclusion

This architecture provides:
- **Security**: Server authority prevents cheating
- **Scalability**: Can handle 10+ concurrent battles
- **Stability**: Graceful error handling and disconnect recovery
- **Maintainability**: Clear separation of concerns
- **Testability**: Unit and integration test friendly

Follow the implementation strategy day-by-day to build this system successfully.

---

*Architecture document created 2025-10-02*
