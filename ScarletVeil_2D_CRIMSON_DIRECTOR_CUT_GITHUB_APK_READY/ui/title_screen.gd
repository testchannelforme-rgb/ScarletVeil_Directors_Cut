extends Control

signal new_game_requested
signal continue_requested

var settings_panel: PanelContainer
var music_check: CheckButton
var sfx_check: CheckButton
var voice_check: CheckButton
var opacity_slider: HSlider
var menu_box: VBoxContainer
var menu_back: PanelContainer
var begin_button: Button
var begun := false
var begin_prompt: Label
var ember_layer: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()

func _panel_style(color: Color, border := Color(0.42, 0.04, 0.08, 0.95)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = border
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	return s

func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(330, 54)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color("e9dfd9"))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _panel_style(Color(0.04,0.018,0.028,0.88)))
	b.add_theme_stylebox_override("hover", _panel_style(Color(0.18,0.025,0.045,0.94), Color("b3132c")))
	b.add_theme_stylebox_override("pressed", _panel_style(Color(0.32,0.025,0.05,0.98), Color("e32643")))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/title_bg.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.002, 0.008, 0.38)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var vignette := ColorRect.new()
	vignette.color = Color(0.0,0.0,0.0,0.22)
	vignette.anchor_left = 0.0
	vignette.anchor_top = 0.72
	vignette.anchor_right = 1.0
	vignette.anchor_bottom = 1.0
	vignette.offset_left = 0
	vignette.offset_top = 0
	vignette.offset_right = 0
	vignette.offset_bottom = 0
	add_child(vignette)

	var subtitle := Label.new()
	subtitle.text = "A 2D DARK-FANTASY METROIDVANIA"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.88,0.75,0.72,0.85))
	subtitle.visible = false
	subtitle.anchor_left = 0.5
	subtitle.anchor_right = 0.5
	subtitle.anchor_top = 0.50
	subtitle.offset_left = -330
	subtitle.offset_right = 330
	subtitle.offset_bottom = 28
	add_child(subtitle)

	menu_back = PanelContainer.new()
	menu_back.anchor_left = 0.5
	menu_back.anchor_right = 0.5
	menu_back.anchor_top = 0.57
	menu_back.anchor_bottom = 0.57
	menu_back.offset_left = -205
	menu_back.offset_right = 205
	menu_back.offset_top = -12
	menu_back.offset_bottom = 230
	menu_back.add_theme_stylebox_override("panel", _panel_style(Color(0.012,0.004,0.010,0.84), Color(0.46,0.04,0.10,0.72)))
	menu_back.visible = false
	add_child(menu_back)

	menu_box = VBoxContainer.new()
	menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_box.add_theme_constant_override("separation", 10)
	menu_back.add_child(menu_box)

	var new_btn := _button("NEW JOURNEY")
	new_btn.pressed.connect(_on_new_pressed)
	menu_box.add_child(new_btn)
	var continue_btn := _button("CONTINUE")
	continue_btn.disabled = not SaveManager.has_save()
	continue_btn.pressed.connect(_on_continue_pressed)
	menu_box.add_child(continue_btn)
	var settings_btn := _button("SETTINGS")
	settings_btn.pressed.connect(_toggle_settings)
	menu_box.add_child(settings_btn)

	var hint := Label.new()
	hint.text = "Move: A/D or touch • Attack: J • Dash: K • Threadblade: L • Parry: Q"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.anchor_left = 0.0
	hint.anchor_right = 1.0
	hint.anchor_top = 0.94
	hint.anchor_bottom = 0.98
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.82,0.72,0.72,0.65))
	add_child(hint)

	ember_layer = Control.new()
	ember_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ember_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ember_layer)
	for i in range(16):
		var ember := Label.new()
		ember.text = "✦"
		ember.position = Vector2(70 + (i*211)%1160, 90 + (i*83)%520)
		ember.add_theme_font_size_override("font_size", 7 + i%3*2)
		ember.add_theme_color_override("font_color", Color(0.85,0.025,0.09,0.16+i%4*0.035))
		ember_layer.add_child(ember)

	begin_prompt = Label.new()
	begin_prompt.text = "PRESS / TAP TO BEGIN"
	begin_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	begin_prompt.anchor_left = 0.32
	begin_prompt.anchor_right = 0.68
	begin_prompt.anchor_top = 0.82
	begin_prompt.anchor_bottom = 0.88
	begin_prompt.add_theme_font_size_override("font_size", 17)
	begin_prompt.add_theme_color_override("font_color", Color(0.96,0.86,0.82,0.92))
	add_child(begin_prompt)
	var prompt_tween := create_tween().set_loops()
	prompt_tween.tween_property(begin_prompt, "modulate:a", 0.35, 0.9)
	prompt_tween.tween_property(begin_prompt, "modulate:a", 1.0, 0.9)

	begin_button = Button.new()
	begin_button.flat = true
	begin_button.text = ""
	begin_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	begin_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	begin_button.pressed.connect(_reveal_menu.bind(subtitle))
	add_child(begin_button)

	_build_settings()

	modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 1.0, 0.7)

