extends Node

## Animation Manager - Battle Animation Sequencer
##
## Manages a queue of battle animations to prevent overlapping.
## Ensures animations play in correct order (move → damage → status → etc.)
##
## Usage:
## ```gdscript
## AnimationManager.queue_animation(func(): _play_move_animation())
## AnimationManager.queue_animation(func(): _play_damage_animation())
## AnimationManager.start_queue()  # Plays all animations in sequence
## ```

# ==================== Signals ====================

signal animation_queue_started()
signal animation_completed(animation_name: String)
signal animation_queue_finished()

# ==================== Constants ====================

# Animation durations (seconds)
const ANIM_MOVE_USE := 0.6
const ANIM_DAMAGE := 0.5
const ANIM_HEAL := 0.5
const ANIM_STATUS_APPLY := 0.4
const ANIM_FAINT := 0.8
const ANIM_SWITCH := 0.6
const ANIM_STAT_CHANGE := 0.3

# ==================== State ====================

var animation_queue: Array[Callable] = []
var is_playing: bool = false
var current_animation_name: String = ""

# ==================== Public Methods - Queue Management ====================

func queue_animation(animation_callable: Callable, name: String = "unnamed") -> void:
	"""
	Add an animation to the queue.

	@param animation_callable: Function to call that performs the animation
	@param name: Name of the animation (for debugging)
	"""
	animation_queue.append(animation_callable)
	if name:
		current_animation_name = name


func clear_queue() -> void:
	"""Clear all queued animations."""
	animation_queue.clear()
	is_playing = false
	current_animation_name = ""


func start_queue() -> void:
	"""Start playing all queued animations in sequence."""
	if is_playing:
		push_warning("[AnimationManager] Already playing animations")
		return

	if animation_queue.is_empty():
		push_warning("[AnimationManager] No animations queued")
		return

	is_playing = true
	animation_queue_started.emit()

	await _play_next_animation()

	# Queue finished
	is_playing = false
	animation_queue_finished.emit()


func is_queue_empty() -> bool:
	"""Check if animation queue is empty."""
	return animation_queue.is_empty()


func get_queue_size() -> int:
	"""Get number of animations in queue."""
	return animation_queue.size()


# ==================== Private Methods ====================

func _play_next_animation() -> void:
	"""Play the next animation in the queue."""
	while not animation_queue.is_empty():
		var animation_callable = animation_queue.pop_front()

		# Call the animation function
		animation_callable.call()

		# Emit completion signal
		animation_completed.emit(current_animation_name)

		# Wait a frame to ensure animation starts
		await get_tree().process_frame


# ==================== Animation Helpers ====================

func wait_for(duration: float) -> void:
	"""
	Helper function to wait for a duration.

	@param duration: Time to wait in seconds
	"""
	await get_tree().create_timer(duration).timeout


# ==================== Pre-built Animation Templates ====================

func create_move_animation(user_sprite: Node2D, target_sprite: Node2D) -> Callable:
	"""
	Create a move use animation.

	@param user_sprite: Sprite of Pokemon using the move
	@param target_sprite: Sprite of target Pokemon
	@return: Callable animation function
	"""
	return func():
		# Flash the user sprite
		if user_sprite:
			var original_modulate = user_sprite.modulate
			user_sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)
			await get_tree().create_timer(0.2).timeout
			user_sprite.modulate = original_modulate

		await get_tree().create_timer(0.4).timeout


func create_damage_animation(target_sprite: Node2D, hp_bar) -> Callable:
	"""
	Create a damage animation.

	@param target_sprite: Sprite of Pokemon taking damage
	@param hp_bar: HPBar component to animate
	@return: Callable animation function
	"""
	return func():
		# Shake the target sprite
		if target_sprite:
			var original_pos = target_sprite.position
			var tween = create_tween()
			tween.set_loops(3)
			tween.tween_property(target_sprite, "position:x", original_pos.x + 5, 0.05)
			tween.tween_property(target_sprite, "position:x", original_pos.x - 5, 0.05)
			await tween.finished
			target_sprite.position = original_pos

		# HP bar will animate automatically via HPBar.animate_to()
		await get_tree().create_timer(0.2).timeout


func create_status_animation(target_sprite: Node2D, status_name: String) -> Callable:
	"""
	Create a status condition animation.

	@param target_sprite: Sprite of Pokemon receiving status
	@param status_name: Name of status condition
	@return: Callable animation function
	"""
	return func():
		if target_sprite:
			var status_color = BattleTheme.get_status_color(status_name)
			var original_modulate = target_sprite.modulate

			# Flash with status color
			target_sprite.modulate = status_color
			await get_tree().create_timer(0.2).timeout
			target_sprite.modulate = original_modulate
			await get_tree().create_timer(0.1).timeout
			target_sprite.modulate = status_color
			await get_tree().create_timer(0.2).timeout
			target_sprite.modulate = original_modulate


func create_faint_animation(target_sprite: Node2D) -> Callable:
	"""
	Create a faint animation.

	@param target_sprite: Sprite of fainting Pokemon
	@return: Callable animation function
	"""
	return func():
		if target_sprite:
			# Fade out and slide down
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(target_sprite, "modulate:a", 0.0, ANIM_FAINT)
			tween.tween_property(target_sprite, "position:y", target_sprite.position.y + 50, ANIM_FAINT)
			await tween.finished


func create_switch_animation(old_sprite: Node2D, new_sprite: Node2D) -> Callable:
	"""
	Create a Pokemon switch animation.

	@param old_sprite: Sprite of Pokemon being withdrawn
	@param new_sprite: Sprite of Pokemon being sent out
	@return: Callable animation function
	"""
	return func():
		# Withdraw old Pokemon
		if old_sprite:
			var tween = create_tween()
			tween.tween_property(old_sprite, "modulate:a", 0.0, ANIM_SWITCH / 2)
			await tween.finished

		await get_tree().create_timer(0.1).timeout

		# Send out new Pokemon
		if new_sprite:
			new_sprite.modulate.a = 0.0
			new_sprite.visible = true
			var tween = create_tween()
			tween.tween_property(new_sprite, "modulate:a", 1.0, ANIM_SWITCH / 2)
			await tween.finished


func create_stat_change_animation(target_sprite: Node2D, is_increase: bool) -> Callable:
	"""
	Create a stat change animation.

	@param target_sprite: Sprite of Pokemon whose stats changed
	@param is_increase: True for stat increase, false for decrease
	@return: Callable animation function
	"""
	return func():
		if target_sprite:
			var color = Color(0.4, 1.0, 0.4, 1.0) if is_increase else Color(1.0, 0.4, 0.4, 1.0)
			var original_modulate = target_sprite.modulate

			# Flash with stat color
			target_sprite.modulate = color
			await get_tree().create_timer(0.15).timeout
			target_sprite.modulate = original_modulate
			await get_tree().create_timer(0.15).timeout
