extends PanelContainer

## Battle Log / Dialogue Box Component (Gen 5 Style)
##
## Displays battle messages with character-by-character text reveal.
## Classic Pokemon text box with auto-scrolling for multiple messages.

# ==================== Signals ====================

signal text_finished()  # Emitted when current text reveal is complete

# ==================== Constants ====================

const CHARS_PER_SECOND := 30.0  # Gen 5 text reveal speed
const CHAR_DELAY := 1.0 / CHARS_PER_SECOND

# ==================== Node References ====================

@onready var scroll_container: ScrollContainer = $MarginContainer/ScrollContainer
@onready var log_label: RichTextLabel = $MarginContainer/ScrollContainer/LogLabel

# ==================== State ====================

var message_queue: Array[String] = []
var is_revealing: bool = false
var current_text: String = ""
var reveal_index: int = 0
var time_since_last_char: float = 0.0

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the battle log."""
	_setup_styling()


func _process(delta: float) -> void:
	"""Handle text reveal animation."""
	if not is_revealing:
		return

	time_since_last_char += delta

	# Reveal next character when enough time has passed
	if time_since_last_char >= CHAR_DELAY:
		time_since_last_char = 0.0
		_reveal_next_char()


# ==================== Public Methods ====================

func add_message(message: String, instant: bool = false) -> void:
	"""
	Add a message to the log.

	@param message: Text to display
	@param instant: If true, show immediately without character-by-character reveal
	"""
	if instant:
		_append_text_instant(message)
	else:
		message_queue.append(message)
		if not is_revealing:
			_start_next_message()


func clear() -> void:
	"""Clear all messages from the log."""
	log_label.clear()
	message_queue.clear()
	is_revealing = false
	current_text = ""
	reveal_index = 0


func skip_current_reveal() -> void:
	"""Instantly show the rest of the currently revealing text."""
	if is_revealing and current_text:
		# Show full text immediately
		log_label.clear()
		log_label.append_text(current_text)
		_finish_reveal()


# ==================== Private Methods ====================

func _setup_styling() -> void:
	"""Apply Gen 5 visual styling."""
	# Panel background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = BattleTheme.BG_DARK
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = BattleTheme.BORDER_LIGHT
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", style_box)

	# Configure RichTextLabel
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	log_label.add_theme_color_override("default_color", BattleTheme.TEXT_WHITE)
	log_label.add_theme_font_size_override("normal_font_size", 16)

	# Configure ScrollContainer
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED


func _start_next_message() -> void:
	"""Start revealing the next message in the queue."""
	if message_queue.is_empty():
		return

	is_revealing = true
	current_text = message_queue.pop_front()
	reveal_index = 0
	time_since_last_char = 0.0

	# Add newline if there's existing text
	if log_label.get_parsed_text().length() > 0:
		log_label.append_text("\n")


func _reveal_next_char() -> void:
	"""Reveal the next character in the current message."""
	if reveal_index >= current_text.length():
		_finish_reveal()
		return

	# Get next character and append it
	var char = current_text[reveal_index]
	log_label.append_text(char)

	reveal_index += 1

	# Auto-scroll to bottom
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)


func _finish_reveal() -> void:
	"""Finish the current text reveal."""
	is_revealing = false
	text_finished.emit()

	# Start next message if available
	if not message_queue.is_empty():
		await get_tree().create_timer(0.5).timeout  # Brief pause between messages
		_start_next_message()


func _append_text_instant(message: String) -> void:
	"""Append text instantly without reveal animation."""
	# Add newline if there's existing text
	if log_label.get_parsed_text().length() > 0:
		log_label.append_text("\n")

	log_label.append_text(message)

	# Auto-scroll to bottom
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