func _unhandled_input(event: InputEvent) -> void:
	if begun:
		return
	if (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed():
		_reveal_menu(null)

func _reveal_menu(subtitle_node = null) -> void:
	if begun:
		return
	begun = true
	AudioManager.play_sfx("res://assets/audio/ui_click.wav", -8.0, 0.9)
	if is_instance_valid(begin_button):
		begin_button.queue_free()
	if is_instance_valid(begin_prompt):
		begin_prompt.visible = false
	menu_back.visible = true
	menu_back.modulate.a = 0.0
	var subtitle := subtitle_node
	if subtitle == null:
		for child in get_children():
			if child is Label and child.text == "A 2D DARK-FANTASY METROIDVANIA":
				subtitle = child
				break
	if is_instance_valid(subtitle):
		subtitle.visible = true
		subtitle.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(menu_back, "modulate:a", 1.0, 0.35)
	if is_instance_valid(subtitle):
		tween.parallel().tween_property(subtitle, "modulate:a", 1.0, 0.35)

func _build_settings() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018,0.008,0.014,0.97), Color("8d1327")))
	settings_panel.anchor_left = 0.5
	settings_panel.anchor_top = 0.5
	settings_panel.anchor_right = 0.5
	settings_panel.anchor_bottom = 0.5
	settings_panel.offset_left = -240
	settings_panel.offset_top = -205
	settings_panel.offset_right = 240
	settings_panel.offset_bottom = 205
	settings_panel.visible = false
	add_child(settings_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	settings_panel.add_child(box)
	var title := Label.new()
	title.text = "HEARTGLASS SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f1e5df"))
	box.add_child(title)
	music_check = CheckButton.new()
	music_check.text = "Music"
	music_check.button_pressed = bool(SaveManager.data["settings"]["music"])
	box.add_child(music_check)
	sfx_check = CheckButton.new()
	sfx_check.text = "Sound Effects"
	sfx_check.button_pressed = bool(SaveManager.data["settings"]["sfx"])
	box.add_child(sfx_check)
	voice_check = CheckButton.new()
	voice_check.text = "Voice Lines"
	voice_check.button_pressed = bool(SaveManager.data["settings"]["voice"])
	box.add_child(voice_check)
	var op_label := Label.new()
	op_label.text = "Touch Control Opacity"
	box.add_child(op_label)
	opacity_slider = HSlider.new()
	opacity_slider.min_value = 0.35
	opacity_slider.max_value = 1.0
	opacity_slider.step = 0.05
	opacity_slider.value = float(SaveManager.data["settings"]["touch_opacity"])
	box.add_child(opacity_slider)
	var close := _button("APPLY & CLOSE")
	close.custom_minimum_size = Vector2(330, 48)
	close.pressed.connect(_apply_settings)
	box.add_child(close)

func _toggle_settings() -> void:
	AudioManager.play_sfx("res://assets/audio/ui_click.wav")
	settings_panel.visible = not settings_panel.visible

func _apply_settings() -> void:
	SaveManager.set_setting("music", music_check.button_pressed)
	SaveManager.set_setting("sfx", sfx_check.button_pressed)
	SaveManager.set_setting("voice", voice_check.button_pressed)
	SaveManager.set_setting("touch_opacity", opacity_slider.value)
	AudioManager.apply_settings()
	if music_check.button_pressed:
		AudioManager.play_music("res://assets/audio/menu_theme.wav", -14.0)
	settings_panel.visible = false

func _on_new_pressed() -> void:
	AudioManager.play_sfx("res://assets/audio/ui_click.wav")
	new_game_requested.emit()

func _on_continue_pressed() -> void:
	AudioManager.play_sfx("res://assets/audio/ui_click.wav")
	continue_requested.emit()
