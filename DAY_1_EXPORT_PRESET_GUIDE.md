# Day 1: Export Preset Configuration Guide

## ✅ Completed So Far

- [x] Created `Main.gd` entry point with server/client feature detection
- [x] Created `Main.tscn` scene
- [x] Tested Main scene loads correctly in client mode (launches main menu)
- [x] Fixed scene tree error with `call_deferred()`

## 🎯 Next Steps: Configure Export Presets

Export presets are configured through the Godot Editor UI. Follow these steps:

### Step 1: Open Godot Editor

```bash
cd /Users/diyagamah/Documents/Pokemon-Battle-Simulator/godot_project
godot --editor .
```

Or use Godot MCP:
```
mcp__godot__launch_editor(projectPath: "/Users/diyagamah/Documents/Pokemon-Battle-Simulator/godot_project")
```

---

### Step 2: Create Server Export Preset (Headless)

1. In Godot Editor, go to **Project → Export...**
2. Click **Add...** → Select your platform (macOS, Linux, or Windows)
3. Configure the preset:

**Preset Name**: `Server (Headless)`

**Settings to Configure**:
- **Runnable**: ✓ Checked
- **Export Path**: `builds/server/pokemon_server` (or `.exe` for Windows)

**Features Tab**:
- Click **Custom** button
- **Add Feature**: `dedicated_server`
- **Remove Features**: Remove `client` if present

**Resources Tab**:
- **Export Mode**: `Export all resources in the project`
- **Filters to export non-resource files**: Leave default

**Dedicated Server Tab** (important!):
- **Dedicated Server**: ✓ Checked (this strips graphics/audio)

**Application Settings**:
- **Run Dedicated Server**: ✓ Checked

---

### Step 3: Create Client Export Preset (Full Features)

1. Still in **Project → Export...**
2. Click **Add...** → Select your platform again
3. Configure the preset:

**Preset Name**: `Client (Full)`

**Settings**:
- **Runnable**: ✓ Checked
- **Export Path**: `builds/client/pokemon_client` (or `.exe` for Windows)

**Features Tab**:
- Click **Custom** button
- **Add Feature**: `client`
- **Do NOT add**: `dedicated_server`

**Resources Tab**:
- **Export Mode**: `Export all resources in the project`

**Application Settings**:
- **Dedicated Server**: ✗ Unchecked (keep graphics/audio)

---

### Step 4: Export Both Builds

1. Select **Server (Headless)** preset
2. Click **Export Project**
3. Save to `builds/server/pokemon_server`

4. Select **Client (Full)** preset
5. Click **Export Project**
6. Save to `builds/client/pokemon_client`

---

### Step 5: Test Exports

#### Test Server Build (Headless):
```bash
cd /Users/diyagamah/Documents/Pokemon-Battle-Simulator/godot_project/builds/server
./pokemon_server
```

**Expected Output**:
```
=== POKEMON BATTLE SIMULATOR SERVER ===
Server mode detected - launching headless server...
Godot version: 4.5.stable
Server starting on port 9999...
Server ready - waiting for client connections...
```

**Should NOT show**: Any graphics window

---

#### Test Client Build (Full UI):
```bash
cd /Users/diyagamah/Documents/Pokemon-Battle-Simulator/godot_project/builds/client
./pokemon_client
```

**Expected Output**:
- Graphics window opens
- Displays: `=== POKEMON BATTLE SIMULATOR CLIENT ===`
- Main menu loads normally

---

## 📝 Alternative: Manual Export Preset Configuration

If you prefer to edit the export preset file directly:

### File Location
`/Users/diyagamah/Documents/Pokemon-Battle-Simulator/godot_project/export_presets.cfg`

### Server Preset (example for macOS):
```ini
[preset.0]
name="Server (Headless)"
platform="macOS"
runnable=true
advanced_options=false
custom_features="dedicated_server"
export_filter="all_resources"
export_path="builds/server/pokemon_server.app"
dedicated_server/dedicated_server=true
```

### Client Preset (example for macOS):
```ini
[preset.1]
name="Client (Full)"
platform="macOS"
runnable=true
advanced_options=false
custom_features="client"
export_filter="all_resources"
export_path="builds/client/pokemon_client.app"
dedicated_server/dedicated_server=false
```

**Note**: Platform-specific settings will vary. Use the Godot Editor method for best results.

---

## ✅ Day 1 Completion Checklist

- [x] Main.gd created with feature detection
- [x] Main.tscn scene created
- [x] Tested Main scene in editor (client mode works)
- [ ] Server export preset configured
- [ ] Client export preset configured
- [ ] Server build exported
- [ ] Client build exported
- [ ] Server build tested (runs headless)
- [ ] Client build tested (shows UI)

---

## 🚀 When Complete

Once all checklist items are done:

1. Update `project.godot` to use Main.tscn as entry point:
   ```ini
   [application]
   run/main_scene="res://Main.tscn"
   ```

2. Commit your changes:
   ```bash
   git add .
   git commit -m "Phase 3 Day 1: Export presets and feature detection"
   git push
   ```

3. Move to **Day 2**: BattleState serialization enhancement

---

## ❓ Troubleshooting

### Server build shows graphics window
- Check **Dedicated Server** is enabled in export preset
- Verify `dedicated_server` feature tag is present
- Make sure `OS.has_feature("dedicated_server")` check is working

### Client build doesn't load main menu
- Check Main.gd `_launch_client()` scene path is correct
- Verify `scenes/menu/MainMenuScene.tscn` exists
- Check debug output for errors

### Export fails
- Make sure export templates are installed: **Editor → Manage Export Templates**
- Check file permissions on export path
- Try exporting to a different location

### Feature detection not working
- Print `OS.get_cmdline_args()` to see active features
- Use `print(OS.has_feature("dedicated_server"))` for debugging
- Check export preset has correct custom features set

---

**Next Document**: See `PHASE_3_IMPLEMENTATION_STRATEGY.md` for Day 2 tasks.
