extends "res://scripts/core/MoveEffect.gd"

## Weather setting effect
##
## Sets battlefield weather for 5 turns (or 8 with appropriate held items).
##
## Weather Types:
##   - sun: Boosts Fire moves, weakens Water moves
##   - rain: Boosts Water moves, weakens Fire moves
##   - sandstorm: Damages non-Rock/Ground/Steel Pokemon each turn
##   - hail: Damages non-Ice Pokemon each turn (renamed to snow in Gen 9)
##   - snow: Boosts Ice defense (Gen 9)
##
## Examples:
##   - Sunny Day: Sets sun
##   - Rain Dance: Sets rain
##   - Sandstorm: Sets sandstorm
##   - Hail/Snowscape: Sets hail/snow

var weather_type: String = ""  # "sun", "rain", "sandstorm", "hail", "snow"
var duration: int = 5  # Default 5 turns


func _init(weather: String, turns: int = 5) -> void:
	super._init("Set %s" % weather.capitalize(), 100, false)
	weather_type = weather
	duration = turns


func execute(context: Dictionary) -> Dictionary:
	"""
	Set battlefield weather.

	Args:
		context: Must contain:
			- state: BattleState

	Returns:
		success: true if weather was set
		message: Weather description
		data: weather type and duration
	"""
	var state = context["state"]  # BattleState

	# Set weather in battle state
	state.weather = weather_type
	state.weather_turns_remaining = duration

	# Get weather description
	var message = _get_weather_message(weather_type)

	return {
		"success": true,
		"message": message,
		"data": {"weather": weather_type, "duration": duration}
	}


func _get_weather_message(weather: String) -> String:
	"""Get the appropriate weather message."""
	match weather:
		"sun":
			return "The sunlight turned harsh!"
		"rain":
			return "It started to rain!"
		"sandstorm":
			return "A sandstorm kicked up!"
		"hail":
			return "It started to hail!"
		"snow":
			return "It started to snow!"
		_:
			return "The weather changed!"
