extends Node2D

signal return_to_title

const PLAYER_SCENE:=preload("res://player/Seren.tscn")
const ENEMY_SCENE:=preload("res://enemies/Hollowed.tscn")
const INK_WRAITH_SCENE:=preload("res://enemies/InkWraith.tscn")
const BOSS_SCENE:=preload("res://bosses/Bellkeeper.tscn")
const MOTHER_SCENE:=preload("res://bosses/MotherThren.tscn")
const REGENT_SCENE:=preload("res://bosses/PaleRegent.tscn")
const LOOM_SCENE:=preload("res://world/MemoryLoom.tscn")
const MOVING_PLATFORM_SCENE:=preload("res://world/MovingPlatform.tscn")
const MEMORY_SCENE:=preload("res://items/MemoryShard.tscn")
const ABILITY_SCENE:=preload("res://items/AbilityShrine.tscn")
const MASK_SCENE:=preload("res://items/MaskPickup.tscn")
const ANCHOR_SCENE:=preload("res://world/GrappleAnchor.tscn")
const NPC_SCENE:=preload("res://npc/Whisperer.tscn")
const HUD_SCENE:=preload("res://ui/HUD.tscn")
const TOUCH_SCENE:=preload("res://ui/TouchControls.tscn")
const PAUSE_SCENE:=preload("res://ui/PauseMenu.tscn")
const ENDING_ALTAR_SCENE:=preload("res://world/EndingAltar.tscn")

var player
var hud
var touch_controls
var pause_menu
var boss
var mother
var regent
var loom
var boss_gate:StaticBody2D
var boss_exit_gate:StaticBody2D
var mother_gate:StaticBody2D
var mother_exit_gate:StaticBody2D
var regent_gate:StaticBody2D
var regent_exit_gate:StaticBody2D
var boss_started:=false
var mother_started:=false
var regent_started:=false
var current_region:=""
var checkpoint_stage:=0
var autosave_timer:=0.0
var bg_far:Node2D
var bg_mid:Node2D
var bg_near:Node2D
var fog_nodes:Array[Polygon2D]=[]
var mote_nodes:Array[Polygon2D]=[]
var memory_catalog:Dictionary={}
var ending_shown:=false
var truth_shortcut_built:=false

func _ready()->void:
	_load_catalog()
	_build_background()
	_build_geometry()
	_build_decorations()
	_spawn_objects()
	_spawn_player()
	_build_ui()
	AudioManager.play_music("res://assets/audio/ambient.wav",-18.0)
	_check_region(true)
	hud.set_objective("Find a way out")

func _load_catalog()->void:
	var file:=FileAccess.open("res://data/memories.json",FileAccess.READ)
	if file!=null:
		var parsed=JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			memory_catalog=parsed

func _process(delta:float)->void:
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	if get_tree().paused:
		return
	if not is_instance_valid(player):
		return
	_update_parallax()
	_update_atmosphere(delta)
	_update_hidden_echoes()
	_check_region(false)
	_check_progression()
	_check_fall()
	autosave_timer+=delta
	if autosave_timer>8.0:
		autosave_timer=0.0
		save_game(false)

func _build_background()->void:
	var clear:=Polygon2D.new()
	clear.polygon=PackedVector2Array([Vector2(-500,-350),Vector2(10600,-350),Vector2(10600,760),Vector2(-500,760)])
	clear.color=Color("070409")
	clear.z_index=-120
	add_child(clear)
	bg_far=_make_bg_layer("res://assets/art/bg_far.png",-110)
	bg_mid=_make_bg_layer("res://assets/art/bg_mid.png",-100)
	bg_near=_make_bg_layer("res://assets/art/bg_near.png",-70)
	_add_region_haze(Rect2(2050,0,3050,720),Color(0.34,0.02,0.055,0.055))
	_add_region_haze(Rect2(5050,0,2130,720),Color(0.24,0.08,0.08,0.045))
	_add_region_haze(Rect2(7180,0,1500,720),Color(0.08,0.04,0.18,0.10))
	_add_region_haze(Rect2(8680,0,1900,720),Color(0.42,0.015,0.06,0.075))
	# Red shafts and Veil haze.
	for x in [620.0,1650.0,2920.0,4210.0,5480.0,6550.0,7580.0,8650.0,9440.0]:
		var shaft:=Polygon2D.new()
		shaft.polygon=PackedVector2Array([Vector2(-18,-340),Vector2(18,-340),Vector2(44,330),Vector2(-44,330)])
		shaft.position=Vector2(x,300)
		shaft.color=Color(0.65,0.01,0.06,0.06)
		shaft.z_index=-65
		add_child(shaft)
	for i in range(21):
		var fog:=Polygon2D.new()
		fog.polygon=PackedVector2Array([Vector2(-155,-18),Vector2(-85,-42),Vector2(20,-36),Vector2(155,-8),Vector2(110,24),Vector2(-100,28)])
		fog.position=Vector2(80+i*500,420+(i%3)*60)
		fog.color=Color(0.48,0.015,0.05,0.055)
		fog.z_index=-40
		fog_nodes.append(fog)
		add_child(fog)
	for i in range(62):
		var m:=Polygon2D.new()
		var r:=1.5+float(i%3)
		m.polygon=PackedVector2Array([Vector2(0,-r),Vector2(r,0),Vector2(0,r),Vector2(-r,0)])
		m.position=Vector2(80+fmod(float(i*353),10200.0),100+fmod(float(i*97),500.0))
		m.color=Color(0.95,0.04,0.11,0.17+float(i%5)*0.025)
		m.z_index=-32
		mote_nodes.append(m)
		add_child(m)

