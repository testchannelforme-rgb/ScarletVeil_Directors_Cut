extends CanvasLayer

signal ending_chosen(id: String)
signal memory_choice_chosen(id: String)

var player
var hp_fill: ColorRect
var veil_fill: ColorRect
var flow_fill: ColorRect
var hp_text: Label
var veil_text: Label
var flow_text: Label
var mask_icon: TextureRect
var mask_text: Label
var memory_text: Label
var objective: Label
var region_label: Label
var overlay_panel: PanelContainer
var overlay_title: Label
var overlay_body: Label
var dialogue_panel: PanelContainer
var dialogue_text: Label
var boss_panel: Control
var boss_fill: ColorRect
var boss_label: Label
var flash: ColorRect
var ending_panel: PanelContainer
var ending_secret_button: Button
var memory_choice_panel: PanelContainer

func _ready() -> void:
	layer=80
	_build()

func _style(bg: Color, border:=Color(0.45,0.04,0.09,0.9), radius:=7) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=bg
	s.border_color=border
	s.border_width_left=1
	s.border_width_top=1
	s.border_width_right=1
	s.border_width_bottom=1
	s.corner_radius_top_left=radius
	s.corner_radius_top_right=radius
	s.corner_radius_bottom_left=radius
	s.corner_radius_bottom_right=radius
	return s

func _make_bar(parent: Control, y: float, color: Color, width:=330.0) -> ColorRect:
	var bg:=ColorRect.new()
	bg.color=Color(0.08,0.03,0.05,0.92)
	bg.position=Vector2(28,y)
	bg.size=Vector2(width,14)
	parent.add_child(bg)
	var fill:=ColorRect.new()
	fill.color=color
	fill.position=Vector2(2,2)
	fill.size=Vector2(width-4,10)
	bg.add_child(fill)
	return fill

