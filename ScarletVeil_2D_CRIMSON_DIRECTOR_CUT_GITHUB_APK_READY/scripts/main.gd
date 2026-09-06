extends Node

const TITLE_SCENE := preload("res://ui/TitleScreen.tscn")
const LOADING_SCENE := preload("res://ui/LoadingScreen.tscn")
const WORLD_PATH := "res://world/World.tscn"

var title_screen
var loading_screen
var world

func _ready() -> void:
	_ensure_input_map()
	GameFX.reset_time_scale()
	show_title()

func _ensure_input_map() -> void:
	_add_action_keys("move_left", [KEY_A, KEY_LEFT])
	_add_action_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_action_keys("move_down", [KEY_S, KEY_DOWN])
	_add_action_keys("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_action_keys("attack", [KEY_J])
	_add_action_keys("dash", [KEY_K, KEY_SHIFT])
	_add_action_keys("grapple", [KEY_L])
	_add_action_keys("parry", [KEY_Q])
	_add_action_keys("interact", [KEY_E, KEY_ENTER])
	_add_action_keys("mask_cycle", [KEY_R])
	_add_action_keys("pause", [KEY_ESCAPE, KEY_P])
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_button("jump", JOY_BUTTON_A)
	_add_joy_button("attack", JOY_BUTTON_X)
	_add_joy_button("dash", JOY_BUTTON_B)
	_add_joy_button("grapple", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_button("parry", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_button("mask_cycle", JOY_BUTTON_Y)
	_add_joy_button("pause", JOY_BUTTON_START)

func _add_action_keys(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for code in keys:
		var e := InputEventKey.new()
		e.keycode = code
		InputMap.action_add_event(action, e)

func _add_joy_button(action: StringName, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var e := InputEventJoypadButton.new()
	e.button_index = button
	InputMap.action_add_event(action, e)

func _add_joy_axis(action: StringName, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	InputMap.action_add_event(action, e)

func show_title() -> void:
	GameFX.reset_time_scale()
	get_tree().paused = false
	if is_instance_valid(world):
		world.queue_free()
	world = null
	if is_instance_valid(loading_screen):
		loading_screen.queue_free()
	if is_instance_valid(title_screen):
		title_screen.queue_free()
	title_screen = TITLE_SCENE.instantiate()
	add_child(title_screen)
	title_screen.new_game_requested.connect(_on_new_game)
	title_screen.continue_requested.connect(_on_continue)
	AudioManager.stop_ambience()
	AudioManager.play_music("res://assets/audio/menu_theme.wav", -14.0)

func _on_new_game() -> void:
	SaveManager.new_game()
	_start_game(true)

func _on_continue() -> void:
	SaveManager.load_game()
	_start_game(false)

func _start_game(play_intro: bool) -> void:
	if is_instance_valid(title_screen):
		title_screen.queue_free()
		title_screen = null
	loading_screen = LOADING_SCENE.instantiate()
	add_child(loading_screen)
	AudioManager.stop_music(0.2)

	var request_error := ResourceLoader.load_threaded_request(WORLD_PATH, "PackedScene")
	if request_error != OK:
		push_error("Scarlet Veil: failed to request World.tscn for threaded loading.")
		loading_screen.set_progress(1.0, "THE VEIL REFUSES TO OPEN")
		await get_tree().create_timer(0.8).timeout
		loading_screen.finish()
		await loading_screen.finished
		return

	var progress := []
	var minimum_show_time := 1.75
	var shown := 0.0
	while true:
		var status := ResourceLoader.load_threaded_get_status(WORLD_PATH, progress)
		var p := 0.0
		if not progress.is_empty():
			p = clampf(float(progress[0]), 0.0, 1.0)
		loading_screen.set_progress(p, _loading_stage(p))
		await get_tree().process_frame
		shown += get_process_delta_time()
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Scarlet Veil: World.tscn threaded load failed.")
			loading_screen.set_progress(1.0, "MEMORY FRACTURED")
			break
		if status == ResourceLoader.THREAD_LOAD_LOADED and shown >= minimum_show_time:
			break

	loading_screen.set_progress(1.0, "THE HEARTWELL REMEMBERS")
	await get_tree().create_timer(0.18).timeout
	loading_screen.finish()
	await loading_screen.finished
	loading_screen.queue_free()
	loading_screen = null

	if play_intro:
		await _play_intro()

	var packed = ResourceLoader.load_threaded_get(WORLD_PATH)
	if not (packed is PackedScene):
		push_error("Scarlet Veil: World.tscn did not resolve to PackedScene.")
		show_title()
		return
	world = packed.instantiate()
	add_child(world)
	world.return_to_title.connect(show_title)

func _loading_stage(p: float) -> String:
	if p < 0.18:
		return "LISTENING FOR A HEARTBEAT"
	if p < 0.42:
		return "REASSEMBLING THE SANCTUARY"
	if p < 0.68:
		return "THREADING LOST MEMORIES"
	if p < 0.9:
		return "WAKING WHAT SHOULD SLEEP"
	return "THE VEIL IS THINNING"

func _play_intro() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 500
	add_child(layer)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(black)
	var glow := ColorRect.new()
	glow.color = Color(0.84, 0.0, 0.055, 0.0)
	glow.anchor_left = 0.5
	glow.anchor_top = 0.5
	glow.anchor_right = 0.5
	glow.anchor_bottom = 0.5
	glow.offset_left = -4.0
	glow.offset_right = 4.0
	glow.offset_top = -310.0
	glow.offset_bottom = 310.0
	layer.add_child(glow)
	AudioManager.play_sfx("res://assets/audio/heartbeat.wav", -2.0)
	await get_tree().create_timer(0.35).timeout
	var t := create_tween()
	t.tween_property(glow, "color:a", 0.82, 0.16)
	t.tween_property(glow, "scale:x", 10.0, 0.3)
	t.tween_property(glow, "color:a", 0.0, 0.24)
	await t.finished
	var quote := Label.new()
	quote.text = "IF YOU WAKE, DO NOT REMEMBER."
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quote.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	quote.add_theme_font_size_override("font_size", 25)
	quote.add_theme_color_override("font_color", Color("e6ddd8"))
	quote.modulate.a = 0.0
	layer.add_child(quote)
	AudioManager.play_voice("res://assets/audio/voice_intro.wav")
	var q := create_tween()
	q.tween_property(quote, "modulate:a", 1.0, 0.55)
	q.tween_interval(1.45)
	q.tween_property(quote, "modulate:a", 0.0, 0.45)
	await q.finished
	layer.queue_free()