func _add_region_haze(rect:Rect2,color:Color)->void:
	var p:=Polygon2D.new()
	p.position=rect.position
	p.polygon=PackedVector2Array([Vector2.ZERO,Vector2(rect.size.x,0),rect.size,Vector2(0,rect.size.y)])
	p.color=color
	p.z_index=-62
	add_child(p)

func _make_bg_layer(path:String,z:int)->Node2D:
	var layer:=Node2D.new()
	layer.z_index=z
	add_child(layer)
	for x in [0.0,2048.0,4096.0,6144.0,8192.0,10240.0]:
		var s:=Sprite2D.new()
		s.texture=load(path)
		s.centered=false
		s.position=Vector2(x,0)
		layer.add_child(s)
	return layer

func _update_parallax()->void:
	bg_far.position.x=player.global_position.x*0.80
	bg_mid.position.x=player.global_position.x*0.56
	bg_near.position.x=player.global_position.x*0.18

func _update_atmosphere(delta:float)->void:
	for i in range(fog_nodes.size()):
		var f:=fog_nodes[i]
		f.position.x+=delta*(5.0+float(i%3)*2.0)
		if f.position.x>10450:
			f.position.x=-150
	for i in range(mote_nodes.size()):
		var m:=mote_nodes[i]
		m.position.y-=delta*(7.0+float(i%6)*2.0)
		m.position.x+=sin(float(i)+m.position.y*.018)*delta*3.0
		if m.position.y<70:
			m.position.y=640

func _build_geometry()->void:
	# Forgotten Sanctuary — training route.
	_add_platform(Rect2(-180,620,1920,120),Color("21181e"))
	_add_platform(Rect2(2050,620,720,120),Color("25191f"))
	_add_platform(Rect2(310,510,220,26),Color("38272f"))
	_add_platform(Rect2(665,455,170,24),Color("38272f"))
	_add_platform(Rect2(1000,500,145,24),Color("38272f"))
	_add_platform(Rect2(1280,410,185,24),Color("38272f"))
	_add_platform(Rect2(1520,515,160,24),Color("38272f"))
	_add_platform(Rect2(1750,540,90,22),Color("38272f"))
	_add_platform(Rect2(1870,480,95,22),Color("38272f"))
	_add_platform(Rect2(1970,550,110,22),Color("38272f"))
	# wall-jump chapel / secret loft
	_add_platform(Rect2(1145,275,34,345),Color("30242a"))
	_add_platform(Rect2(1470,250,34,370),Color("30242a"))
	_add_platform(Rect2(1190,215,280,24),Color("3a2931"))
	# Ashen Hollow
	_add_platform(Rect2(2770,620,800,120),Color("28191e"))
	_add_platform(Rect2(3910,620,1320,120),Color("291a20"))
	_add_platform(Rect2(2210,520,260,26),Color("3a2830"))
	_add_platform(Rect2(2490,420,200,24),Color("3a2830"))
	_add_platform(Rect2(2840,500,180,24),Color("3a2830"))
	_add_platform(Rect2(3180,445,250,24),Color("3a2830"))
	_add_platform(Rect2(3480,525,90,22),Color("3a2830"))
	# grapple ravine between 3570 and 3910
	_add_platform(Rect2(3600,510,70,18),Color("3c2930"))
	_add_platform(Rect2(3790,455,70,18),Color("3c2930"))
	# rooftops / lower secret
	_add_platform(Rect2(3020,320,165,20),Color("34232a"))
	_add_platform(Rect2(3350,295,190,20),Color("34232a"))
	# Iron Choir approach
	_add_platform(Rect2(5230,620,1960,120),Color("21191c"))
	_add_platform(Rect2(4410,510,180,24),Color("403039"))
	_add_platform(Rect2(4700,430,180,24),Color("403039"))
	_add_platform(Rect2(4980,515,170,24),Color("403039"))
	_add_platform(Rect2(5300,470,130,22),Color("403039"))
	# far exit dais
	_add_platform(Rect2(6950,520,220,22),Color("4a3038"))
	# Drowned Archive — black-water stacks and moving bridges.
	_add_platform(Rect2(7180,620,700,120),Color("17151d"))
	_add_platform(Rect2(8260,620,420,120),Color("17151d"))
	_add_platform(Rect2(7350,500,160,22),Color("302838"))
	_add_platform(Rect2(7610,405,150,22),Color("302838"))
	_add_platform(Rect2(8330,470,180,22),Color("302838"))
	# Crimson approach / Regent bridge.
	_add_platform(Rect2(8680,620,1540,120),Color("25171d"))
	_add_platform(Rect2(8770,500,150,22),Color("47303a"))
	_add_platform(Rect2(8990,430,170,22),Color("47303a"))
	_add_platform(Rect2(9440,455,170,22),Color("47303a"))
	_add_platform(Rect2(10180,520,250,22),Color("56323d"))
	if SaveManager.data.get("important_choices", {}).get("mercy_or_truth", "") == "truth":
		_add_truth_shortcut()

