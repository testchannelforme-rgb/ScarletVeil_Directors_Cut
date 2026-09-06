extends Control

signal finished

var progress: ProgressBar
var percent: Label
var stage_label: Label
var quote_label: Label
var ring_root: Control
var inner_ring: Control
var outer_ring: Control
var pulse: ColorRect
var shard_root: Control
var shards: Array[Polygon2D] = []
var embers: Array[Label] = []
var elapsed := 0.0
var target_progress := 0.0
var shown_progress := 0.0
var finishing := false
var quote_index := 0
var quote_timer := 0.0

const QUOTES := [
	"WHAT CANNOT BE REMEMBERED CANNOT HURT YOU.",
	"THE HEARTWELL DOES NOT SPEAK. IT REMEMBERS.",
	"A MEMORY CAN LIE WITHOUT KNOWING IT IS LYING.",
	"EVERY MASK SAVES SOMETHING. EVERY MASK HIDES SOMETHING."
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	set_process(true)

func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/bg_far.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var dim := ColorRect.new()
	dim.color = Color(0.004, 0.001, 0.006, 0.76)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var title := Label.new()
	title.text = "SCARLET VEIL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.25
	title.anchor_right = 0.75
	title.anchor_top = 0.08
	title.anchor_bottom = 0.15
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.84, 0.88))
	add_child(title)

	# A procedural Heartwell sigil. No external shader: cheap enough for Android.
	ring_root = Control.new()
	ring_root.anchor_left = 0.5
	ring_root.anchor_right = 0.5
	ring_root.anchor_top = 0.43
	ring_root.anchor_bottom = 0.43
	ring_root.position = Vector2.ZERO
	add_child(ring_root)

	outer_ring = _make_ring(116.0, 2.0, Color(0.72, 0.025, 0.09, 0.42), 64)
	ring_root.add_child(outer_ring)
	inner_ring = _make_ring(78.0, 1.5, Color(0.92, 0.08, 0.16, 0.48), 48)
	ring_root.add_child(inner_ring)

	var core := ColorRect.new()
	core.color = Color(0.74, 0.0, 0.055, 0.22)
	core.position = Vector2(-5, -92)
	core.size = Vector2(10, 184)
	ring_root.add_child(core)
	pulse = core

	shard_root = Control.new()
	ring_root.add_child(shard_root)
	for i in range(12):
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([Vector2(0,-13),Vector2(5,0),Vector2(0,13),Vector2(-5,0)])
		shard.color = Color(0.93, 0.08, 0.15, 0.46 if i % 2 == 0 else 0.28)
		var a := TAU * float(i) / 12.0
		shard.position = Vector2(cos(a), sin(a)) * 145.0
		shard.rotation = a
		shard_root.add_child(shard)
		shards.append(shard)

	quote_label = Label.new()
	quote_label.text = QUOTES[0]
	quote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote_label.anchor_left = 0.12
	quote_label.anchor_right = 0.88
	quote_label.anchor_top = 0.67
	quote_label.anchor_bottom = 0.73
	quote_label.add_theme_font_size_override("font_size", 16)
	quote_label.add_theme_color_override("font_color", Color(0.91, 0.79, 0.77, 0.74))
	add_child(quote_label)

	stage_label = Label.new()
	stage_label.text = "LISTENING FOR A HEARTBEAT"
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.anchor_left = 0.18
	stage_label.anchor_right = 0.82
	stage_label.anchor_top = 0.76
	stage_label.anchor_bottom = 0.805
	stage_label.add_theme_font_size_override("font_size", 13)
	stage_label.add_theme_color_override("font_color", Color(0.92, 0.84, 0.82, 0.72))
	add_child(stage_label)

	progress = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = 100
	progress.value = 0
	progress.show_percentage = false
	progress.anchor_left = 0.22
	progress.anchor_right = 0.78
	progress.anchor_top = 0.835
	progress.anchor_bottom = 0.855
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08,0.025,0.04,0.88)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("b80d2e")
	fill.corner_radius_top_left = 8
	fill.corner_radius_top_right = 8
	fill.corner_radius_bottom_left = 8
	fill.corner_radius_bottom_right = 8
	progress.add_theme_stylebox_override("background", bg_style)
	progress.add_theme_stylebox_override("fill", fill)
	add_child(progress)

	percent = Label.new()
	percent.text = "AWAKENING 0%"
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percent.anchor_left = 0.3
	percent.anchor_right = 0.7
	percent.anchor_top = 0.87
	percent.anchor_bottom = 0.91
	percent.add_theme_font_size_override("font_size", 13)
	percent.add_theme_color_override("font_color", Color(0.93,0.82,0.81,0.72))
	add_child(percent)

	for i in range(22):
		var ember := Label.new()
		ember.text = "✦"
		ember.add_theme_font_size_override("font_size", 7 + (i % 4) * 2)
		ember.add_theme_color_override("font_color", Color(0.92,0.03,0.10,0.16 + (i % 5) * 0.035))
		ember.position = Vector2(45 + (i * 193) % 1190, 80 + (i * 79) % 540)
		embers.append(ember)
		add_child(ember)

func _make_ring(radius: float, width: float, color: Color, segments: int) -> Control:
	var holder := Control.new()
	for i in range(segments):
		if i % 3 == 1:
			continue
		var tick := ColorRect.new()
		var a := TAU * float(i) / float(segments)
		tick.color = color
		tick.size = Vector2(width, 8.0 if i % 6 == 0 else 4.0)
		tick.position = Vector2(cos(a), sin(a)) * radius - tick.size * 0.5
		tick.rotation = a + PI * 0.5
		holder.add_child(tick)
	return holder

func set_progress(value: float, stage := "") -> void:
	target_progress = clampf(value, 0.0, 1.0)
	if not stage.is_empty():
		stage_label.text = stage

func finish() -> void:
	if finishing:
		return
	finishing = true
	target_progress = 1.0
	var t := create_tween()
	t.tween_interval(0.12)
	t.tween_property(self, "modulate:a", 0.0, 0.32)
	await t.finished
	finished.emit()

func _process(delta: float) -> void:
	elapsed += delta
	quote_timer += delta
	shown_progress = move_toward(shown_progress, target_progress, delta * 0.75)
	progress.value = shown_progress * 100.0
	percent.text = "AWAKENING %d%%" % int(shown_progress * 100.0)

	outer_ring.rotation += delta * 0.18
	inner_ring.rotation -= delta * 0.29
	shard_root.rotation += delta * 0.09
	pulse.color.a = 0.18 + sin(elapsed * 3.2) * 0.09
	pulse.scale.x = 1.0 + sin(elapsed * 2.3) * 0.5
	for i in range(shards.size()):
		var shard := shards[i]
		shard.scale = Vector2.ONE * (0.82 + sin(elapsed * 2.2 + i * 0.6) * 0.12)
	for i in range(embers.size()):
		var e := embers[i]
		e.position.y -= delta * (7.0 + float(i % 4) * 3.0)
		e.position.x += sin(elapsed * 0.8 + i) * delta * 3.0
		if e.position.y < 35:
			e.position.y = 690

	if quote_timer > 2.4:
		quote_timer = 0.0
		quote_index = (quote_index + 1) % QUOTES.size()
		var tw := create_tween()
		tw.tween_property(quote_label, "modulate:a", 0.0, 0.2)
		tw.tween_callback(func(): quote_label.text = QUOTES[quote_index])
		tw.tween_property(quote_label, "modulate:a", 1.0, 0.28)
