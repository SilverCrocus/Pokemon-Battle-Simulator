extends Node

## Pokemon Gen 5 (Black/White) Authentic Color Palette
##
## This class provides all colors used in the battle UI to match the Gen 5 aesthetic.
## All colors are based on authentic Gen 5 screenshots and sprite resource analysis.
##
## Usage:
## ```gdscript
## var hp_color = BattleTheme.get_hp_color(0.75)  # Returns green for 75% HP
## var type_color = BattleTheme.get_type_color("fire")  # Returns Fire type color
## ```

# ==================== UI COLORS ====================

## Dark UI background (main battle background)
const BG_DARK = Color(0.094, 0.094, 0.125, 1.0)  # #181820

## Medium panel background
const BG_MEDIUM = Color(0.157, 0.157, 0.188, 1.0)  # #28282F

## Light raised panel
const BG_LIGHT = Color(0.220, 0.220, 0.251, 1.0)  # #383840

# ==================== BORDER COLORS ====================

## Dark borders
const BORDER_DARK = Color(0.063, 0.063, 0.094, 1.0)  # #101018

## Light borders
const BORDER_LIGHT = Color(0.376, 0.376, 0.439, 1.0)  # #606070

# ==================== TEXT COLORS ====================

## Primary text (white)
const TEXT_WHITE = Color(1.0, 1.0, 1.0, 1.0)  # #FFFFFF

## Secondary text (gray)
const TEXT_GRAY = Color(0.753, 0.753, 0.753, 1.0)  # #C0C0C0

## Text on light background (black)
const TEXT_BLACK = Color(0.0, 0.0, 0.0, 1.0)  # #000000

# ==================== HP BAR COLORS ====================

## Healthy HP (>50%)
const HP_GREEN = Color(0.471, 0.784, 0.314, 1.0)  # #78C850

## Warning HP (20-50%)
const HP_YELLOW = Color(0.973, 0.816, 0.188, 1.0)  # #F8D030

## Critical HP (<20%)
const HP_RED = Color(0.941, 0.502, 0.188, 1.0)  # #F08030

## Empty HP background
const HP_BG = Color(0.188, 0.188, 0.188, 1.0)  # #303030

## HP bar border
const HP_BORDER = Color(0.125, 0.125, 0.125, 1.0)  # #202020

# ==================== EXP BAR COLORS ====================

## Experience bar (player only)
const EXP_BLUE = Color(0.345, 0.784, 0.941, 1.0)  # #58C8F0

## Empty EXP background
const EXP_BG = Color(0.188, 0.188, 0.188, 1.0)  # #303030

# ==================== TYPE COLORS (Gen 5 Palette) ====================

## Pokemon type colors for UI display
const TYPE_COLORS = {
	"normal": Color(0.659, 0.659, 0.471, 1.0),      # #A8A878
	"fighting": Color(0.753, 0.188, 0.157, 1.0),    # #C02828
	"flying": Color(0.659, 0.565, 0.957, 1.0),      # #A890F0
	"poison": Color(0.627, 0.251, 0.627, 1.0),      # #A040A0
	"ground": Color(0.878, 0.753, 0.408, 1.0),      # #E0C068
	"rock": Color(0.722, 0.627, 0.220, 1.0),        # #B8A038
	"bug": Color(0.659, 0.722, 0.157, 1.0),         # #A8B820
	"ghost": Color(0.439, 0.345, 0.596, 1.0),       # #705898
	"steel": Color(0.722, 0.722, 0.816, 1.0),       # #B8B8D0
	"fire": Color(0.941, 0.502, 0.188, 1.0),        # #F08030
	"water": Color(0.408, 0.565, 0.941, 1.0),       # #6890F0
	"grass": Color(0.471, 0.784, 0.314, 1.0),       # #78C850
	"electric": Color(0.973, 0.816, 0.188, 1.0),    # #F8D030
	"psychic": Color(0.973, 0.345, 0.502, 1.0),     # #F85888
	"ice": Color(0.596, 0.847, 0.847, 1.0),         # #98D8D8
	"dragon": Color(0.439, 0.220, 0.969, 1.0),      # #7038F8
	"dark": Color(0.439, 0.345, 0.282, 1.0),        # #705848
	"fairy": Color(0.933, 0.659, 0.933, 1.0),       # #EE99EE
	"stellar": Color(0.565, 0.878, 0.878, 1.0)      # #90DFDF
}