func _add_truth_shortcut()->void:
	if truth_shortcut_built:
		return
	truth_shortcut_built = true
	_add_platform(Rect2(3715,410,115,18),Color("5a2634"))
	_add_platform(Rect2(3870,355,115,18),Color("5a2634"))

func _add_platform(rect:Rect2,color:Color)->StaticBody2D:
	var body:=StaticBody2D.new()
	body.collision_layer=1
	body.collision_mask=0
	body.position=rect.position+rect.size*.5
	add_child(body)
	var c:=CollisionShape2D.new()
	var s:=RectangleShape2D.new()
	s.size=rect.size
	c.shape=s
	body.add_child(c)
	var p:=Polygon2D.new()
	p.polygon=PackedVector2Array([Vector2(-rect.size.x*.5,-rect.size.y*.5),Vector2(rect.size.x*.5,-rect.size.y*.5),Vector2(rect.size.x*.5,rect.size.y*.5),Vector2(-rect.size.x*.5,rect.size.y*.5)])
	p.color=color
	body.add_child(p)
	var edge:=Line2D.new()
	edge.width=2
	edge.default_color=Color(0.47,0.25,0.31,0.45)
	edge.points=PackedVector2Array([Vector2(-rect.size.x*.5,-rect.size.y*.5),Vector2(rect.size.x*.5,-rect.size.y*.5)])
	body.add_child(edge)
	return body

func _build_decorations()->void:
	# Sanctuary statues, graves, scratched masks.
	for x in [120.0,520.0,930.0,1580.0]:
		_add_statue(Vector2(x,570))
	for x in [240.0,370.0,570.0,710.0,890.0]:
		_add_grave(Vector2(x,600),x/100.0)
	for x in [1080.0,1380.0,1680.0]:
		_add_broken_mask(Vector2(x,592))
	# Ashen houses and red flowers.
	_add_house(Vector2(2200,620),360,235)
	_add_house(Vector2(3030,620),430,260)
	_add_house(Vector2(4010,620),390,220)
	for i in range(28):
		_add_flower(Vector2(2150+fmod(float(i*179),3000.0),606),0.75+float(i%4)*.08)
	# Iron Choir bells and machinery.
	for x in [4720.0,5350.0,6120.0,6620.0]:
		_add_bell(Vector2(x,210 if x<5700 else 180),1.0 if x<5700 else 1.35)
	for x in [4520.0,5060.0,5460.0]:
		_add_gear(Vector2(x,565),34.0+fmod(float(x),18.0))
	# Drowned Archive — readable silhouettes, black water and drifting pages.
	for x in [7290.0, 7500.0, 7700.0, 8380.0, 8550.0]:
		_add_bookshelf(Vector2(x, 615))
	_add_black_water(Rect2(7880, 590, 380, 135))
	for i in range(16):
		_add_page(Vector2(7240 + fmod(float(i * 113), 1380.0), 210 + fmod(float(i * 67), 310.0)), float(i))
	# Crimson Citadel approach — pillars act as strong navigation landmarks.
	for x in [8780.0, 9020.0, 9360.0, 9640.0, 10020.0]:
		_add_citadel_pillar(Vector2(x, 620))

	# Royal-looking distant gate tease.
	var gate:=Polygon2D.new()
	gate.position=Vector2(10270,420)
	gate.polygon=PackedVector2Array([Vector2(-70,200),Vector2(-60,-70),Vector2(0,-145),Vector2(60,-70),Vector2(70,200)])
	gate.color=Color("1d1017")
	gate.z_index=-10
	add_child(gate)
	var sigil:=Line2D.new()
	sigil.position=Vector2(10270,350)
	sigil.width=4
	sigil.default_color=Color(0.8,0.02,0.08,.45)
	sigil.points=PackedVector2Array([Vector2(0,-55),Vector2(0,55),Vector2(-24,10),Vector2(24,10),Vector2(0,-55)])
	add_child(sigil)

