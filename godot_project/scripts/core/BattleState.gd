class_name BattleState
extends RefCounted

## Preload dependencies
const BattlePokemonScript = preload("res://scripts/core/BattlePokemon.gd")

## Complete battle state
##
## Represents the entire state of a Pokemon battle including both teams, active Pokemon,
## weather, terrain, turn count, and RNG seed for deterministic replay. This class is the
## single source of truth for all battle information.
##
## Example usage:
## [codeblock]
## var state = BattleState.new()
## state.set_team1([pikachu, charizard, blastoise])
## state.set_team2([mewtwo, dragonite, alakazam])
## state.begin_battle()
##
## # Access active Pokemon
## var player1_active = state.get_active_pokemon(1)
## var player2_active = state.get_active_pokemon(2)
##
## # Switch Pokemon
## state.switch_pokemon(1, 2)  # Player 1 switches to their third Pokemon
## [/codeblock]

## Current turn number (starts at 1)
var turn_number: int = 0

## Current weather condition
var weather: String = "none"

## Turns remaining for current weather (-1 for infinite)
var weather_turns_remaining: int = 0

## Current terrain
var terrain: String = "none"

## Turns remaining for current terrain (-1 for infinite)
var terrain_turns_remaining: int = 0

## Player 1's team (up to 6 Pokemon)
var team1 = []  # Array of BattlePokemon

## Player 2's team (up to 6 Pokemon)
var team2 = []  # Array of BattlePokemon

## Index of Player 1's active Pokemon (0-5)
var active1_index: int = 0

## Index of Player 2's active Pokemon (0-5)
var active2_index: int = 0

## RNG seed for deterministic battle replay
var rng_seed: int = 0

## Internal RNG state
var _rng: RandomNumberGenerator

## Valid weather conditions
const VALID_WEATHER: Array[String] = [
	"none",
	"sun",
	"rain",
	"sandstorm",
	"hail",
	"snow"
]

## Valid terrain types
const VALID_TERRAIN: Array[String] = [
	"none",
	"electric",
	"grassy",
	"misty",
	"psychic"
]

## Battle status
enum BattleStatus {
	NOT_STARTED,   ## Battle hasn't begun yet
	IN_PROGRESS,   ## Battle is ongoing
	PLAYER1_WIN,   ## Player 1 won
	PLAYER2_WIN,   ## Player 2 won
	DRAW           ## Both players forfeited or other draw condition
}

## Current battle status
var battle_status: BattleStatus = BattleStatus.NOT_STARTED


func _init(p_rng_seed: int = 0) -> void:
	"""
	Initialize a new battle state.

	Args:
		p_rng_seed: Random seed for deterministic battles (0 for random seed)
	"""
	if p_rng_seed == 0:
		rng_seed = randi()
	else:
		rng_seed = p_rng_seed

	_rng = RandomNumberGenerator.new()
	_rng.seed = rng_seed


func set_team1(pokemon_team: Array) -> void:
	"""
	Set Player 1's team.

	Args:
		pokemon_team: Array of BattlePokemon (1-6 Pokemon)
	"""
	_validate_team(pokemon_team)
	team1.clear()
	for pokemon in pokemon_team:
		team1.append(pokemon)


func set_team2(pokemon_team: Array) -> void:
	"""
	Set Player 2's team.

	Args:
		pokemon_team: Array of BattlePokemon (1-6 Pokemon)
	"""
	_validate_team(pokemon_team)
	team2.clear()
	for pokemon in pokemon_team:
		team2.append(pokemon)


func _validate_team(pokemon_team: Array) -> void:
	"""Validate that a team meets requirements."""
	assert(pokemon_team.size() >= 1 and pokemon_team.size() <= 6,
		"BattleState: team must have 1-6 Pokemon, got %d" % pokemon_team.size())

	for pokemon in pokemon_team:
		assert(pokemon.get_script() == BattlePokemonScript,
			"BattleState: all team members must be BattlePokemon instances")
		assert(not pokemon.is_fainted(),
			"BattleState: team cannot contain fainted Pokemon (%s)" % pokemon.get_display_name())


func begin_battle() -> void:
	"""
	Start the battle. Must be called after both teams are set.
	"""
	assert(team1.size() > 0, "BattleState: team1 not set")
	assert(team2.size() > 0, "BattleState: team2 not set")
	assert(battle_status == BattleStatus.NOT_STARTED, "BattleState: battle already started")

	turn_number = 1
	active1_index = 0
	active2_index = 0
	battle_status = BattleStatus.IN_PROGRESS


func get_active_pokemon(player: int):  # Returns BattlePokemon
	"""
	Get the active Pokemon for a player.

	Args:
		player: Player number (1 or 2)

	Returns:
		Active BattlePokemon for the specified player
	"""
	assert(player == 1 or player == 2, "BattleState: player must be 1 or 2, got %d" % player)

	if player == 1:
		assert(active1_index < team1.size(), "BattleState: invalid active1_index")
		return team1[active1_index]
	else:
		assert(active2_index < team2.size(), "BattleState: invalid active2_index")
		return team2[active2_index]


