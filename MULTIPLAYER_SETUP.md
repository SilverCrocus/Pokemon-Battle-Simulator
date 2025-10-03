# Multiplayer Setup Guide

## Quick Start - Playing With a Friend

### Prerequisites
1. Both players must have a saved team (create one in Team Builder first)
2. One person needs to host the server
3. Both players need the game installed

---

## Option 1: Localhost Testing (Same Computer)

Perfect for testing or playing against yourself.

### Steps:
1. **Start Server** (Terminal/Command Prompt):
   ```bash
   cd godot_project
   godot --headless --path . --feature dedicated_server
   ```
   - Server starts on port 7777
   - Leave this terminal running

2. **Start Client 1** (new terminal):
   ```bash
   godot --path .
   ```
   - Main Menu → Multiplayer
   - Click "Connect to Localhost" or enter `127.0.0.1` and port `7777`
   - Click "Create Lobby" (optional: enter lobby name)
   - Share the lobby code with Player 2

3. **Start Client 2** (new terminal):
   ```bash
   godot --path .
   ```
   - Main Menu → Multiplayer
   - Connect to `127.0.0.1:7777`
   - Enter lobby code → Click "Join by Code"

4. **Both Players**: Click "Ready" button
5. **Battle starts automatically!**

---

## Option 2: LAN/Local Network (Same WiFi)

Perfect for playing with a friend in the same house.

### Server Host Steps:
1. **Find your local IP**:
   - Windows: `ipconfig` (look for IPv4 Address, e.g., `192.168.1.100`)
   - Mac/Linux: `ifconfig` or `ip addr` (look for inet address)

2. **Start server**:
   ```bash
   cd godot_project
   godot --headless --path . --feature dedicated_server
   ```

3. **Share your IP** with your friend (e.g., `192.168.1.100`)

### Client Steps:
1. Launch game
2. Main Menu → Multiplayer
3. Enter host's IP (e.g., `192.168.1.100`) and port `7777`
4. Click Connect
5. Join lobby or create one
6. Click Ready when both players are in

---

## Option 3: Internet Play (Remote Friend)

Requires port forwarding on the host's router.

### Server Host Steps:
1. **Port Forward** on your router:
   - Forward port `7777` (TCP/UDP) to your computer's local IP
   - Google "[your router model] port forwarding guide"

2. **Find your public IP**:
   - Visit https://whatismyipaddress.com/
   - Note the IP address (e.g., `203.0.113.45`)

3. **Start server**:
   ```bash
   cd godot_project
   godot --headless --path . --feature dedicated_server
   ```

4. **Share your public IP** with your friend

### Client Steps:
1. Launch game
2. Main Menu → Multiplayer
3. Enter host's **public IP** and port `7777`
4. Connect and join lobby

---

## Troubleshooting

### "Connection failed. Check server is running."
- **Cause**: Server not started or wrong IP/port
- **Fix**:
  - Verify server is running (you should see console output)
  - Check IP address is correct
  - For localhost: use `127.0.0.1`
  - For LAN: use host's local IP (192.168.x.x)
  - For internet: use host's public IP

### "No team found - please create a team first"
- **Cause**: No team saved in Team Builder
- **Fix**:
  - Go to Main Menu → Team Builder
  - Create a team with 1-6 Pokemon
  - Click "Save Team"
  - Return to Multiplayer

### Firewall Blocking Connection
- **Windows**: Allow Godot through Windows Firewall
- **Mac**: System Preferences → Security & Privacy → Firewall → Allow Godot
- **Port**: Make sure port 7777 is not blocked

### Connection Works But Can't Join Lobby
- **Cause**: Team validation failed
- **Fix**:
  - Check your team has valid Pokemon, moves, EVs, IVs
  - EVs total ≤ 510, each stat ≤ 252
  - IVs each stat 0-31
  - All Pokemon/moves exist in game data

---

## Technical Details

### Server Architecture
- **Type**: Dedicated server (server-authoritative)
- **Port**: 7777 (default)
- **Protocol**: ENet (built into Godot)
- **Max Lobbies**: 100
- **Players per Lobby**: 2

### Battle Synchronization
- Server runs all battle logic
- Clients receive state updates
- Deterministic RNG with shared seed
- All actions validated server-side

### Security
- Team validation prevents illegal teams
- Action validation prevents cheating
- Server authority prevents client manipulation
- Packet validation with timestamps

---

## Server Commands

### Start Server (Headless)
```bash
godot --headless --path . --feature dedicated_server
```

### Start Server (With Display, for debugging)
```bash
godot --path . --feature dedicated_server
```

### Custom Port (Advanced)
```bash
# Not currently supported - defaults to 7777
# Future update will add --port argument
```

---

## Network Requirements

### Ports
- **7777** (TCP/UDP) - Game server

### Bandwidth
- **Minimal** - Turn-based game uses very little data
- ~1-5 KB per turn
- Suitable for any broadband connection

### Latency
- Turn-based gameplay is tolerant of latency
- Up to 200ms is comfortable
- Higher latency just adds slight delay between turns

---

## Known Limitations (MVP)

1. **No Matchmaking**: Must manually share lobby codes
2. **No Reconnection**: Disconnect = lobby abandoned
3. **No LAN Discovery**: Must manually enter IP
4. **No Recent Servers**: IP must be entered each time
5. **No Spectator Mode**: Only 2 players per lobby

These features are planned for future updates!

---

## Advanced: Running Dedicated Server on Cloud

For always-online server hosting:

### DigitalOcean/AWS/etc:
1. Create Linux VPS
2. Install Godot Server:
   ```bash
   wget https://downloads.tuxfamily.org/godotengine/4.5/Godot_v4.5-stable_linux.x86_64.zip
   unzip Godot_v4.5-stable_linux.x86_64.zip
   ```
3. Upload game files
4. Run server:
   ```bash
   ./Godot_v4.5-stable_linux.x86_64 --headless --path godot_project --feature dedicated_server
   ```
5. Open port 7777 in firewall
6. Share server IP with friends

---

## Quick Reference

| Action | Command/Steps |
|--------|---------------|
| Start Server | `godot --headless --path . --feature dedicated_server` |
| Connect Localhost | IP: `127.0.0.1`, Port: `7777` |
| Connect LAN | IP: Host's local IP (192.168.x.x) |
| Connect Internet | IP: Host's public IP |
| Create Lobby | Click "Create Lobby" button |
| Join Lobby | Enter lobby code → "Join by Code" |
| Start Battle | Both players click "Ready" |

---

**Need Help?** Check the logs at:
- Mac: `~/Library/Application Support/Godot/app_userdata/Pokemon Battle Simulator/logs/godot.log`
- Windows: `%APPDATA%\Godot\app_userdata\Pokemon Battle Simulator\logs\godot.log`
- Linux: `~/.local/share/godot/app_userdata/Pokemon Battle Simulator/logs/godot.log`

**Version:** 0.2.0 - Multiplayer MVP
**Last Updated:** 2025-10-03