func _add_statue(pos:Vector2)->void:
	var n:=Node2D.new()
	n.position=pos
	n.z_index=-5
	add_child(n)
	var body:=Polygon2D.new()
	body.polygon=PackedVector2Array([Vector2(-18,0),Vector2(18,0),Vector2(24,-70),Vector2(0,-95),Vector2(-24,-70)])
	body.color=Color("2e252a")
	n.add_child(body)
	var mask:=Polygon2D.new()
	mask.polygon=PackedVector2Array([Vector2(-10,-83),Vector2(10,-83),Vector2(13,-69),Vector2(0,-57),Vector2(-13,-69)])
	mask.color=Color("877d78")
	n.add_child(mask)
	var scratch:=Line2D.new()
	scratch.width=3
	scratch.default_color=Color("241419")
	scratch.points=PackedVector2Array([Vector2(-10,-80),Vector2(10,-61)])
	n.add_child(scratch)

func _add_grave(pos:Vector2,seed:float)->void:
	var p:=Polygon2D.new()
	p.position=pos
	p.polygon=PackedVector2Array([Vector2(-13,0),Vector2(13,0),Vector2(11,-37),Vector2(0,-49),Vector2(-11,-37)])
	p.color=Color("36282f")
	p.rotation=sin(seed)*.08
	p.z_index=-4
	add_child(p)

func _add_broken_mask(pos:Vector2)->void:
	var p:=Polygon2D.new()
	p.position=pos
	p.polygon=PackedVector2Array([Vector2(-9,0),Vector2(12,-2),Vector2(14,-18),Vector2(0,-28),Vector2(-12,-15)])
	p.color=Color("b7aaa4")
	p.rotation=.6
	add_child(p)

func _add_house(pos:Vector2,w:float,h:float)->void:
	var n:=Node2D.new()
	n.position=pos
	n.z_index=-12
	add_child(n)
	var wall:=Polygon2D.new()
	wall.polygon=PackedVector2Array([Vector2(0,0),Vector2(w,0),Vector2(w,-h),Vector2(w*.62,-h-70),Vector2(w*.1,-h)])
	wall.color=Color("25151b")
	n.add_child(wall)
	for xx in [w*.25,w*.68]:
		var win:=Polygon2D.new()
		win.polygon=PackedVector2Array([Vector2(-24,0),Vector2(24,0),Vector2(24,-60),Vector2(0,-78),Vector2(-24,-60)])
		win.position=Vector2(xx,-100)
		win.color=Color(0.65,0.02,0.07,.12)
		n.add_child(win)

func _add_flower(pos:Vector2,scalev:float)->void:
	var n:=Node2D.new()
	n.position=pos
	n.scale=Vector2.ONE*scalev
	n.z_index=4
	add_child(n)
	var stem:=Line2D.new()
	stem.width=1.4
	stem.default_color=Color("49101e")
	stem.points=PackedVector2Array([Vector2(0,0),Vector2(0,-15)])
	n.add_child(stem)
	for a in [0.0,2.1,4.2]:
		var p:=Polygon2D.new()
		p.position=Vector2(0,-17)
		p.rotation=a
		p.polygon=PackedVector2Array([Vector2(0,0),Vector2(7,-2),Vector2(3,-8)])
		p.color=Color("9f0d29")
		n.add_child(p)

func _add_bell(pos:Vector2,scalev:float)->void:
	var n:=Node2D.new()
	n.position=pos
	n.scale=Vector2.ONE*scalev
	n.z_index=-6
	add_child(n)
	var rope:=Line2D.new()
	rope.width=3
	rope.default_color=Color("3d2930")
	rope.points=PackedVector2Array([Vector2(0,-210),Vector2(0,-30)])
	n.add_child(rope)
	var bellp:=Polygon2D.new()
	bellp.polygon=PackedVector2Array([Vector2(-44,0),Vector2(44,0),Vector2(32,-75),Vector2(0,-95),Vector2(-32,-75)])
	bellp.color=Color("51434a")
	n.add_child(bellp)
	var rim:=Line2D.new()
	rim.width=5
	rim.default_color=Color("8f3947")
	rim.points=PackedVector2Array([Vector2(-44,0),Vector2(44,0)])
	n.add_child(rim)

func _add_gear(pos: Vector2, r: float) -> void:
	var l := Line2D.new()
	l.position = pos
	l.width = 7.0
	l.default_color = Color("4a343c")
	var pts := PackedVector2Array()
	for i in range(13):
		var a := TAU * float(i) / 12.0
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	l.points = pts
	l.closed = true
	l.z_index = -3
	add_child(l)

func _add_bookshelf(pos:Vector2)->void:
	var n:=Node2D.new()
	n.position=pos
	n.z_index=-8
	add_child(n)
	var frame:=Polygon2D.new()
	frame.polygon=PackedVector2Array([Vector2(-55,0),Vector2(55,0),Vector2(55,-150),Vector2(-55,-150)])
	frame.color=Color("201923")
	n.add_child(frame)
	for row in range(4):
		var y:=-25.0-row*34.0
		var shelf:=Line2D.new()
		shelf.width=3
		shelf.default_color=Color("49313e")
		shelf.points=PackedVector2Array([Vector2(-48,y),Vector2(48,y)])
		n.add_child(shelf)
		for col in range(6):
			var book:=Polygon2D.new()
			var x:=-42.0+col*15.0
			book.polygon=PackedVector2Array([Vector2(x,y-25),Vector2(x+9,y-25),Vector2(x+9,y-3),Vector2(x,y-3)])
			book.color=Color(0.24+col*.02,0.07,0.11+row*.015,0.8)
			n.add_child(book)

