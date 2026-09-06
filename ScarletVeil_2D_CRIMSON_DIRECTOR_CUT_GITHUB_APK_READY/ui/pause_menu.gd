extends CanvasLayer
signal return_to_title
signal save_requested

var panel: PanelContainer
var memory_box: VBoxContainer
var settings_box: VBoxContainer
var memory_scroll: ScrollContainer
var settings_scroll: ScrollContainer
var content: VBoxContainer

func _ready() -> void:
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false

func _style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.012, 0.004, 0.009, 0.97)
	s.border_color = Color("831229")
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	return s

func _btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 48)
	b.add_theme_font_size_override("font_size", 16)
	return b

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -390
	panel.offset_right = 390
	panel.offset_top = -290
	panel.offset_bottom = 290
	panel.add_theme_stylebox_override("panel", _style())
	add_child(panel)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	var title := Label.new()
	title.text = "SCARLET VEIL — PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	content.add_child(title)

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(tabs)
	var resume := _btn("RESUME")
	resume.custom_minimum_size = Vector2(160, 42)
	resume.pressed.connect(toggle)
	tabs.add_child(resume)
	var mem := _btn("MEMORIES")
	mem.custom_minimum_size = Vector2(160, 42)
	mem.pressed.connect(_show_memories)
	tabs.add_child(mem)
	var set_btn := _btn("SETTINGS")
	set_btn.custom_minimum_size = Vector2(160, 42)
	set_btn.pressed.connect(_show_settings)
	tabs.add_child(set_btn)
	var save := _btn("SAVE")
	save.custom_minimum_size = Vector2(140, 42)
	save.pressed.connect(_on_save)
	tabs.add_child(save)

	memory_scroll = ScrollContainer.new()
	memory_scroll.custom_minimum_size = Vector2(730, 360)
	memory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(memory_scroll)
	memory_box = VBoxContainer.new()
	memory_box.custom_minimum_size = Vector2(700, 0)
	memory_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	memory_scroll.add_child(memory_box)
	settings_scroll = ScrollContainer.new()
	settings_scroll.custom_minimum_size = Vector2(730, 360)
	settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(settings_scroll)
	settings_box = VBoxContainer.new()
	settings_box.custom_minimum_size = Vector2(700, 0)
	settings_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scroll.add_child(settings_box)

	var exit := _btn("RETURN TO TITLE")
	exit.pressed.connect(_on_exit)
	content.add_child(exit)
	_show_memories()

func _on_save() -> void:
	save_requested.emit()
	AudioManager.play_sfx("res://assets/audio/ui_click.wav")

func _on_exit() -> void:
	get_tree().paused = false
	return_to_title.emit()

func toggle() -> void:
	visible = not visible
	get_tree().paused = visible

func _clear(box: VBoxContainer) -> void:
	for c in box.get_children():
		c.queue_free()

func _show_memories() -> void:
	memory_scroll.visible = true
	settings_scroll.visible = false
	_clear(memory_box)
	var catalog: Dictionary = {}
	var file := FileAccess.open("res://data/memories.json", FileAccess.READ)
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			catalog = parsed
	var found: Array = SaveManager.data.get("memory_shards", [])
	var head := Label.new()
	head.text = "RECOVERED MEMORY SHARDS  %d / 12" % found.size()
	head.add_theme_font_size_override("font_size", 18)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memory_box.add_child(head)
	for id in found:
		if catalog.has(id):
			var l := Label.new()
			l.text = "◆ %s — %s" % [catalog[id]["title"], catalog[id]["text"]]
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.add_theme_font_size_override("font_size", 14)
			l.add_theme_color_override("font_color", Color(0.85, 0.76, 0.75, 0.92))
			memory_box.add_child(l)
	if found.is_empty():
		var empty := Label.new()
		empty.text = "No memories recovered yet."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		memory_box.add_child(empty)

func _show_settings() -> void:
	memory_scroll.visible = false
	settings_scroll.visible = true
	_clear(settings_box)
	_add_setting_toggle("Music", "music")
	_add_setting_toggle("Sound Effects", "sfx")
	_add_setting_toggle("Voice Lines", "voice")
	var label := Label.new()
	label.text = "Touch Opacity"
	settings_box.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.35
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(SaveManager.data["settings"]["touch_opacity"])
	slider.value_changed.connect(_on_touch_opacity_changed)
	settings_box.add_child(slider)

func _add_setting_toggle(label_text: String, key: String) -> void:
	var c := CheckButton.new()
	c.text = label_text
	c.button_pressed = bool(SaveManager.data["settings"][key])
	c.toggled.connect(_on_setting_toggled_bound.bind(key))
	settings_box.add_child(c)

func _on_setting_toggled_bound(value: bool, key: String) -> void:
	SaveManager.set_setting(key, value)
	AudioManager.apply_settings()

func _on_touch_opacity_changed(value: float) -> void:
	SaveManager.set_setting("touch_opacity", value)
