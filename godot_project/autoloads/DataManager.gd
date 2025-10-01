extends Node

## DataManager - Pokemon Data Loading System
##
## Manages loading and caching of Pokemon, move, ability, and item data.
## Uses lazy loading with caching for optimal performance.
## Loaded as an autoload singleton.

# Cached data (loaded on-demand)
var pokemon_cache: Dictionary = {}  # id -> PokemonData
var move_cache: Dictionary = {}     # id -> MoveData
var ability_cache: Dictionary = {}  # id -> AbilityData
var item_cache: Dictionary = {}     # id -> ItemData

# Name lookup tables (for searching by name)
var pokemon_by_name: Dictionary = {}
var move_by_name: Dictionary = {}
var ability_by_name: Dictionary = {}
var item_by_name: Dictionary = {}

# Resource paths
const POKEMON_PATH = "res://resources/pokemon/"
const MOVE_PATH = "res://resources/moves/"
const ABILITY_PATH = "res://resources/abilities/"
const ITEM_PATH = "res://resources/items/"

# Preload flags
var data_preloaded: bool = false


func _ready() -> void:
	"""Initialize on game start."""
	print("[DataManager] Ready - using lazy loading")
	# Optionally preload common data here
	# preload_common_data()


func preload_common_data() -> void:
	"""
	Preload frequently used Pokemon and moves.
	Call this during a loading screen to reduce latency.
	"""
	print("[DataManager] Preloading common data...")

	# TODO: Preload top 50 OU Pokemon, common moves, etc.
	# For now, just mark as preloaded
	data_preloaded = true

	print("[DataManager] Preload complete")


## Pokemon Data Methods

func get_pokemon(pokemon_id: int) -> PokemonData:
	"""
	Get Pokemon data by ID. Uses caching.
	Returns null if not found.
	"""
	if pokemon_id in pokemon_cache:
		return pokemon_cache[pokemon_id]

	var resource_path = "%s%d.tres" % [POKEMON_PATH, pokemon_id]

	if not ResourceLoader.exists(resource_path):
		push_warning("[DataManager] Pokemon %d not found" % pokemon_id)
		return null

	var pokemon_data: PokemonData = load(resource_path)
	pokemon_cache[pokemon_id] = pokemon_data
	pokemon_by_name[pokemon_data.name.to_lower()] = pokemon_data

	return pokemon_data


func get_pokemon_by_name(pokemon_name: String) -> PokemonData:
	"""
	Get Pokemon data by name (case-insensitive).
	Returns null if not found.
	"""
	var name_lower = pokemon_name.to_lower()

	if name_lower in pokemon_by_name:
		return pokemon_by_name[name_lower]

	# Try to find by searching all files (slow, but works)
	# TODO: Build index file during transformation
	push_warning("[DataManager] Pokemon '%s' not in cache, searching..." % pokemon_name)
	return null


## Move Data Methods

func get_move(move_id: int) -> MoveData:
	"""
	Get move data by ID. Uses caching.
	Returns null if not found.
	"""
	if move_id in move_cache:
		return move_cache[move_id]

	var resource_path = "%s%d.tres" % [MOVE_PATH, move_id]

	if not ResourceLoader.exists(resource_path):
		push_warning("[DataManager] Move %d not found" % move_id)
		return null

	var move_data: MoveData = load(resource_path)
	move_cache[move_id] = move_data
	move_by_name[move_data.name.to_lower()] = move_data

	return move_data


func get_move_by_name(move_name: String) -> MoveData:
	"""
	Get move data by name (case-insensitive).
	Returns null if not found.
	"""
	var name_lower = move_name.to_lower()

	if name_lower in move_by_name:
		return move_by_name[name_lower]

	# Fallback search
	push_warning("[DataManager] Move '%s' not in cache" % move_name)
	return null


## Ability Data Methods

func get_ability(ability_id: int) -> AbilityData:
	"""
	Get ability data by ID. Uses caching.
	Returns null if not found.
	"""
	if ability_id in ability_cache:
		return ability_cache[ability_id]

	var resource_path = "%s%d.tres" % [ABILITY_PATH, ability_id]

	if not ResourceLoader.exists(resource_path):
		push_warning("[DataManager] Ability %d not found" % ability_id)
		return null

	var ability_data: AbilityData = load(resource_path)
	ability_cache[ability_id] = ability_data
	ability_by_name[ability_data.name.to_lower()] = ability_data

	return ability_data


func get_ability_by_name(ability_name: String) -> AbilityData:
	"""
	Get ability data by name (case-insensitive).
	Returns null if not found.
	"""
	var name_lower = ability_name.to_lower()

	if name_lower in ability_by_name:
		return ability_by_name[name_lower]

	push_warning("[DataManager] Ability '%s' not in cache" % ability_name)
	return null


## Item Data Methods

func get_item(item_id: int) -> ItemData:
	"""
	Get item data by ID. Uses caching.
	Returns null if not found.
	"""
	if item_id in item_cache:
		return item_cache[item_id]

	var resource_path = "%s%d.tres" % [ITEM_PATH, item_id]

	if not ResourceLoader.exists(resource_path):
		push_warning("[DataManager] Item %d not found" % item_id)
		return null

	var item_data: ItemData = load(resource_path)
	item_cache[item_id] = item_data
	item_by_name[item_data.name.to_lower()] = item_data

	return item_data


func get_item_by_name(item_name: String) -> ItemData:
	"""
	Get item data by name (case-insensitive).
	Returns null if not found.
	"""
	var name_lower = item_name.to_lower()

	if name_lower in item_by_name:
		return item_by_name[name_lower]

	push_warning("[DataManager] Item '%s' not in cache" % item_name)
	return null


## Cache Management

func clear_cache() -> void:
	"""Clear all cached data (free memory)."""
	pokemon_cache.clear()
	move_cache.clear()
	ability_cache.clear()
	item_cache.clear()
	pokemon_by_name.clear()
	move_by_name.clear()
	ability_by_name.clear()
	item_by_name.clear()
	print("[DataManager] Cache cleared")


func get_cache_stats() -> Dictionary:
	"""Get cache statistics for debugging."""
	return {
		"pokemon_cached": pokemon_cache.size(),
		"moves_cached": move_cache.size(),
		"abilities_cached": ability_cache.size(),
		"items_cached": item_cache.size()
	}