func _add_black_water(rect:Rect2)->void:
	var water:=Polygon2D.new()
	water.position=rect.position
	water.z_index=-2
	water.polygon=PackedVector2Array([Vector2.ZERO,Vector2(rect.size.x,0),rect.size,Vector2(0,rect.size.y)])
	water.color=Color(0.012,0.009,0.02,0.96)
	add_child(water)
	var edge:=Line2D.new()
	edge.position=rect.position
	edge.width=3
	edge.default_color=Color(0.58,0.03,0.12,0.4)
	edge.points=PackedVector2Array([Vector2(0,0),Vector2(rect.size.x,0)])
	add_child(edge)

func _add_page(pos:Vector2,seed:float)->void:
	var p:=Polygon2D.new()
	p.position=pos
	p.z_index=-4
	p.polygon=PackedVector2Array([Vector2(-8,-5),Vector2(9,-4),Vector2(7,6),Vector2(-9,5)])
	p.color=Color(0.72,0.67,0.62,0.42)
	p.rotation=sin(seed*1.7)*0.7
	add_child(p)

func _add_citadel_pillar(pos:Vector2)->void:
	var p:=Polygon2D.new()
	p.position=pos
	p.z_index=-10
	p.polygon=PackedVector2Array([Vector2(-22,0),Vector2(22,0),Vector2(17,-230),Vector2(0,-270),Vector2(-17,-230)])
	p.color=Color("2b1b22")
	add_child(p)
	var crack:=Line2D.new()
	crack.position=pos+Vector2(0,-150)
	crack.width=2
	crack.default_color=Color(0.62,0.03,0.1,0.35)
	crack.points=PackedVector2Array([Vector2(-4,-45),Vector2(5,-15),Vector2(-3,10),Vector2(8,44)])
	add_child(crack)

func _spawn_objects()->void:
	_spawn_ability(Vector2(780,575),"wall_jump","WALL JUMP","Kick away from ancient stone. Reach the sanctuary lofts.")
	_spawn_ability(Vector2(1580,575),"dash","SCARLET DASH","Burst through danger in a streak of Veilfire.")
	_spawn_ability(Vector2(2530,375),"grapple","THREADBLADE GRAPPLE","Throw the blade into crimson anchors and carry your momentum.")
	_spawn_ability(Vector2(3920,575),"down_strike","FALLING THREAD","Drive the Threadblade downward and shatter enemies beneath you.")
	_spawn_mask(Vector2(1330,180),"echo")
	_spawn_mask(Vector2(3370,260),"hunter")
	_spawn_anchor(Vector2(2540,315))
	_spawn_anchor(Vector2(2860,310))
	_spawn_anchor(Vector2(3140,285))
	_spawn_anchor(Vector2(3710,275))
	_spawn_anchor(Vector2(3900,325))
	_spawn_anchor(Vector2(4770,265))
	_spawn_anchor(Vector2(5120,330))
	_spawn_memory(Vector2(470,570),"sanctuary_01")
	_spawn_memory(Vector2(1260,365),"sanctuary_02")
	_spawn_memory(Vector2(1830,435),"seren_warning")
	_spawn_memory(Vector2(2340,480),"ashen_01")
	_spawn_memory(Vector2(3310,405),"ashen_02")
	_spawn_memory(Vector2(4860,385),"choir_01")
	_spawn_memory(Vector2(1400,165),"echo_secret",true)
	_spawn_enemy(Vector2(1030,570),"guardian")
	_spawn_enemy(Vector2(2230,570),"mourner")
	_spawn_enemy(Vector2(2930,570),"guardian")
	_spawn_enemy(Vector2(3460,570),"mourner")
	_spawn_enemy(Vector2(4850,570),"guardian")
	_spawn_enemy(Vector2(5330,570),"warden")
	_spawn_enemy(Vector2(7420,570),"mourner")
	_spawn_enemy(Vector2(8460,570),"warden")
	_spawn_ink_wraith(Vector2(7680,350))
	_spawn_ink_wraith(Vector2(8380,330))
	_spawn_enemy(Vector2(8880,570),"guardian")
	var npc = NPC_SCENE.instantiate()
	add_child(npc)
	npc.global_position = Vector2(3520, 565)
	npc.dialogue_requested.connect(_on_npc_dialogue)
	loom = LOOM_SCENE.instantiate()
	add_child(loom)
	loom.global_position = Vector2(3680, 565)
	loom.choice_requested.connect(_on_loom_choice_requested)

	_spawn_moving_platform(Vector2(7920,500),Vector2(260,-80),2.7,0.0)
	_spawn_moving_platform(Vector2(8120,395),Vector2(210,95),2.4,1.2)

	var altar = ENDING_ALTAR_SCENE.instantiate()
	add_child(altar)
	altar.global_position = Vector2(10270, 470)
	altar.choice_requested.connect(_on_ending_altar)
	if not bool(SaveManager.data.get("bosses_defeated",{}).get("mother_thren",false)):
		mother = MOTHER_SCENE.instantiate()
		add_child(mother)
		mother.global_position = Vector2(4440,560)
		mother.boss_health.connect(_on_boss_health)
		mother.defeated.connect(_on_mother_defeated)
	else:
		_spawn_memory(Vector2(4440,545),"mother_thren")

	if not bool(SaveManager.data.get("bosses_defeated",{}).get("bellkeeper",false)):
		boss = BOSS_SCENE.instantiate()
		add_child(boss)
		boss.global_position = Vector2(6330, 560)
		boss.boss_health.connect(_on_boss_health)
		boss.defeated.connect(_on_boss_defeated)
	else:
		_spawn_memory(Vector2(6330,550),"bellkeeper")

	_spawn_memory(Vector2(7480,455),"archive_01")
	_spawn_memory(Vector2(8460,425),"archive_02")
	if not bool(SaveManager.data.get("bosses_defeated",{}).get("pale_regent",false)):
		regent = REGENT_SCENE.instantiate()
		add_child(regent)
		regent.global_position = Vector2(9250,560)
		regent.boss_health.connect(_on_boss_health)
		regent.defeated.connect(_on_regent_defeated)
	else:
		_spawn_memory(Vector2(9250,545),"regent_echo")

