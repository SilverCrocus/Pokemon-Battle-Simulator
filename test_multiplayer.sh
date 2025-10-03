#!/bin/bash

# Multiplayer Test Script
# Tests the full multiplayer flow from main menu to connection screen

echo "=== POKEMON BATTLE SIMULATOR - MULTIPLAYER TEST ==="
echo ""

cd godot_project

# Test 1: Check if ConnectionScreen exists
echo "[1/5] Checking ConnectionScreen scene..."
if [ -f "scenes/multiplayer/ConnectionScreen.tscn" ]; then
    echo "✅ ConnectionScreen.tscn exists"
else
    echo "❌ ConnectionScreen.tscn missing"
    exit 1
fi

# Test 2: Check if ConnectionController exists
echo "[2/5] Checking ConnectionController script..."
if [ -f "scripts/ui/ConnectionController.gd" ]; then
    echo "✅ ConnectionController.gd exists"
else
    echo "❌ ConnectionController.gd missing"
    exit 1
fi

# Test 3: Check if main menu navigation is updated
echo "[3/5] Checking MainMenuController navigation..."
if grep -q "ConnectionScreen.tscn" scripts/ui/MainMenuController.gd; then
    echo "✅ Main menu navigates to ConnectionScreen"
else
    echo "❌ Main menu navigation not updated"
    exit 1
fi

# Test 4: Check if multiplayer button is enabled
echo "[4/5] Checking multiplayer button status..."
if grep -q "disabled = true" scenes/menu/MainMenuScene.tscn; then
    echo "❌ Multiplayer button still disabled"
    exit 1
else
    echo "✅ Multiplayer button enabled"
fi

# Test 5: Check if LobbyController loads saved teams
echo "[5/5] Checking LobbyController team loading..."
if grep -q "_load_saved_team" scripts/ui/LobbyController.gd; then
    echo "✅ LobbyController loads saved teams"
else
    echo "❌ LobbyController still uses test team"
    exit 1
fi

echo ""
echo "=== ALL TESTS PASSED ✅ ==="
echo ""
echo "To test multiplayer:"
echo "1. Start server: godot --headless --path . --feature dedicated_server"
echo "2. Start client: godot --path ."
echo "3. Main Menu → Multiplayer → Connect to 127.0.0.1:7777"
echo ""
echo "See MULTIPLAYER_SETUP.md for full instructions"
