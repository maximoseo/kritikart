extends RefCounted
class_name DailyChallenge
## Deterministic UTC-day challenge seed for KritiKart (offline-first).

const TRACK_OPTIONS: Array[StringName] = [&"storm_coast", &"showcase_circuit"]
const DIFFICULTIES: Array[String] = ["easy", "medium", "hard"]
const MODIFIERS: Array[String] = ["clean_racing", "wet_grip", "hard_ai"]


static func utc_day_key(unix_time: int = -1) -> String:
	var t: int = unix_time if unix_time >= 0 else int(Time.get_unix_time_from_system())
	var dict: Dictionary = Time.get_datetime_dict_from_unix_time(t)
	return "%04d-%02d-%02d" % [int(dict.get("year", 1970)), int(dict.get("month", 1)), int(dict.get("day", 1))]


static func challenge_seed(day_key: String = "") -> int:
	var key: String = day_key if not day_key.is_empty() else utc_day_key()
	return int(hash(key + "|kritikart-daily-v1") & 0x7fffffff)


static func challenge_for_day(day_key: String = "") -> Dictionary:
	var key: String = day_key if not day_key.is_empty() else utc_day_key()
	var seed_value: int = challenge_seed(key)
	var track_id: StringName = TRACK_OPTIONS[seed_value % TRACK_OPTIONS.size()]
	var difficulty: String = DIFFICULTIES[(seed_value / 7) % DIFFICULTIES.size()]
	var modifier: String = MODIFIERS[(seed_value / 13) % MODIFIERS.size()]
	return {
		"day_key": key,
		"seed": seed_value,
		"track_id": track_id,
		"difficulty": difficulty,
		"modifier": modifier,
		"title": "Daily · %s" % key,
		"blurb": "Beat today's seeded run (%s · %s)." % [String(track_id).replace("_", " ").capitalize(), difficulty.capitalize()],
	}
