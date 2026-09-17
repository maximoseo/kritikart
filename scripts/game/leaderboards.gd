extends Node
## KritiKart cloud leaderboards (Supabase) — offline-first, fire-and-forget.
##
## Wires itself to any RaceManager that enters the scene tree and submits the
## player's result when a race finishes. All network work is non-blocking and
## silently skipped when offline or unconfigured.

const DEFAULT_URL: String = "https://jdpxvwihlmpmmmiihvws.supabase.co"
const DEFAULT_ANON_KEY: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpkcHh2d2lobG1wbW1taWlodndzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY5ODEyNDgsImV4cCI6MjEwMjU1NzI0OH0.WuUJ9O8ahi8fo74Lu3VF8sXY4NJKIg5vd4APCZcgNwA"
const TABLE: String = "kritikart_leaderboard"

var _base_url: String
var _anon_key: String
var _enabled: bool = true


func _ready() -> void:
	_base_url = OS.get_environment("KRITIKART_SUPABASE_URL")
	if _base_url.is_empty():
		_base_url = DEFAULT_URL
	_anon_key = OS.get_environment("KRITIKART_SUPABASE_ANON_KEY")
	if _anon_key.is_empty():
		_anon_key = DEFAULT_ANON_KEY
	# headless/CI: skip networking entirely
	if DisplayServer.get_name() == "headless" or OS.has_feature("editor"):
		if OS.get_environment("KRITIKART_ALLOW_EDITOR_SUBMIT") != "1":
			_enabled = false
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is RaceManager and not node.race_finished.is_connected(_on_race_finished):
		node.race_finished.connect(_on_race_finished.bind(node))


func _on_race_finished(results: Array, source: RaceManager) -> void:
	if not _enabled:
		return
	for entry in results:
		if entry.get("is_player") if entry is Dictionary else entry.is_player:
			var total_ms: int = int(entry.get("total_time_msec") if entry is Dictionary else entry.total_time_msec)
			if total_ms <= 0:
				return
			var meta: Dictionary = (entry.get("metadata") if entry is Dictionary else entry.metadata) as Dictionary
			submit_score(
				str((entry.get("display_name") if entry is Dictionary else entry.display_name)).substr(0, 24),
				str(meta.get("track", "storm_coast")),
				str(meta.get("difficulty", "medium")),
				int(meta.get("best_lap_ms", 0)) if meta.get("best_lap_ms", 0) > 0 else -1,
				total_ms
			)
			return


## Submit a score. Fire-and-forget; failures are logged only in verbose builds.
func submit_score(player_name: String, track: String, difficulty: String, best_lap_ms: int, total_time_ms: int) -> void:
	if not _enabled or player_name.is_empty():
		player_name = "Player"
	var body := {
		"player_name": player_name.substr(0, 24),
		"track": track,
		"difficulty": difficulty,
		"total_time_ms": total_time_ms,
	}
	if best_lap_ms > 0:
		body["best_lap_ms"] = best_lap_ms
	_http("POST", "/rest/v1/%s" % TABLE, JSON.stringify(body), func(_response: PackedByteArray, _code: int) -> void: pass)


## Fetch top entries. `on_done(code, text)` is called on the main thread.
func fetch_top(track: String, difficulty: String, limit: int, on_done: Callable) -> void:
	var path := "/rest/v1/%s?select=player_name,total_time_ms,best_lap_ms&track=eq.%s&difficulty=eq.%s&order=total_time_ms.asc&limit=%d" % [
		TABLE, track.uri_encode(), difficulty.uri_encode(), clampi(limit, 1, 50)
	]
	_http("GET", path, "", func(response: PackedByteArray, code: int) -> void:
		on_done.call(code, response.get_string_from_utf8())
	)


func _http(method: String, path: String, body: String, on_done: Callable) -> void:
	if not _enabled:
		on_done.call(PackedByteArray(), 0)
		return
	var http := HTTPRequest.new()
	http.use_threads = true
	http.timeout = 8.0
	add_child(http)
	http.request_completed.connect(func(_r: int, code: int, _h: PackedStringArray, body_bytes: PackedByteArray) -> void:
		on_done.call(body_bytes, code)
		http.queue_free()
	, CONNECT_ONE_SHOT)
	var headers := PackedStringArray([
		"apikey: %s" % _anon_key,
		"Authorization: Bearer %s" % _anon_key,
		"Content-Type: application/json",
	])
	if body.is_empty():
		http.request(_base_url + path, headers, HTTPClient.METHOD_GET if method == "GET" else HTTPClient.METHOD_POST)
	else:
		http.request(_base_url + path, headers, HTTPClient.METHOD_POST, body)