func _build() -> void:
	var root:=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var stats:=Panel.new()
	stats.position=Vector2(18,18)
	stats.size=Vector2(390,182)
	stats.add_theme_stylebox_override("panel",_style(Color(0.01,0.005,0.01,0.68),Color(0.35,0.04,0.08,0.55)))
	root.add_child(stats)
	hp_text=Label.new()
	hp_text.position=Vector2(28,15)
	hp_text.add_theme_font_size_override("font_size",17)
	hp_text.add_theme_color_override("font_color",Color("f2e6df"))
	stats.add_child(hp_text)
	hp_fill=_make_bar(stats,45,Color("b90d2a"))
	veil_text=Label.new()
	veil_text.position=Vector2(28,68)
	veil_text.add_theme_font_size_override("font_size",13)
	veil_text.add_theme_color_override("font_color",Color("dfc9dc"))
	stats.add_child(veil_text)
	veil_fill=_make_bar(stats,91,Color("8c0b63"))
	flow_text=Label.new()
	flow_text.position=Vector2(28,112)
	flow_text.add_theme_font_size_override("font_size",12)
	flow_text.add_theme_color_override("font_color",Color("e9b8bd"))
	stats.add_child(flow_text)
	flow_fill=_make_bar(stats,132,Color("d91a35"))
	mask_icon=TextureRect.new()
	mask_icon.position=Vector2(28,151)
	mask_icon.size=Vector2(28,28)
	mask_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	mask_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stats.add_child(mask_icon)
	mask_text=Label.new()
	mask_text.position=Vector2(64,155)
	mask_text.add_theme_font_size_override("font_size",13)
	stats.add_child(mask_text)
	memory_text=Label.new()
	memory_text.position=Vector2(240,155)
	memory_text.add_theme_font_size_override("font_size",13)
	memory_text.add_theme_color_override("font_color",Color("d6b7bd"))
	stats.add_child(memory_text)
	objective=Label.new()
	objective.text="OBJECTIVE — FIND A WAY OUT"
	objective.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	objective.anchor_left=.3
	objective.anchor_right=.7
	objective.offset_top=25
	objective.offset_bottom=58
	objective.add_theme_font_size_override("font_size",16)
	objective.add_theme_color_override("font_color",Color(0.95,0.89,0.86,0.9))
	root.add_child(objective)
	region_label=Label.new()
	region_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	region_label.anchor_left=.25
	region_label.anchor_right=.75
	region_label.anchor_top=.18
	region_label.anchor_bottom=.26
	region_label.add_theme_font_size_override("font_size",29)
	region_label.add_theme_color_override("font_color",Color("eadbd5"))
	region_label.modulate.a=0
	root.add_child(region_label)

	overlay_panel=PanelContainer.new()
	overlay_panel.anchor_left=.5
	overlay_panel.anchor_right=.5
	overlay_panel.anchor_top=.5
	overlay_panel.anchor_bottom=.5
	overlay_panel.offset_left=-360
	overlay_panel.offset_right=360
	overlay_panel.offset_top=-120
	overlay_panel.offset_bottom=120
	overlay_panel.add_theme_stylebox_override("panel",_style(Color(0.018,0.006,0.012,0.96),Color("a01028"),10))
	overlay_panel.visible=false
	root.add_child(overlay_panel)
	var ov:=VBoxContainer.new()
	ov.add_theme_constant_override("separation",14)
	overlay_panel.add_child(ov)
	overlay_title=Label.new()
	overlay_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.add_theme_font_size_override("font_size",24)
	overlay_title.add_theme_color_override("font_color",Color("fff0e8"))
	ov.add_child(overlay_title)
	overlay_body=Label.new()
	overlay_body.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	overlay_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	overlay_body.add_theme_font_size_override("font_size",17)
	overlay_body.add_theme_color_override("font_color",Color(0.88,0.8,0.78,0.9))
	overlay_body.custom_minimum_size=Vector2(650,110)
	ov.add_child(overlay_body)

	dialogue_panel=PanelContainer.new()
	dialogue_panel.anchor_left=.18
	dialogue_panel.anchor_right=.82
	dialogue_panel.anchor_top=.72
	dialogue_panel.anchor_bottom=.91
	dialogue_panel.add_theme_stylebox_override("panel",_style(Color(0.01,0.004,0.008,0.94),Color("701023"),8))
	dialogue_panel.visible=false
	root.add_child(dialogue_panel)
	dialogue_text=Label.new()
	dialogue_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	dialogue_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	dialogue_text.add_theme_font_size_override("font_size",18)
	dialogue_text.add_theme_color_override("font_color",Color("eee0da"))
	dialogue_panel.add_child(dialogue_text)

	boss_panel=Control.new()
	boss_panel.anchor_left=.25
	boss_panel.anchor_right=.75
	boss_panel.anchor_top=.88
	boss_panel.anchor_bottom=.96
	boss_panel.visible=false
	root.add_child(boss_panel)
	boss_label=Label.new()
	boss_label.text="THE BELLKEEPER"
	boss_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	boss_label.anchor_right=1
	boss_label.offset_bottom=28
	boss_label.add_theme_font_size_override("font_size",17)
	boss_label.add_theme_color_override("font_color",Color("f5e4dc"))
	boss_panel.add_child(boss_label)
	var bb:=ColorRect.new()
	bb.color=Color(0.08,0.02,0.04,.94)
	bb.anchor_left=.05
	bb.anchor_right=.95
	bb.offset_top=34
	bb.offset_bottom=49
	boss_panel.add_child(bb)
	boss_fill=ColorRect.new()
	boss_fill.color=Color("a50c24")
	boss_fill.anchor_right=1.0
	boss_fill.offset_left=2
	boss_fill.offset_top=2
	boss_fill.offset_right=-2
	boss_fill.offset_bottom=13
	bb.add_child(boss_fill)

	flash=ColorRect.new()
	flash.color=Color(0.8,0.02,0.06,0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)

	ending_panel = PanelContainer.new()
	ending_panel.anchor_left = 0.5
	ending_panel.anchor_right = 0.5
	ending_panel.anchor_top = 0.5
	ending_panel.anchor_bottom = 0.5
	ending_panel.offset_left = -350
	ending_panel.offset_right = 350
	ending_panel.offset_top = -245
	ending_panel.offset_bottom = 245
	ending_panel.add_theme_stylebox_override("panel", _style(Color(0.012,0.003,0.009,0.985), Color("b0112d"), 12))
	ending_panel.visible = false
	root.add_child(ending_panel)
	var ending_box := VBoxContainer.new()
	ending_box.add_theme_constant_override("separation", 11)
	ending_panel.add_child(ending_box)
	var ending_title := Label.new()
	ending_title.text = "THE HEARTWELL REMEMBERS FOUR FUTURES"
	ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_title.add_theme_font_size_override("font_size", 22)
	ending_box.add_child(ending_title)
	var ending_note := Label.new()
	ending_note.text = "Choose the memory Seren would become. This prototype records the choice."
	ending_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_note.add_theme_color_override("font_color", Color(0.84,0.74,0.73,0.85))
	ending_box.add_child(ending_note)
	_add_ending_button(ending_box, "DESTROY THE HEARTWELL", "destroy")
	_add_ending_button(ending_box, "MERGE WITH THE SCARLET ECHO", "merge")
	_add_ending_button(ending_box, "OPEN THE HEARTWELL", "open")
	ending_secret_button = _add_ending_button(ending_box, "SEPARATE THE MEMORIES", "secret")
	var cancel := Button.new()
	cancel.text = "NOT YET"
	cancel.custom_minimum_size = Vector2(520, 42)
	cancel.pressed.connect(_hide_endings)
	ending_box.add_child(cancel)

	memory_choice_panel = PanelContainer.new()
	memory_choice_panel.anchor_left = 0.5
	memory_choice_panel.anchor_right = 0.5
	memory_choice_panel.anchor_top = 0.5
	memory_choice_panel.anchor_bottom = 0.5
	memory_choice_panel.offset_left = -360
	memory_choice_panel.offset_right = 360
	memory_choice_panel.offset_top = -190
	memory_choice_panel.offset_bottom = 190
	memory_choice_panel.add_theme_stylebox_override("panel", _style(Color(0.012,0.003,0.009,0.985), Color("a60e2a"), 12))
	memory_choice_panel.visible = false
	root.add_child(memory_choice_panel)
	var mc_box := VBoxContainer.new()
	mc_box.add_theme_constant_override("separation", 12)
	memory_choice_panel.add_child(mc_box)
	var mc_title := Label.new()
	mc_title.text = "TWO MEMORIES OCCUPY THE SAME WOUND"
	mc_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mc_title.add_theme_font_size_override("font_size", 22)
	mc_box.add_child(mc_title)
	var mc_body := Label.new()
	mc_body.text = "The Loom cannot prove which memory is true. It can only decide which truth the world will obey."
	mc_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mc_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mc_body.custom_minimum_size = Vector2(650, 80)
	mc_body.add_theme_color_override("font_color", Color(0.86,0.76,0.74,0.9))
	mc_box.add_child(mc_body)
	var mercy := Button.new()
	mercy.text = "KEEP THE MERCY — THEY SAVED US"
	mercy.custom_minimum_size = Vector2(560, 48)
	mercy.pressed.connect(_choose_memory.bind("mercy"))
	mc_box.add_child(mercy)
	var truth := Button.new()
	truth.text = "KEEP THE WOUND — THEY ERASED US"
	truth.custom_minimum_size = Vector2(560, 48)
	truth.pressed.connect(_choose_memory.bind("truth"))
	mc_box.add_child(truth)
	var leave := Button.new()
	leave.text = "WALK AWAY"
	leave.custom_minimum_size = Vector2(560, 42)
	leave.pressed.connect(_hide_memory_choice)
	mc_box.add_child(leave)

