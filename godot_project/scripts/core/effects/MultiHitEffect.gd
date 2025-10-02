class_name MultiHitEffect
extends MoveEffect

## Multi-hit effect
##
## Move hits multiple times in succession. Each hit can be a critical hit
## and type effectiveness applies to all hits.
##
## Hit Distribution (Gen 5+):
##   - 2 hits: 35% (e.g., Double Kick, Bonemerang)
##   - 3 hits: 35%
##   - 4 hits: 15%
##   - 5 hits: 15%
##
## Examples:
##   - Bullet Seed: 2-5 hits
##   - Icicle Spear: 2-5 hits
##   - Rock Blast: 2-5 hits
##   - Pin Missile: 2-5 hits
##   - Tail Slap: 2-5 hits
##   - Double Kick: Always 2 hits
##   - Triple Kick: 1-3 hits (special mechanics)

var min_hits: int = 2
var max_hits: int = 5


func _init(minimum: int = 2, maximum: int = 5) -> void:
	super._init("Multi-hit (%d-%d)" % [minimum, maximum], 100, false)
	min_hits = minimum
	max_hits = maximum


func execute(context: Dictionary) -> Dictionary:
	"""
	Determine number of hits for this multi-hit move.

	Gen 5+ distribution for 2-5 hits:
	- 2-3 hits: 35% each (70% combined)
	- 4-5 hits: 15% each (30% combined)

	Args:
		context: Must contain:
			- rng: RandomNumberGenerator

	Returns:
		success: true
		message: Number of hits
		data: hit_count
	"""
	var rng = context["rng"]  # RandomNumberGenerator

	var hit_count: int

	if min_hits == max_hits:
		# Fixed hit count (e.g., Double Kick always 2)
		hit_count = min_hits
	elif max_hits - min_hits == 3:
		# Standard 2-5 distribution
		var roll = rng.randi_range(1, 100)
		if roll <= 35:
			hit_count = min_hits  # 2 hits
		elif roll <= 70:
			hit_count = min_hits + 1  # 3 hits
		elif roll <= 85:
			hit_count = min_hits + 2  # 4 hits
		else:
			hit_count = max_hits  # 5 hits
	else:
		# Other distributions - uniform random
		hit_count = rng.randi_range(min_hits, max_hits)

	return {
		"success": true,
		"message": "Hit %d times!" % hit_count,
		"data": {"hit_count": hit_count}
	}


func get_description() -> String:
	"""Get description with hit range."""
	if min_hits == max_hits:
		return "Hits %d times" % min_hits
	else:
		return "Hits %d-%d times" % [min_hits, max_hits]
