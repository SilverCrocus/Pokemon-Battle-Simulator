class_name ItemData
extends Resource

## Static item data loaded from PokeAPI
##
## This Resource contains immutable data about an item (effects, category).

@export var item_id: int = 0
@export var name: String = ""
@export var category: String = ""  # "held-items", "consumables", "berries", etc.

# Effects
@export var effect_description: String = ""
@export var short_effect: String = ""

# Attributes
@export var is_holdable: bool = false
@export var is_consumable: bool = false
@export var is_usable_in_battle: bool = false

# Metadata
@export var generation: int = 9


func is_berry() -> bool:
	"""Check if item is a berry."""
	return category == "berries" or name.ends_with("berry")


func is_choice_item() -> bool:
	"""Check if item is a Choice item (Band/Scarf/Specs)."""
	return name in ["choice-band", "choice-scarf", "choice-specs"]


func get_display_name() -> String:
	"""Get formatted display name (capitalize, spaces)."""
	return name.capitalize().replace("-", " ")
