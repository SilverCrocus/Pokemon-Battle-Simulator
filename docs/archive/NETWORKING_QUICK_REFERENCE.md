# Godot 4 Networking Quick Reference
**For Pokemon Battle Simulator Phase 3**

## Essential Code Snippets

### Server Setup
```gdscript
# main.gd
extends Node

func _ready():
    if OS.has_feature("dedicated_server"):
        _start_server()
    else:
        _show_main_menu()

func _start_server():
    var peer = ENetMultiplayerPeer.new()
    peer.create_server(7777, 32)  # Port 7777, max 32 players
    multiplayer.multiplayer_peer = peer

    multiplayer.peer_connected.connect(_on_player_connected)
    multiplayer.peer_disconnected.connect(_on_player_disconnected)

    print("Server started on port 7777")
```

### Client Connection
```gdscript
func _connect_to_server(ip: String, port: int):
    var peer = ENetMultiplayerPeer.new()
    peer.create_client(ip, port)
    multiplayer.multiplayer_peer = peer

    multiplayer.connected_to_server.connect(_on_connected)
    multiplayer.connection_failed.connect(_on_connection_failed)
```

### RPC Patterns

#### Client Request → Server Validates
```gdscript
# Client calls this
func select_move(move_index: int):
    request_move.rpc_id(1, move_index)  # Send to server (ID 1)

# Server receives and validates
@rpc("any_peer", "reliable")
func request_move(move_index: int):
    if not multiplayer.is_server():
        return

    var player_id = multiplayer.get_remote_sender_id()

    # VALIDATE EVERYTHING
    if not _is_valid_move(player_id, move_index):
        send_error.rpc_id(player_id, "Invalid move")
        return

    # Execute server-side
    var result = _execute_move(player_id, move_index)

    # Broadcast to all clients
    broadcast_result.rpc(result)
```

#### Server Broadcast → All Clients
```gdscript
@rpc("authority", "reliable")
func broadcast_result(result: Dictionary):
    # Clients apply result
    _update_battle_state(result)
```

### Server-Side Validation Template
```gdscript
@rpc("any_peer", "reliable")
func request_action(action_data: Dictionary):
    if not multiplayer.is_server():
        return

    var sender_id = multiplayer.get_remote_sender_id()

    # 1. Check authentication
    if not authenticated_players.has(sender_id):
        multiplayer.disconnect_peer(sender_id)
        return

    # 2. Check rate limit
    if not _check_rate_limit(sender_id):
        return

    # 3. Validate action
    if not _is_valid_action(sender_id, action_data):
        send_error.rpc_id(sender_id, "Invalid action")
        return

    # 4. Execute server-side (NEVER trust client data)
    var result = _execute_action_server_side(sender_id, action_data)

    # 5. Broadcast result
    update_state.rpc(result)
```

### Rate Limiting
```gdscript
var rpc_timestamps = {}
const MAX_CALLS_PER_SECOND = 5

func _check_rate_limit(peer_id: int) -> bool:
    var now = Time.get_ticks_msec()

    if not rpc_timestamps.has(peer_id):
        rpc_timestamps[peer_id] = []

    # Remove timestamps older than 1 second
    rpc_timestamps[peer_id] = rpc_timestamps[peer_id].filter(
        func(t): return now - t < 1000
    )

    if rpc_timestamps[peer_id].size() >= MAX_CALLS_PER_SECOND:
        _kick_player(peer_id, "Rate limit")
        return false

    rpc_timestamps[peer_id].append(now)
    return true
```

### Battle Instance Management
```gdscript
# lobby_manager.gd
class_name LobbyManager extends Node

var active_battles = {}  # battle_id -> BattleInstance
var player_to_battle = {}  # player_id -> battle_id

func create_battle(p1_id: int, p2_id: int, p1_team: Array, p2_team: Array):
    var battle_id = _generate_id()

    var battle = preload("res://battles/battle_instance.tscn").instantiate()
    battle.battle_id = battle_id
    battle.initialize(p1_id, p2_id, p1_team, p2_team)

    active_battles[battle_id] = battle
    player_to_battle[p1_id] = battle_id
    player_to_battle[p2_id] = battle_id

    add_child(battle)

    # Notify players
    battle_started.rpc_id(p1_id, battle_id)
    battle_started.rpc_id(p2_id, battle_id)

func remove_battle(battle_id: String):
    var battle = active_battles.get(battle_id)
    if battle:
        player_to_battle.erase(battle.player1_id)
        player_to_battle.erase(battle.player2_id)
        active_battles.erase(battle_id)
        battle.queue_free()
```

### Battle Instance
```gdscript
# battle_instance.gd
class_name BattleInstance extends Node

var battle_id: String
var player1_id: int
var player2_id: int
var battle_state = {}

func initialize(p1_id: int, p2_id: int, p1_team: Array, p2_team: Array):
    player1_id = p1_id
    player2_id = p2_id
    battle_state = _create_state(p1_team, p2_team)

@rpc("any_peer", "reliable")
func submit_move(move_index: int):
    if not multiplayer.is_server():
        return

    var sender = multiplayer.get_remote_sender_id()

    # Verify sender is in THIS battle
    if sender != player1_id and sender != player2_id:
        return

    # Process move
    _process_turn(sender, move_index)

func _process_turn(player_id: int, move_index: int):
    # Server-side battle logic
    var result = BattleEngine.execute_move(battle_state, player_id, move_index)

    # Update state
    battle_state = result.new_state

    # Send to both players
    turn_result.rpc_id(player1_id, result)
    turn_result.rpc_id(player2_id, result)

    # Check if battle ended
    if result.battle_ended:
        end_battle(result.winner)

func end_battle(winner_id: int):
    battle_ended.rpc_id(player1_id, winner_id)
    battle_ended.rpc_id(player2_id, winner_id)

    LobbyManager.remove_battle(battle_id)
```

