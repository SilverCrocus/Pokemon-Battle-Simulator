class_name TerrainEffect
extends MoveEffect

## Terrain setting effect
##
## Sets battlefield terrain for 5 turns (or 8 with Terrain Extender).
##
## Terrain Types:
##   - electric: Boosts Electric moves, prevents sleep (grounded Pokemon)
##   - grassy: Boosts Grass moves, heals grounded Pokemon each turn
##   - misty: Boosts Fairy moves, halves Dragon damage (grounded Pokemon)
##   - psychic: Boosts Psychic moves, prevents priority moves (grounded Pokemon)
##
## Examples:
##   - Electric Terrain: Sets electric terrain
##   - Grassy Terrain: Sets grassy terrain
##   - Misty Terrain: Sets misty terrain
##   - Psychic Terrain: Sets psychic terrain

var terrain_type: String = ""  # "electric", "grassy", "misty", "psychic"
var duration: int = 5  # Default 5 turns


func _init(terrain: String, turns: int = 5) -> void:
	super._init("Set %s Terrain" % terrain.capitalize(), 100, false)
	terrain_type = terrain
	duration = turns


func execute(context: Dictionary) -> Dictionary:
	"""
	Set battlefield terrain.

	Args:
		context: Must contain:
			- state: BattleState

	Returns:
		success: true if terrain was set
		message: Terrain description
		data: terrain type and duration
	"""
	var state = context["state"]  # BattleState

	# Set terrain in battle state
	state.terrain = terrain_type
	state.terrain_turns_remaining = duration

	# Get terrain description
	var message = _get_terrain_message(terrain_type)

	return {
		"success": true,
		"message": message,
		"data": {"terrain": terrain_type, "duration": duration}
	}


func _get_terrain_message(terrain: String) -> String:
	"""Get the appropriate terrain message."""
	match terrain:
		"electric":
			return "An electric current ran across the battlefield!"
		"grassy":
			return "Grass grew to cover the battlefield!"
		"misty":
			return "Mist swirled around the battlefield!"
		"psychic":
			return "The battlefield got weird!"
		_:
			return "The terrain changed!"