func _spawn_player()->void:
	player=PLAYER_SCENE.instantiate()
	add_child(player)
	var pos_arr=SaveManager.data.get("player_position",[180.0,540.0])
	player.global_position=Vector2(float(pos_arr[0]),float(pos_arr[1]))
	player.died.connect(_on_player_died)

func _build_ui()->void:
	hud=HUD_SCENE.instantiate()
	add_child(hud)
	hud.attach_player(player)
	hud.ending_chosen.connect(_on_ending_chosen)
	hud.memory_choice_chosen.connect(_on_memory_choice_chosen)
	touch_controls=TOUCH_SCENE.instantiate()
	add_child(touch_controls)
	pause_menu = PAUSE_SCENE.instantiate()
	add_child(pause_menu)
	pause_menu.return_to_title.connect(_on_pause_return)
	pause_menu.save_requested.connect(_on_manual_save)

func _spawn_enemy(pos:Vector2,variant:String)->void:
	var e=ENEMY_SCENE.instantiate()
	e.variant=variant
	e.position=pos
	add_child(e)
func _spawn_ink_wraith(pos:Vector2)->void:
	var e=INK_WRAITH_SCENE.instantiate()
	e.position=pos
	add_child(e)
func _spawn_anchor(pos:Vector2)->void:
	var a=ANCHOR_SCENE.instantiate()
	add_child(a)
	a.global_position=pos
func _spawn_ability(pos: Vector2, id: String, name: String, desc: String) -> void:
	var a = ABILITY_SCENE.instantiate()
	a.ability_id = id
	a.display_name = name
	a.description = desc
	add_child(a)
	a.global_position = pos
	a.activated.connect(_on_ability_activated)

func _spawn_mask(pos: Vector2, id: String) -> void:
	var m = MASK_SCENE.instantiate()
	m.mask_id = id
	m.position = pos
	add_child(m)
	m.picked.connect(_on_mask_picked)

func _spawn_memory(pos: Vector2, id: String, hidden := false) -> void:
	if id in SaveManager.data.get("memory_shards", []):
		return
	var m = MEMORY_SCENE.instantiate()
	m.memory_id = id
	m.hidden_until_echo = hidden
	m.position = pos
	if memory_catalog.has(id):
		m.memory_title = str(memory_catalog[id]["title"])
		m.memory_text = str(memory_catalog[id]["text"])
	add_child(m)
	m.collected.connect(_on_memory_collected)

func _update_hidden_echoes()->void:
	var reveal:=player.equipped_mask=="echo"
	for n in get_tree().get_nodes_in_group("memory_shards"):
		if is_instance_valid(n) and bool(n.hidden_until_echo):
			n.set_revealed(reveal)

func _check_region(force:bool)->void:
	var next:="THE FORGOTTEN SANCTUARY"
	if player.global_position.x>=2100:
		next="ASHEN HOLLOW"
	if player.global_position.x>=4050:
		next="THE CRADLE COURT"
	if player.global_position.x>=5050:
		next="THE IRON CHOIR"
	if player.global_position.x>=5650:
		next="BELL COURT"
	if player.global_position.x>=7180:
		next="THE DROWNED ARCHIVE"
	if player.global_position.x>=8680:
		next="THE CRIMSON APPROACH"
	if player.global_position.x>=8850:
		next="THE REGENT'S BRIDGE"
	if force or next!=current_region:
		current_region=next
		hud.show_region(next)