func get_inactive_pokemon(player: int):  # Returns Array of BattlePokemon
	"""
	Get all non-active Pokemon for a player that can be switched in.

	Args:
		player: Player number (1 or 2)

	Returns:
		Array of inactive BattlePokemon (not fainted, not currently active)
	"""
	assert(player == 1 or player == 2, "BattleState: player must be 1 or 2, got %d" % player)

	var inactive = []  # Array of BattlePokemon
	var team = team1 if player == 1 else team2
	var active_index = active1_index if player == 1 else active2_index

	for i in range(team.size()):
		if i != active_index and not team[i].is_fainted():
			inactive.append(team[i])

	return inactive


func get_team(player: int):  # Returns Array of BattlePokemon
	"""
	Get a player's full team.

	Args:
		player: Player number (1 or 2)

	Returns:
		Array of all Pokemon on the player's team
	"""
	assert(player == 1 or player == 2, "BattleState: player must be 1 or 2, got %d" % player)
	return team1 if player == 1 else team2


func switch_pokemon(player: int, new_index: int) -> void:
	"""
	Switch a player's active Pokemon.

	Args:
		player: Player number (1 or 2)
		new_index: Index of Pokemon to switch to (0-5)
	"""
	assert(player == 1 or player == 2, "BattleState: player must be 1 or 2, got %d" % player)

	var team = get_team(player)
	assert(new_index >= 0 and new_index < team.size(),
		"BattleState: invalid switch index %d for team size %d" % [new_index, team.size()])

	var new_pokemon = team[new_index]
	assert(not new_pokemon.is_fainted(),
		"BattleState: cannot switch to fainted Pokemon (%s)" % new_pokemon.get_display_name())

	if player == 1:
		assert(new_index != active1_index,
			"BattleState: cannot switch to already active Pokemon")
		active1_index = new_index
	else:
		assert(new_index != active2_index,
			"BattleState: cannot switch to already active Pokemon")
		active2_index = new_index


func can_switch(player: int) -> bool:
	"""
	Check if a player has any Pokemon they can switch to.

	Args:
		player: Player number (1 or 2)

	Returns:
		true if player has at least one non-fainted, non-active Pokemon
	"""
	return get_inactive_pokemon(player).size() > 0


func has_available_pokemon(player: int) -> bool:
	"""
	Check if a player has any non-fainted Pokemon remaining.

	Args:
		player: Player number (1 or 2)

	Returns:
		true if player has at least one non-fainted Pokemon
	"""
	var team = get_team(player)
	for pokemon in team:
		if not pokemon.is_fainted():
			return true
	return false


func set_weather(new_weather: String, duration: int = 5) -> void:
	"""
	Set the weather condition.

	Args:
		new_weather: Weather type (must be valid)
		duration: Number of turns weather lasts (-1 for infinite, default 5)
	"""
	assert(new_weather in VALID_WEATHER,
		"BattleState: invalid weather '%s'" % new_weather)

	weather = new_weather
	weather_turns_remaining = duration if new_weather != "none" else 0


func set_terrain(new_terrain: String, duration: int = 5) -> void:
	"""
	Set the terrain.

	Args:
		new_terrain: Terrain type (must be valid)
		duration: Number of turns terrain lasts (-1 for infinite, default 5)
	"""
	assert(new_terrain in VALID_TERRAIN,
		"BattleState: invalid terrain '%s'" % new_terrain)

	terrain = new_terrain
	terrain_turns_remaining = duration if new_terrain != "none" else 0


func advance_turn() -> void:
	"""
	Advance to the next turn and update weather/terrain counters.
	"""
	turn_number += 1

	# Update weather
	if weather != "none" and weather_turns_remaining > 0:
		weather_turns_remaining -= 1
		if weather_turns_remaining == 0:
			weather = "none"

	# Update terrain
	if terrain != "none" and terrain_turns_remaining > 0:
		terrain_turns_remaining -= 1
		if terrain_turns_remaining == 0:
			terrain = "none"


func check_battle_end() -> void:
	"""
	Check if the battle has ended and update battle_status.
	Called after each turn to determine if a player has won.
	"""
	if battle_status != BattleStatus.IN_PROGRESS:
		return

	var player1_has_pokemon = has_available_pokemon(1)
	var player2_has_pokemon = has_available_pokemon(2)

	if not player1_has_pokemon and not player2_has_pokemon:
		battle_status = BattleStatus.DRAW
	elif not player1_has_pokemon:
		battle_status = BattleStatus.PLAYER2_WIN
	elif not player2_has_pokemon:
		battle_status = BattleStatus.PLAYER1_WIN


func is_battle_over() -> bool:
	"""
	Check if the battle has ended.

	Returns:
		true if battle is over (win, loss, or draw)
	"""
	return battle_status != BattleStatus.IN_PROGRESS and battle_status != BattleStatus.NOT_STARTED


func get_winner() -> int:
	"""
	Get the winning player number.

	Returns:
		1 if player 1 won, 2 if player 2 won, 0 if draw or battle ongoing
	"""
	match battle_status:
		BattleStatus.PLAYER1_WIN:
			return 1
		BattleStatus.PLAYER2_WIN:
			return 2
		_:
			return 0


