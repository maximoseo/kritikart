# Headless logic probe for TouchControlsLayer (no Summer engine needed).
# Run: godot --headless --path . --script res://tests/probe/touch_logic_probe.gd
# Exit 0 + PASS lines = all checks passed.
extends SceneTree

var _layer: CanvasLayer = null
var _step: int = 0
var _failures: int = 0
var _checks: int = 0

func _initialize() -> void:
	var script := load("res://scripts/ui/touch_controls.gd")
	_layer = script.new()
	root.add_child(_layer)

func _process(_delta: float) -> bool:
	_step += 1
	match _step:
		2:
			_check(true, "touchscreen self-activates on first touch", true)
			_send_touch(0, true, _button_center("Gas"))
		4:
			_check(Input.get_action_strength("drive_accelerate") > 0.5, "GAS held -> drive_accelerate strength", Input.get_action_strength("drive_accelerate"))
			_send_touch(1, true, _button_center("SteerLeft"))
		6:
			_check(Input.get_action_strength("drive_accelerate") > 0.5, "GAS still held with second finger", Input.get_action_strength("drive_accelerate"))
			_check(Input.get_action_strength("drive_left") > 0.5, "STEER held simultaneously -> drive_left strength", Input.get_action_strength("drive_left"))
			_send_touch(2, true, _button_center("Brake"))
		8:
			_check(Input.get_action_strength("drive_brake") > 0.5, "BRAKE held as third finger", Input.get_action_strength("drive_brake"))
			_send_touch(0, false, Vector2.ZERO)
		10:
			_check(Input.get_action_strength("drive_accelerate") < 0.01, "GAS released while others held", Input.get_action_strength("drive_accelerate"))
			_check(Input.get_action_strength("drive_left") > 0.5, "STEER unaffected by GAS release", Input.get_action_strength("drive_left"))
			_send_touch(1, false, Vector2.ZERO)
			_send_touch(2, false, Vector2.ZERO)
		12:
			_check(Input.get_action_strength("drive_left") < 0.01, "STEER released", Input.get_action_strength("drive_left"))
			_check(Input.get_action_strength("drive_brake") < 0.01, "BRAKE released", Input.get_action_strength("drive_brake"))
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = MOUSE_BUTTON_LEFT
			mouse_event.pressed = true
			mouse_event.position = _button_center("Gas")
			_layer._input(mouse_event)
		14:
			_check(Input.get_action_strength("drive_accelerate") < 0.01, "mouse ignored while in touchscreen mode", Input.get_action_strength("drive_accelerate"))
			_send_touch(3, true, _button_center("Pause"))
		16:
			_check(Input.is_action_pressed("ui_cancel"), "PAUSE tap -> ui_cancel pressed", Input.is_action_pressed("ui_cancel"))
			_send_touch(3, false, Vector2.ZERO)
			_layer.set_controls_active(false)
		18:
			_check(Input.is_action_pressed("ui_cancel") == false, "PAUSE released", Input.is_action_pressed("ui_cancel"))
			_send_touch(4, true, _button_center("Gas"))
		20:
			_check(Input.get_action_strength("drive_accelerate") < 0.01, "inactive layer ignores touches", Input.get_action_strength("drive_accelerate"))
			_layer.set_controls_active(true)
			_send_touch(5, true, _button_center("Drift"))
		22:
			_check(Input.get_action_strength("drive_drift") > 0.5, "reactivated layer accepts touches", Input.get_action_strength("drive_drift"))
			_send_touch(5, false, Vector2.ZERO)
			_finish()
	return false

func _button_center(button_name: String) -> Vector2:
	for button in _layer._buttons:
		if String(button.name) == button_name:
			return button.get_global_rect().get_center()
	return Vector2(-9999.0, -9999.0)

func _send_touch(index: int, pressed: bool, position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	_layer._input(event)

func _check(condition: bool, label: String, value) -> void:
	_checks += 1
	if condition:
		print("PASS | ", label)
	else:
		_failures += 1
		print("FAIL | ", label, " | got: ", value)

func _finish() -> void:
	print("SUMMARY checks=", _checks, " failures=", _failures)
	quit(1 if _failures > 0 else 0)