func _check_progression()->void:
	var x:=player.global_position.x
	if x>1900 and checkpoint_stage<1:
		checkpoint_stage=1
		SaveManager.data["checkpoint"]=[2050.0,540.0]
		save_game(true)
	if x>4050 and is_instance_valid(mother) and not mother_started:
		mother_started=true
		mother_gate=_add_platform(Rect2(4010,260,26,360),Color("55101e"))
		mother_exit_gate=_add_platform(Rect2(5010,260,26,360),Color("55101e"))
		hud.show_boss("MOTHER THREN — THE EMPTY CRADLE")
		hud.set_objective("Survive the lullaby")
		AudioManager.play_music("res://assets/audio/boss_theme.wav",-11.0)
		mother.call("start_battle")
	if x>5200 and checkpoint_stage<2 and bool(SaveManager.data.get("bosses_defeated",{}).get("mother_thren",false)):
		checkpoint_stage=2
		SaveManager.data["checkpoint"]=[5300.0,540.0]
		save_game(true)
	if x>5700 and is_instance_valid(boss) and not boss_started:
		boss_started=true
		_close_boss_gate()
		hud.show_boss("THE BELLKEEPER — THE LAST COMMAND")
		hud.set_objective("Silence the warning bell")
		AudioManager.play_music("res://assets/audio/boss_theme.wav",-10.0)
		boss.call("start_battle")
	if x>7200 and checkpoint_stage<3 and bool(SaveManager.data.get("bosses_defeated",{}).get("bellkeeper",false)):
		checkpoint_stage=3
		SaveManager.data["checkpoint"]=[7240.0,540.0]
		save_game(true)
		hud.set_objective("Cross the drowned stacks")
	if x>8850 and is_instance_valid(regent) and not regent_started:
		regent_started=true
		regent_gate=_add_platform(Rect2(8640,250,28,370),Color("651225"))
		regent_exit_gate=_add_platform(Rect2(9750,245,28,375),Color("651225"))
		hud.show_boss("THE PALE REGENT — MEMORY WITHOUT GRIEF")
		hud.set_objective("Refuse the life he remembers for you")
		AudioManager.play_music("res://assets/audio/boss_theme.wav",-8.5)
		regent.call("start_battle")
	if x>10020 and bool(SaveManager.data.get("bosses_defeated",{}).get("pale_regent",false)) and not ending_shown:
		ending_shown=true
		hud.set_objective("Answer the Heartwell")
		hud.show_notice("THE HEARTWELL IS LISTENING","Three guardians are silent. Twelve memories disagree about what happened. Seren must choose what kind of truth survives.",5.4)

func _close_boss_gate()->void:
	boss_gate=_add_platform(Rect2(5600,260,28,360),Color("55101e"))
	boss_exit_gate=_add_platform(Rect2(6890,250,28,370),Color("55101e"))
	boss_gate.z_index=4
	boss_exit_gate.z_index=4
func _open_boss_gate()->void:
	if is_instance_valid(boss_gate):
		boss_gate.queue_free()
	if is_instance_valid(boss_exit_gate):
		boss_exit_gate.queue_free()

func _on_boss_defeated()->void:
	_open_boss_gate()
	hud.hide_boss()
	hud.set_objective("Follow the red road deeper")
	AudioManager.play_music("res://assets/audio/ambient.wav",-18.0)
	_spawn_memory(Vector2(6330,545),"bellkeeper")
	SaveManager.data["checkpoint"]=[6500.0,540.0]
	save_game(true)

func _on_mother_defeated()->void:
	if is_instance_valid(mother_gate):
		mother_gate.queue_free()
	if is_instance_valid(mother_exit_gate):
		mother_exit_gate.queue_free()
	hud.hide_boss()
	hud.set_objective("Follow the bells beneath Ashen Hollow")
	AudioManager.play_music("res://assets/audio/ambient.wav",-18.0)
	_spawn_memory(Vector2(4440,545),"mother_thren")
	SaveManager.data["checkpoint"]=[4700.0,540.0]
	save_game(true)

func _on_regent_defeated()->void:
	if is_instance_valid(regent_gate):
		regent_gate.queue_free()
	if is_instance_valid(regent_exit_gate):
		regent_exit_gate.queue_free()
	hud.hide_boss()
	hud.set_objective("Approach the Heartwell")
	AudioManager.play_music("res://assets/audio/ambient.wav",-17.0)
	_spawn_memory(Vector2(9250,545),"regent_echo")
	SaveManager.data["checkpoint"]=[9850.0,540.0]
	save_game(true)

func _on_player_died()->void:
	await get_tree().create_timer(0.65).timeout
	var cp=SaveManager.data.get("checkpoint",[180.0,540.0])
	var respawn := Vector2(float(cp[0]),float(cp[1]))
	# If a boss gate is sealed, respawn Seren inside the active arena so death never soft-locks progression.
	if mother_started and is_instance_valid(mother):
		respawn = Vector2(4110,540)
	elif boss_started and is_instance_valid(boss):
		respawn = Vector2(5685,540)
	elif regent_started and is_instance_valid(regent):
		respawn = Vector2(8720,540)
	player.global_position=respawn
	player.velocity=Vector2.ZERO
	player.heal_full()
	SaveManager.data["health"]=player.health
	SaveManager.save_to_disk()
	hud.show_notice("HEARTGLASS REFORGED","The mask remembers the last sanctuary flame.",1.6)

