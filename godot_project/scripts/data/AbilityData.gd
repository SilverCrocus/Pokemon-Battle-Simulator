class_name AbilityData
extends Resource

## Static ability data loaded from PokeAPI
##
## This Resource contains immutable data about an ability (effects, description).

@export var ability_id: int = 0
@export var name: String = ""
@export var effect_description: String = ""
@export var short_effect: String = ""
@export var generation: int = 9


func get_display_name() -> String:
	"""Get formatted display name (capitalize, spaces)."""
	return name.capitalize().replace("-", " ")