func forfeit(player: int) -> void:
	"""
	Player forfeits the battle.

	Args:
		player: Player number who is forfeiting (1 or 2)
	"""
	assert(player == 1 or player == 2, "BattleState: player must be 1 or 2, got %d" % player)
	assert(battle_status == BattleStatus.IN_PROGRESS, "BattleState: cannot forfeit when battle not in progress")

	if player == 1:
		battle_status = BattleStatus.PLAYER2_WIN
	else:
		battle_status = BattleStatus.PLAYER1_WIN


func random_int(min_val: int, max_val: int) -> int:
	"""
	Generate a random integer using battle's RNG.

	Args:
		min_val: Minimum value (inclusive)
		max_val: Maximum value (inclusive)

	Returns:
		Random integer between min_val and max_val
	"""
	return _rng.randi_range(min_val, max_val)


func random_float() -> float:
	"""
	Generate a random float using battle's RNG.

	Returns:
		Random float between 0.0 and 1.0
	"""
	return _rng.randf()


func get_battle_summary() -> Dictionary:
	"""
	Get a summary of the current battle state.

	Returns:
		Dictionary containing key battle information
	"""
	return {
		"turn": turn_number,
		"weather": weather,
		"weather_turns": weather_turns_remaining,
		"terrain": terrain,
		"terrain_turns": terrain_turns_remaining,
		"status": _get_status_string(),
		"team1_size": team1.size(),
		"team2_size": team2.size(),
		"team1_active": get_active_pokemon(1).get_display_name() if team1.size() > 0 else "None",
		"team2_active": get_active_pokemon(2).get_display_name() if team2.size() > 0 else "None",
		"team1_remaining": _count_alive(team1),
		"team2_remaining": _count_alive(team2)
	}


func _get_status_string() -> String:
	"""Get battle status as a readable string."""
	match battle_status:
		BattleStatus.NOT_STARTED:
			return "Not Started"
		BattleStatus.IN_PROGRESS:
			return "In Progress"
		BattleStatus.PLAYER1_WIN:
			return "Player 1 Victory"
		BattleStatus.PLAYER2_WIN:
			return "Player 2 Victory"
		BattleStatus.DRAW:
			return "Draw"
		_:
			return "Unknown"


func _count_alive(team) -> int:  # Array of BattlePokemon parameter
	"""Count non-fainted Pokemon in a team."""
	var count = 0
	for pokemon in team:
		if not pokemon.is_fainted():
			count += 1
	return count


func to_dict() -> Dictionary:
	"""
	Serialize battle state to a dictionary for network transmission.

	Returns:
		Dictionary containing complete battle state including teams
	"""
	# Serialize teams
	var team1_data = []
	for pokemon in team1:
		team1_data.append(pokemon.to_dict())

	var team2_data = []
	for pokemon in team2:
		team2_data.append(pokemon.to_dict())

	return {
		"turn_number": turn_number,
		"weather": weather,
		"weather_turns_remaining": weather_turns_remaining,
		"terrain": terrain,
		"terrain_turns_remaining": terrain_turns_remaining,
		"active1_index": active1_index,
		"active2_index": active2_index,
		"rng_seed": rng_seed,
		"battle_status": battle_status,
		"team1": team1_data,
		"team2": team2_data
	}


static func from_dict(data: Dictionary) -> BattleState:
	"""
	Reconstruct a BattleState from a dictionary.

	Args:
		data: Dictionary containing battle state data (from to_dict())

	Returns:
		New BattleState instance reconstructed from data
	"""
	# Create new state with same RNG seed
	var state = BattleState.new(data["rng_seed"])

	# Restore basic state
	state.turn_number = data["turn_number"]
	state.weather = data["weather"]
	state.weather_turns_remaining = data["weather_turns_remaining"]
	state.terrain = data["terrain"]
	state.terrain_turns_remaining = data["terrain_turns_remaining"]
	state.active1_index = data["active1_index"]
	state.active2_index = data["active2_index"]
	state.battle_status = data["battle_status"]

	# Restore teams
	state.team1.clear()
	for pokemon_data in data["team1"]:
		state.team1.append(BattlePokemonScript.from_dict(pokemon_data))

	state.team2.clear()
	for pokemon_data in data["team2"]:
		state.team2.append(BattlePokemonScript.from_dict(pokemon_data))

	return state


func clone() -> BattleState:
	"""
	Create a deep copy of this battle state.
	Note: Teams are not cloned, only referenced.

	Returns:
		New BattleState with identical properties
	"""
	var new_state = get_script().new(rng_seed)
	new_state.turn_number = turn_number
	new_state.weather = weather
	new_state.weather_turns_remaining = weather_turns_remaining
	new_state.terrain = terrain
	new_state.terrain_turns_remaining = terrain_turns_remaining
	new_state.team1 = team1.duplicate()
	new_state.team2 = team2.duplicate()
	new_state.active1_index = active1_index
	new_state.active2_index = active2_index
	new_state.battle_status = battle_status
	return new_state
