extends Node
## KritiKart in-app update check (Android direct builds only).
##
## On the main menu, fetches a small JSON manifest from the download host,
## and when a newer build exists offers: Download (verifies sha256 + size)
## then Install (hands the APK to Android's installer, which validates the
## package signature and asks the player to confirm). Offline-first: every
## failure is silent and never blocks the game. Enabled only for exports
## carrying the `apk_updates` feature (the direct Android preset), mirroring
## the Zip Rush pattern scaled to KritiKart's host and semver scheme.

signal update_available(version: String)
signal update_ready(version: String)
signal update_failed

const MANIFEST_URL: String = "https://github.com/maximoseo/kritikart/releases/latest/download/version.json"
const APK_URL_ROOT: String = "https://github.com/maximoseo/kritikart/releases/latest/download/"
const APK_FILE: String = "user://kritikart-update.apk"
const MAX_APK_BYTES: int = 256 * 1024 * 1024
const CHECK_DELAY_S: float = 2.0

var _offered_version: String = ""
var _offered_file: String = ""
var _expected_sha256: String = ""
var _expected_size: int = 0
var _request: HTTPRequest = null
var _dialog_layer: CanvasLayer = null
var _prompt_dialog: ConfirmationDialog = null
var _ready_dialog: ConfirmationDialog = null
var _checked: bool = false


func enabled() -> bool:
	return OS.has_feature("android") and OS.has_feature("apk_updates")


func current_version() -> String:
	return String(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func _ready() -> void:
	if not enabled():
		return
	if DisplayServer.get_name() == "headless" or OS.has_feature("editor"):
		return
	if FileAccess.file_exists(APK_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(APK_FILE))
	await get_tree().create_timer(CHECK_DELAY_S).timeout
	check_for_update()


func check_for_update() -> void:
	if not enabled() or _checked or _request != null:
		return
	_checked = true
	var req := _new_request(15.0, 16384)
	req.request_completed.connect(_on_manifest_received.bind(req), CONNECT_ONE_SHOT)
	if req.request(MANIFEST_URL) != OK:
		_finish_request(req)
		update_failed.emit()


static func compare_versions(a: String, b: String) -> int:
	var pa := _version_parts(a)
	var pb := _version_parts(b)
	for i in 3:
		if pa[i] != pb[i]:
			return signi(pa[i] - pb[i])
	return 0


static func _version_parts(v: String) -> Array[int]:
	var out: Array[int] = [0, 0, 0]
	var parts := v.strip_edges().trim_prefix("v").split(".")
	for i in mini(parts.size(), 3):
		out[i] = parts[i].to_int() if parts[i].is_valid_int() else 0
	return out


func _on_manifest_received(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, req: HTTPRequest) -> void:
	if not _finish_request(req):
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		update_failed.emit()
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		update_failed.emit()
		return
	var info: Dictionary = parsed
	var version := String(info.get("version", ""))
	var file := String(info.get("apk", ""))
	var sha := String(info.get("sha256", "")).to_lower()
	var size_value: Variant = info.get("size", 0)
	if version.is_empty() or file.is_empty() or "/" in file or sha.length() != 64 or not sha.is_valid_hex_number(false):
		update_failed.emit()
		return
	if not size_value is int and not size_value is float:
		update_failed.emit()
		return
	var size_bytes := int(size_value)
	if size_bytes < 1 or size_bytes > MAX_APK_BYTES:
		update_failed.emit()
		return
	if compare_versions(version, current_version()) <= 0:
		return
	_offered_version = version
	_offered_file = file
	_expected_sha256 = sha
	_expected_size = size_bytes
	update_available.emit(version)
	_show_update_prompt()


func download_update() -> void:
	if _offered_file.is_empty() or _request != null:
		return
	var req := _new_request(240.0, _expected_size)
	req.accept_gzip = false
	req.download_file = APK_FILE
	req.request_completed.connect(_on_apk_received.bind(req), CONNECT_ONE_SHOT)
	if req.request(APK_URL_ROOT + _offered_file) != OK:
		_finish_request(req)
		update_failed.emit()


func _on_apk_received(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray, req: HTTPRequest) -> void:
	if not _finish_request(req):
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not _verified_download():
		_discard_download()
		update_failed.emit()
		return
	update_ready.emit(_offered_version)
	_show_install_prompt()


func _verified_download() -> bool:
	var file := FileAccess.open(APK_FILE, FileAccess.READ)
	if file == null:
		return false
	var length := file.get_length()
	file.close()
	if length != _expected_size:
		return false
	return FileAccess.get_sha256(APK_FILE) == _expected_sha256


func install_update() -> void:
	if not FileAccess.file_exists(APK_FILE):
		update_failed.emit()
		return
	# Android validates the package signature and obtains the player's
	# install confirmation; REQUEST_INSTALL_PACKAGES comes from the preset.
	OS.shell_open(ProjectSettings.globalize_path(APK_FILE))


func _discard_download() -> void:
	if FileAccess.file_exists(APK_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(APK_FILE))


func _ensure_dialogs() -> void:
	if _dialog_layer != null:
		return
	_dialog_layer = CanvasLayer.new()
	_dialog_layer.layer = 100
	add_child(_dialog_layer)

	_prompt_dialog = ConfirmationDialog.new()
	_prompt_dialog.title = "Update available"
	_prompt_dialog.ok_button_text = "Download"
	_prompt_dialog.cancel_button_text = "Later"
	_prompt_dialog.confirmed.connect(download_update)
	_dialog_layer.add_child(_prompt_dialog)

	_ready_dialog = ConfirmationDialog.new()
	_ready_dialog.title = "Update ready"
	_ready_dialog.ok_button_text = "Install"
	_ready_dialog.cancel_button_text = "Later"
	_ready_dialog.confirmed.connect(install_update)
	_dialog_layer.add_child(_ready_dialog)


func _show_update_prompt() -> void:
	_ensure_dialogs()
	_prompt_dialog.dialog_text = "KritiKart v%s is available (you have v%s).\nDownload it now?" % [_offered_version, current_version()]
	_prompt_dialog.popup_centered()


func _show_install_prompt() -> void:
	_ensure_dialogs()
	_ready_dialog.dialog_text = "KritiKart v%s is downloaded and verified.\nInstall it now?" % _offered_version
	_ready_dialog.popup_centered()


func _new_request(timeout_s: float, body_limit: int) -> HTTPRequest:
	var req := HTTPRequest.new()
	req.max_redirects = 3
	req.body_size_limit = body_limit
	req.timeout = timeout_s
	add_child(req)
	_request = req
	return req


func _finish_request(req: HTTPRequest) -> bool:
	if req != _request:
		return false
	_request = null
	req.queue_free()
	return true