# ==================== BUTTON COLORS ====================

## Normal button state
const BTN_NORMAL = Color(0.220, 0.220, 0.251, 1.0)  # #383840

## Hovered button state
const BTN_HOVER = Color(0.282, 0.282, 0.314, 1.0)   # #484850

## Pressed button state
const BTN_PRESSED = Color(0.157, 0.157, 0.188, 1.0) # #28282F

## Disabled button state
const BTN_DISABLED = Color(0.125, 0.125, 0.157, 1.0) # #202028

## Button text (normal)
const BTN_TEXT = Color(1.0, 1.0, 1.0, 1.0)          # #FFFFFF

## Button text (disabled)
const BTN_TEXT_DISABLED = Color(0.502, 0.502, 0.502, 1.0) # #808080

# ==================== STATUS CONDITION COLORS ====================

## Status condition color coding
const STATUS_COLORS = {
	"burn": Color(0.969, 0.384, 0.188, 1.0),        # #F76230 - Orange/red
	"poison": Color(0.627, 0.251, 0.627, 1.0),      # #A040A0 - Purple
	"badly_poison": Color(0.502, 0.157, 0.502, 1.0), # #802880 - Dark purple
	"paralysis": Color(0.973, 0.816, 0.188, 1.0),   # #F8D030 - Yellow
	"sleep": Color(0.565, 0.565, 0.627, 1.0),       # #9090A0 - Gray
	"freeze": Color(0.596, 0.847, 0.847, 1.0)       # #98D8D8 - Cyan
}

# ==================== HELPER METHODS ====================

## Get color for a Pokemon type
##
## @param type_name: Type name (e.g., "fire", "water", "electric")
## @return: Color for the specified type, or white if type not found
static func get_type_color(type_name: String) -> Color:
	return TYPE_COLORS.get(type_name.to_lower(), TEXT_WHITE)


## Get color for a status condition
##
## @param status: Status condition name (e.g., "burn", "poison", "paralysis")
## @return: Color for the specified status, or white if status not found
static func get_status_color(status: String) -> Color:
	return STATUS_COLORS.get(status.to_lower(), TEXT_WHITE)


## Get HP bar color based on HP percentage
##
## @param hp_percentage: HP as a percentage (0.0 to 1.0)
## @return: Green (>50%), Yellow (20-50%), or Red (<20%)
static func get_hp_color(hp_percentage: float) -> Color:
	if hp_percentage >= 0.5:
		return HP_GREEN
	elif hp_percentage >= 0.2:
		return HP_YELLOW
	else:
		return HP_RED


## Get color for type effectiveness display
##
## @param multiplier: Type effectiveness multiplier (0.0, 0.25, 0.5, 1.0, 2.0, 4.0)
## @return: Green (super effective), Red (not very effective), Gray (no effect), White (normal)
static func get_effectiveness_color(multiplier: float) -> Color:
	if multiplier >= 2.0:
		return Color(0.396, 0.875, 0.271, 1.0)  # Green - Super effective
	elif multiplier <= 0.5 and multiplier > 0.0:
		return Color(0.969, 0.180, 0.180, 1.0)  # Red - Not very effective
	elif multiplier == 0.0:
		return Color(0.502, 0.502, 0.502, 1.0)  # Gray - No effect
	else:
		return TEXT_WHITE  # Normal effectiveness


## Get text for type effectiveness
##
## @param multiplier: Type effectiveness multiplier
## @return: Human-readable text (e.g., "Super effective!", "Not very effective...")
static func get_effectiveness_text(multiplier: float) -> String:
	if multiplier >= 4.0:
		return "It's super effective!" # 4x
	elif multiplier >= 2.0:
		return "It's super effective!" # 2x
	elif multiplier == 0.5:
		return "It's not very effective..." # 0.5x
	elif multiplier <= 0.25:
		return "It's not very effective..." # 0.25x
	elif multiplier == 0.0:
		return "It doesn't affect the Pokemon..."
	else:
		return ""  # Normal effectiveness (1.0x) - no text