func attach_player(p) -> void:
	player=p
	p.health_changed.connect(_on_health)
	p.veilfire_changed.connect(_on_veil)
	p.flow_changed.connect(_on_flow)
	p.perfect_parry.connect(_on_perfect_parry)
	p.mask_changed.connect(_on_mask)
	p.memory_changed.connect(_on_memory)
	p.ability_unlocked.connect(_on_ability_signal)
	_on_health(p.health,p.max_health)
	_on_veil(p.veilfire,100.0)
	_on_flow(p.flow,100.0)
	_on_mask(p.equipped_mask,str(preload("res://masks/mask_data.gd").get_mask(p.equipped_mask)["name"]))
	_on_memory(SaveManager.data.get("memory_shards",[]).size())

func _on_health(cur:int,maxi:int)->void:
	hp_text.text="HEARTGLASS  %d / %d"%[cur,maxi]
	hp_fill.scale.x=clampf(float(cur)/maxi,0,1)
	if is_instance_valid(player) and player.hurt_flash>0:
		var t:=create_tween()
		flash.color=Color(0.75,0.01,0.05,0.18)
		t.tween_property(flash,"color:a",0.0,0.28)

func _on_veil(cur:float,maxi:float)->void:
	veil_text.text="VEILFIRE  %d"%int(cur)
	veil_fill.scale.x=clampf(cur/maxi,0,1)