### Matchmaking Queue
```gdscript
var waiting_players = []

@rpc("any_peer", "reliable")
func join_queue(team_data: Array):
    if not multiplayer.is_server():
        return

    var player_id = multiplayer.get_remote_sender_id()

    # Validate team
    if not _validate_team(team_data):
        queue_error.rpc_id(player_id, "Invalid team")
        return

    waiting_players.append({
        "id": player_id,
        "team": team_data
    })

    queue_joined.rpc_id(player_id)

    # Try to match
    if waiting_players.size() >= 2:
        var p1 = waiting_players.pop_front()
        var p2 = waiting_players.pop_front()
        create_battle(p1.id, p2.id, p1.team, p2.team)
```

### State Synchronization
```gdscript
# Send complete state
@rpc("authority", "reliable")
func sync_battle_state(state: Dictionary):
    battle_state = state
    _update_ui()

# Or delta compression for optimization
var last_state = {}

func broadcast_state_delta():
    var delta = {}
    for key in current_state:
        if current_state[key] != last_state.get(key):
            delta[key] = current_state[key]

    if not delta.is_empty():
        apply_delta.rpc(delta)
        last_state = current_state.duplicate(true)
```

### Timeout Handling
```gdscript
var turn_timers = {}
const TURN_TIMEOUT = 60.0

func _process(delta):
    if not multiplayer.is_server():
        return

    for player_id in turn_timers:
        turn_timers[player_id] -= delta

        if turn_timers[player_id] <= 0:
            _handle_timeout(player_id)
            turn_timers.erase(player_id)
```

### Disconnection Handling
```gdscript
func _on_player_disconnected(id: int):
    if not multiplayer.is_server():
        return

    # Find player's battle
    if player_to_battle.has(id):
        var battle_id = player_to_battle[id]
        var battle = active_battles[battle_id]

        # Award victory to opponent
        var opponent_id = battle.player1_id if id == battle.player2_id else battle.player2_id
        battle.end_battle(opponent_id)

    # Clean up
    authenticated_players.erase(id)
    rpc_timestamps.erase(id)
```

## Key Principles

1. **Never Trust Clients**
   - All validation on server
   - Server calculates damage/effects
   - Clients only display results

2. **Server is Source of Truth**
   - All game state stored server-side
   - Clients request actions
   - Server broadcasts results

3. **Validate Everything**
   - Move legality
   - Team composition
   - Stat values
   - Turn order

4. **Rate Limit RPCs**
   - Prevent flooding
   - Track timestamps
   - Auto-kick abusers

5. **Isolate Battles**
   - Separate instances
   - Independent state
   - Verify sender in battle

## Export Settings

### Server Export Preset
1. Project → Export
2. Add Linux/X11 preset
3. Resources tab → "Export as dedicated server"
4. Features tab → Verify "dedicated_server" tag added

### Runtime Detection
```gdscript
if OS.has_feature("dedicated_server"):
    # Server code
else:
    # Client code
```

## Testing Checklist

- [ ] Server starts and accepts connections
- [ ] Client can connect and authenticate
- [ ] Invalid moves are rejected
- [ ] Modified stats are detected
- [ ] Rate limiting works
- [ ] Timeouts trigger correctly
- [ ] Disconnections handled gracefully
- [ ] Multiple battles run concurrently
- [ ] No memory leaks after battles end
- [ ] Bandwidth usage is acceptable

## Common Issues

### RPC Not Working
- Check authority is set correctly
- Verify node is in scene tree
- Ensure multiplayer peer is connected
- Check RPC mode allows caller

### State Desync
- Use server-authoritative pattern
- Send complete state periodically
- Don't rely on client-side prediction for critical state

### Memory Leaks
- Call `queue_free()` on battle instances
- Disconnect signals before freeing
- Clear dictionary references

### Performance Issues
- Limit RPC calls per frame
- Use delta compression
- Profile with --profile flag

## Performance Targets

- 10+ concurrent battles: < 50% CPU
- < 10 MB RAM per battle
- < 200ms turn latency
- < 10 KB/s bandwidth per battle

## Security Checklist

- [ ] All RPCs use "any_peer" are validated
- [ ] Stats loaded from server database, not client
- [ ] Damage calculated server-side
- [ ] Rate limiting implemented
- [ ] Authentication required
- [ ] Invalid data kicks player
- [ ] No client data trusted

## File Structure

```
res://networking/
├── server/
│   ├── server_main.gd
│   ├── lobby_manager.gd
│   ├── battle_instance.gd
│   └── validation.gd
├── client/
│   ├── network_client.gd
│   └── ui/
│       ├── matchmaking_ui.gd
│       └── battle_ui_network.gd
└── shared/
    ├── network_protocol.gd
    └── pokemon_data.gd
```

---

**Quick Start:** See full `NETWORKING_RESEARCH.md` for detailed explanations and architecture.
