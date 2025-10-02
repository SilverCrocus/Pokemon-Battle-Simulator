class_name HazardEffect
extends MoveEffect

## Entry hazard effect
##
## Sets up entry hazards on the opponent's side of the field.
## Hazards damage Pokemon when they switch in.
##
## Hazard Types:
##   - stealth_rock: Deals damage based on Rock type effectiveness (1/32 to 1/2 max HP)
##   - spikes: Deals 1/8 max HP (1 layer), 1/6 (2 layers), 1/4 (3 layers)
##   - toxic_spikes: Poisons (1 layer) or badly poisons (2 layers) on switch-in
##   - sticky_web: Lowers Speed by 1 stage on switch-in
##
## Examples:
##   - Stealth Rock: Sets stealth rocks
##   - Spikes: Adds spikes layer (max 3)
##   - Toxic Spikes: Adds toxic spikes layer (max 2)
##   - Sticky Web: Sets sticky web

var hazard_type: String = ""  # "stealth_rock", "spikes", "toxic_spikes", "sticky_web"


func _init(hazard: String) -> void:
	super._init("Set %s" % hazard.replace("_", " ").capitalize(), 100, false)
	hazard_type = hazard


func execute(context: Dictionary) -> Dictionary:
	"""
	Set entry hazard on opponent's side.

	Args:
		context: Must contain:
			- state: BattleState
			- player: int (1 or 2) - determines which side gets hazard

	Returns:
		success: true if hazard was set
		message: Hazard description
		data: hazard type and layers
	"""
	var state = context["state"]  # BattleState
	var player = context["player"]  # int (1 or 2)

	# Hazards are set on the opponent's side
	var opponent = 3 - player

	# Get or initialize hazards dictionary for opponent's side
	if not state.has("hazards_player1"):
		state.set("hazards_player1", {})
	if not state.has("hazards_player2"):
		state.set("hazards_player2", {})

	var hazards_key = "hazards_player%d" % opponent
	var hazards = state.get(hazards_key)

	# Check max layers
	var max_layers = _get_max_layers(hazard_type)
	var current_layers = hazards.get(hazard_type, 0)

	if current_layers >= max_layers:
		return {
			"success": false,
			"message": "But it failed!",
			"data": {}
		}

	# Add hazard layer
	hazards[hazard_type] = current_layers + 1
	state.set(hazards_key, hazards)

	# Get hazard message
	var message = _get_hazard_message(hazard_type)

	return {
		"success": true,
		"message": message,
		"data": {"hazard": hazard_type, "layers": current_layers + 1}
	}


func _get_max_layers(hazard: String) -> int:
	"""Get maximum number of layers for hazard type."""
	match hazard:
		"spikes":
			return 3
		"toxic_spikes":
			return 2
		"stealth_rock", "sticky_web":
			return 1
		_:
			return 1


func _get_hazard_message(hazard: String) -> String:
	"""Get the appropriate hazard message."""
	match hazard:
		"stealth_rock":
			return "Pointed stones float in the air!"
		"spikes":
			return "Spikes were scattered all around!"
		"toxic_spikes":
			return "Poison spikes were scattered all around!"
		"sticky_web":
			return "A sticky web has been laid out!"
		_:
			return "A hazard was set!"