func _on_flow(cur:float,maxi:float)->void:
	var rank := "QUIET"
	if cur >= 85.0:
		rank = "SCARLET"
	elif cur >= 60.0:
		rank = "FIERCE"
	elif cur >= 30.0:
		rank = "RISING"
	flow_text.text="THREAD RESONANCE  %s"%rank
	flow_fill.scale.x=clampf(cur/maxi,0,1)

func _on_perfect_parry()->void:
	show_notice("PERFECT COUNTER", "The Threadblade remembers the strike before it lands.", 0.75)

func _on_mask(id:String,name:String)->void:
	mask_text.text="MASK: "+name
	var path="res://assets/art/mask_%s.png"%id
	if ResourceLoader.exists(path):
		mask_icon.texture=load(path)

func _on_memory(count:int)->void: memory_text.text="MEMORIES: %d / 12"%count

func show_region(text:String)->void:
	region_label.text=text
	region_label.modulate.a=0
	var t:=create_tween()
	t.tween_property(region_label,"modulate:a",1.0,.45)
	t.tween_interval(1.2)
	t.tween_property(region_label,"modulate:a",0.0,.8)

func show_memory(title:String,body:String)->void:
	show_notice("MEMORY SHARD — "+title,body,4.3)
	var t:=create_tween()
	flash.color=Color(0.75,0.03,0.12,0.16)
	t.tween_property(flash,"color:a",0.0,.5)

func show_notice(title:String,body:String,duration:=2.6)->void:
	overlay_title.text=title
	overlay_body.text=body
	overlay_panel.visible=true
	overlay_panel.modulate.a=0
	var t:=create_tween()
	t.tween_property(overlay_panel,"modulate:a",1.0,.18)
	t.tween_interval(duration)
	t.tween_property(overlay_panel,"modulate:a",0.0,.35)
	await t.finished
	overlay_panel.visible=false

func show_dialogue(lines:Array[String])->void:
	if lines.is_empty():
		return
	dialogue_panel.visible=true
	for line in lines:
		dialogue_text.text=line
		await get_tree().create_timer(2.4).timeout
	dialogue_panel.visible=false

func show_boss(name:String)->void:
	boss_label.text=name
	boss_panel.visible=true
	boss_fill.scale.x=1.0

func update_boss(cur:int,maxi:int)->void: boss_fill.scale.x=clampf(float(cur)/maxi,0,1)
func hide_boss()->void: boss_panel.visible=false
func set_objective(text:String)->void: objective.text="OBJECTIVE — "+text.to_upper()

func _on_ability_signal(_id: String, display_name: String) -> void:
	show_notice("ABILITY AWAKENED", display_name, 2.3)

func _add_ending_button(parent: VBoxContainer, text: String, id: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(520, 48)
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(_choose_ending.bind(id))
	parent.add_child(b)
	return b

func show_ending_choices(secret_available: bool) -> void:
	ending_secret_button.disabled = not secret_available
	ending_secret_button.text = "SEPARATE THE MEMORIES" if secret_available else "SEPARATE THE MEMORIES — RECOVER ALL 12 SHARDS"
	ending_panel.visible = true

func _choose_ending(id: String) -> void:
	ending_panel.visible = false
	ending_chosen.emit(id)

func _hide_endings() -> void:
	ending_panel.visible = false

func show_memory_choice() -> void:
	memory_choice_panel.visible = true

func _hide_memory_choice() -> void:
	memory_choice_panel.visible = false

func _choose_memory(id: String) -> void:
	memory_choice_panel.visible = false
	memory_choice_chosen.emit(id)
