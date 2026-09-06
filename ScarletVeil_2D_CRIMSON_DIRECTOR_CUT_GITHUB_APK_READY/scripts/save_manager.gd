extends Node

const SAVE_PATH := "user://scarlet_veil_save.json"
var data: Dictionary = {}

func _ready() -> void:
	load_game()

func default_data() -> Dictionary:
	return {
		"version": 3,
		"player_position": [180.0, 540.0],
		"checkpoint": [180.0, 540.0],
		"health": 6,
		"max_health": 6,
		"veilfire": 100.0,
		"abilities": {
			"wall_jump": false,
			"dash": false,
			"grapple": false,
			"down_strike": false,
			"veil_phase": false
		},
		"masks": ["veilbound"],
		"equipped_mask": "veilbound",
		"memory_shards": [],
		"bosses_defeated": {},
		"important_choices": {},
		"ending_flags": {},
		"tutorials_seen": [],
		"settings": {
			"music": true,
			"sfx": true,
			"voice": true,
			"touch_opacity": 0.78,
			"screen_shake": 1.0
		}
	}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func new_game() -> void:
	var settings := default_data()["settings"]
	if not data.is_empty() and data.get("settings") is Dictionary:
		settings = data["settings"].duplicate(true)
	data = default_data()
	data["settings"] = settings
	save_to_disk()

func load_game() -> void:
	data = default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_merge_defaults(parsed)

func _merge_defaults(loaded: Dictionary) -> void:
	var defaults := default_data()
	for key in defaults.keys():
		if not loaded.has(key):
			loaded[key] = defaults[key]
	for dict_key in ["abilities", "settings"]:
		if not (loaded.get(dict_key) is Dictionary):
			loaded[dict_key] = defaults[dict_key].duplicate(true)
		else:
			for key in defaults[dict_key].keys():
				if not loaded[dict_key].has(key):
					loaded[dict_key][key] = defaults[dict_key][key]
	data = loaded

func save_to_disk() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Scarlet Veil: save file could not be written.")
		return
	file.store_string(JSON.stringify(data, "\t"))

func reset_save() -> void:
	new_game()

func set_setting(key: String, value) -> void:
	if not (data.get("settings") is Dictionary):
		data["settings"] = default_data()["settings"]
	data["settings"][key] = value
	save_to_disk()
