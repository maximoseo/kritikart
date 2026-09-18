# KritiKart — on-screen touch controls for the race scenes.
#
# Injected into both race scenes by RaceFlowOverlay. Multi-touch safe: every
# finger (touch index) is tracked independently, so steering with the left
# thumb while holding GAS with the right thumb works. Button presses are
# translated into InputEventAction events for the existing input actions
# (drive_accelerate, drive_brake, drive_left, drive_right, drive_drift,
# camera_toggle_primary, ui_cancel), so PlayerDriver and the pause overlay
# pick them up exactly like keyboard input — no gameplay code changes needed.
#
# Visibility rules:
#   * auto-visible when the device reports a touchscreen (phones/tablets),
#   * also self-activates on the first InputEventScreenTouch seen (covers
#     browsers where touchscreen detection is unreliable),
#   * mouse fallback drives the buttons when no touchscreen exists (desktop
#     testing). On touchscreen devices emulated-mouse events are ignored so a
#     tap is never counted twice.
#
# RaceFlowOverlay deactivates the layer (set_controls_active(false)) while the
# pause menu or results screen is up; deactivation releases every held action.
extends CanvasLayer
class_name TouchControlsLayer

const ACTION_STEER_LEFT: StringName = &"drive_left"
const ACTION_STEER_RIGHT: StringName = &"drive_right"
const ACTION_ACCELERATE: StringName = &"drive_accelerate"
const ACTION_BRAKE: StringName = &"drive_brake"
const ACTION_DRIFT: StringName = &"drive_drift"
const ACTION_CAMERA_TOGGLE: StringName = &"camera_toggle_primary"
const ACTION_PAUSE: StringName = &"ui_cancel"

var _root: Control = null
var _buttons: Array = []
var _touch_to_button: Dictionary = {}
var _mouse_held_button: VirtualPadButton = null
var _touchscreen_mode: bool = false
var _active: bool = true

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_touchscreen_mode = DisplayServer.is_touchscreen_available()
	_build_interface()
	_root.visible = _touchscreen_mode
	get_viewport().size_changed.connect(Callable(self, "_refresh_layout"))