func _check_fall()->void:
	if player.global_position.y>820 and player.health>0:
		player.take_damage(99,player.global_position+Vector2(0,50),null)

func save_game(force := false) -> void:
	if not is_instance_valid(player):
		return
	var snap: Dictionary = player.get_save_snapshot()
	for key in snap.keys():
		SaveManager.data[key] = snap[key]
	if force or autosave_timer == 0.0:
		SaveManager.save_to_disk()

func _on_npc_dialogue(lines: Array[String]) -> void:
	if is_instance_valid(hud):
		hud.show_dialogue(lines)

func _on_boss_health(current: int, maximum: int) -> void:
	if is_instance_valid(hud):
		hud.update_boss(current, maximum)

func _on_ability_activated(_id: String, display_name: String, description: String) -> void:
	if is_instance_valid(hud):
		hud.show_notice("ABILITY AWAKENED — " + display_name, description, 3.0)

func _on_mask_picked(_id: String, display_name: String, description: String) -> void:
	if is_instance_valid(hud):
		hud.show_notice("HEARTGLASS MASK — " + display_name, description, 3.2)

func _on_memory_collected(_id: String, title: String, text: String) -> void:
	if is_instance_valid(hud):
		hud.show_memory(title, text)

func _on_manual_save() -> void:
	save_game(true)
	if is_instance_valid(hud):
		hud.show_notice("MEMORY ANCHORED", "Your progress has been written into Heartglass.", 1.4)

func _on_pause_return() -> void:
	save_game(true)
	return_to_title.emit()

func _on_ending_altar() -> void:
	if not bool(SaveManager.data.get("bosses_defeated", {}).get("pale_regent", false)):
		if is_instance_valid(hud):
			hud.show_notice("THE HEARTWELL DOES NOT ANSWER", "The Regent still stands between Seren and the Heartwell.", 2.2)
		return
	var secret_available := SaveManager.data.get("memory_shards", []).size() >= 12 and player.unlocked_masks.has("echo")
	AudioManager.play_voice("res://assets/audio/voice_scarlet_echo.wav")
	hud.show_ending_choices(secret_available)

func _on_ending_chosen(id: String) -> void:
	SaveManager.data["important_choices"]["heartwell_choice"] = id
	SaveManager.data["ending_flags"][id] = true
	SaveManager.save_to_disk()
	var title := "ENDING — THE LAST MEMORY"
	var text := ""
	match id:
		"destroy":
			title = "ENDING I — ASHES OF MEMORY"
			text = "Seren destroys the Heartwell. The Veil ends — and every trapped memory ends with it."
		"merge":
			title = "ENDING II — SCARLET SOVEREIGN"
			text = "Seren merges with the Scarlet Echo and becomes the new mind behind the Veil."
		"open":
			title = "ENDING III — CAEL MOURNE REMEMBERED"
			text = "The Heartwell opens. Memory-born citizens return while the surface sky begins to turn red."
		"secret":
			title = "SECRET ENDING — THE FREED VEIL"
			text = "Seren separates memory from hunger. The dead are allowed to end, and she keeps the self she chose."
	hud.show_notice(title, text, 6.0)

func _spawn_moving_platform(pos:Vector2,travel:Vector2,duration:float,phase:float)->void:
	var m=MOVING_PLATFORM_SCENE.instantiate()
	m.position=pos
	m.travel=travel
	m.duration=duration
	m.phase=phase
	add_child(m)

func _on_loom_choice_requested()->void:
	if is_instance_valid(hud):
		hud.show_memory_choice()

func _on_memory_choice_chosen(id:String)->void:
	SaveManager.data["important_choices"]["mercy_or_truth"]=id
	SaveManager.save_to_disk()
	if is_instance_valid(loom):
		loom.call("mark_activated")
	if id=="truth":
		# The choice physically rewrites the Cradle Court: a permanent shortcut manifests.
		_add_truth_shortcut()
		hud.show_notice("THE WORLD ACCEPTS THE WOUND","A shortcut becomes solid where no bridge existed. The Veilbound did not merely protect memory — they curated it.",3.6)
	else:
		# Mercy is not cosmetic: Heartglass permanently becomes a little harder to break.
		player.max_health = maxi(player.max_health, 7)
		player.health = player.max_health
		SaveManager.data["max_health"] = player.max_health
		SaveManager.data["health"] = player.health
		SaveManager.save_to_disk()
		player.health_changed.emit(player.health, player.max_health)
		hud.show_notice("THE WORLD ACCEPTS THE MERCY","Heartglass thickens around Seren's pulse. Maximum health increased.",3.6)

func toggle_pause()->void:
	if is_instance_valid(pause_menu):
		pause_menu.toggle()