func _exit_tree() -> void:
	_release_all_held()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not _touchscreen_mode:
			_touchscreen_mode = true
			if _active:
				_root.visible = true
		if not _active or not _root.visible:
			return
		if event.pressed:
			var button := _button_at(event.position)
			if button != null:
				_touch_to_button[event.index] = button
				_set_button_held(button, true)
				get_viewport().set_input_as_handled()
		else:
			var held: VirtualPadButton = _touch_to_button.get(event.index)
			if held != null:
				_touch_to_button.erase(event.index)
				_set_button_held(held, false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _touchscreen_mode:
			return
		if not _active or not _root.visible:
			return
		if event.pressed:
			var button := _button_at(event.position)
			if button != null:
				_mouse_held_button = button
				_set_button_held(button, true)
				get_viewport().set_input_as_handled()
		elif _mouse_held_button != null:
			_set_button_held(_mouse_held_button, false)
			_mouse_held_button = null


func set_controls_active(active: bool) -> void:
	_active = active
	if not active:
		_release_all_held()
	if _root != null:
		_root.visible = active and _touchscreen_mode


func get_touchscreen_mode() -> bool:
	return _touchscreen_mode


func _release_all_held() -> void:
	for button in _buttons:
		if button is VirtualPadButton and button.is_held:
			_emit_action(button.action, false)
			button.set_held(false)
	_touch_to_button.clear()
	_mouse_held_button = null


func _button_at(position: Vector2) -> VirtualPadButton:
	for button in _buttons:
		if button is VirtualPadButton and button.visible and button.get_global_rect().grow(10.0).has_point(position):
			return button
	return null


func _set_button_held(button: VirtualPadButton, held: bool) -> void:
	if button.is_held == held:
		return
	button.set_held(held)
	_emit_action(button.action, held)


func _emit_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _refresh_layout() -> void:
	_layout_buttons()


func _build_interface() -> void:
	_root = Control.new()
	_root.name = "TouchControlsRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_make_button("SteerLeft", "arrow_left", ACTION_STEER_LEFT, Color(0.42, 0.83, 1.0, 0.95))
	_make_button("SteerRight", "arrow_right", ACTION_STEER_RIGHT, Color(0.42, 0.83, 1.0, 0.95))
	_make_button("Gas", "caption", ACTION_ACCELERATE, Color(0.30, 0.88, 0.45, 0.95), "GAS")
	_make_button("Brake", "caption", ACTION_BRAKE, Color(1.0, 0.30, 0.34, 0.95), "BRAKE")
	_make_button("Drift", "caption", ACTION_DRIFT, Color(1.0, 0.66, 0.12, 0.95), "DRIFT")
	_make_button("Camera", "caption", ACTION_CAMERA_TOGGLE, Color(0.72, 0.74, 0.82, 0.92), "CAM", true)
	_make_button("Pause", "caption", ACTION_PAUSE, Color(0.72, 0.74, 0.82, 0.92), "II", true)
	_layout_buttons()


func _make_button(button_name: String, kind: String, action: StringName, accent: Color, caption: String = "", utility: bool = false) -> void:
	var button := VirtualPadButton.new()
	button.name = button_name
	button.kind = kind
	button.action = action
	button.accent = accent
	button.caption = caption
	button.utility = utility
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(button)
	_buttons.append(button)


func _layout_buttons() -> void:
	if _root == null or _buttons.is_empty():
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var short_side := minf(viewport_size.x, viewport_size.y)
	var pad_scale: float = clampf(short_side / 1080.0, 0.55, 1.35)
	var margin := 40.0 * pad_scale
	var steer_size := 196.0 * pad_scale
	var pedal_big := 232.0 * pad_scale
	var pedal_small := 168.0 * pad_scale
	var utility_size := 92.0 * pad_scale

	for button in _buttons:
		var pad := button as VirtualPadButton
		match String(pad.name):
			"SteerLeft":
				pad.size = Vector2(steer_size, steer_size)
				pad.position = Vector2(margin, viewport_size.y - steer_size - margin)
			"SteerRight":
				pad.size = Vector2(steer_size, steer_size)
				pad.position = Vector2(margin + steer_size + 22.0 * pad_scale, viewport_size.y - steer_size - margin)
			"Gas":
				pad.size = Vector2(pedal_big, pedal_big)
				pad.position = Vector2(viewport_size.x - pedal_big - margin, viewport_size.y - pedal_big - margin)
			"Brake":
				pad.size = Vector2(pedal_small, pedal_small)
				pad.position = Vector2(viewport_size.x - pedal_big - margin - pedal_small - 26.0 * pad_scale, viewport_size.y - pedal_small - margin)
			"Drift":
				pad.size = Vector2(pedal_small, pedal_small)
				pad.position = Vector2(viewport_size.x - pedal_small - 30.0 * pad_scale, viewport_size.y - pedal_big - margin - pedal_small - 20.0 * pad_scale)
			"Camera":
				pad.size = Vector2(utility_size, utility_size)
				pad.position = Vector2(viewport_size.x - utility_size - margin, margin)
			"Pause":
				pad.size = Vector2(utility_size, utility_size)
				pad.position = Vector2(viewport_size.x - utility_size * 2.0 - margin - 16.0 * pad_scale, margin)
		pad.queue_redraw()


class VirtualPadButton:
	extends Control

	const COLOR_GLYPH: Color = Color(1.0, 1.0, 1.0, 0.97)
	const COLOR_FILL_IDLE: Color = Color(0.043, 0.055, 0.090, 0.46)
	const COLOR_FILL_HELD: Color = Color(0.10, 0.16, 0.30, 0.80)

	var action: StringName = &""
	var kind: String = "caption"
	var caption: String = ""
	var accent: Color = Color.WHITE
	var utility: bool = false
	var is_held: bool = false

	func set_held(held: bool) -> void:
		if is_held == held:
			return
		is_held = held
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5
		var fill_color := COLOR_FILL_HELD if is_held else COLOR_FILL_IDLE
		var border_color := accent if is_held else Color(accent, 0.75)
		if utility and not is_held:
			border_color = Color(1.0, 1.0, 1.0, 0.34)
		draw_circle(center, radius, fill_color)
		draw_arc(center, radius - 2.0, 0.0, TAU, 48, border_color, 4.0, true)
		if kind == "arrow_left" or kind == "arrow_right":
			_draw_arrow(center, radius)
		elif not caption.is_empty():
			_draw_caption(center, radius)

	func _draw_arrow(center: Vector2, radius: float) -> void:
		var glyph := Color.WHITE if is_held else COLOR_GLYPH
		var h := radius * 0.52
		var w := radius * 0.60
		var dir := 1.0 if kind == "arrow_right" else -1.0
		var tip := center + Vector2(dir * w * 0.62, 0.0)
		var back_top := center + Vector2(-dir * w * 0.38, -h)
		var back_bottom := center + Vector2(-dir * w * 0.38, h)
		draw_colored_polygon(PackedVector2Array([tip, back_top, back_bottom]), glyph)

	func _draw_caption(center: Vector2, radius: float) -> void:
		var font := ThemeDB.fallback_font
		var font_size := int(clampf(radius * (0.42 if caption.length() <= 2 else 0.34), 14.0, 64.0))
		var text_size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var draw_position := center + Vector2(-text_size.x * 0.5, text_size.y * 0.5 - font_size * 0.06)
		var glyph := Color.WHITE if is_held else COLOR_GLYPH
		draw_string(font, draw_position, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, glyph)
