extends CanvasLayer

var joystick_touch := -1
var joystick_origin := Vector2.ZERO
var joystick_base: Panel
var joystick_knob: Panel
var active_actions: Dictionary = {}
var touch_opacity := 0.78

func _ready() -> void:
	layer=100
	visible = OS.get_name()=="Android" or DisplayServer.is_touchscreen_available()
	if not visible:
		return
	_build()

func _circle_style(color:Color)->StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=color
	s.corner_radius_top_left=60
	s.corner_radius_top_right=60
	s.corner_radius_bottom_left=60
	s.corner_radius_bottom_right=60
	s.border_width_left=2
	s.border_width_top=2
	s.border_width_right=2
	s.border_width_bottom=2
	s.border_color=Color(0.8,0.2,0.3,color.a*.7)
	return s

func _build() -> void:
	touch_opacity=float(SaveManager.data.get("settings",{}).get("touch_opacity",.78))
	var opacity:=touch_opacity
	joystick_base=Panel.new()
	joystick_base.size=Vector2(150,150)
	joystick_base.position=Vector2(60,510)
	joystick_base.add_theme_stylebox_override("panel",_circle_style(Color(0.16,0.04,0.08,0.34*opacity)))
	add_child(joystick_base)
	joystick_knob=Panel.new()
	joystick_knob.size=Vector2(68,68)
	joystick_knob.position=Vector2(41,41)
	joystick_knob.add_theme_stylebox_override("panel",_circle_style(Color(0.72,0.04,0.12,0.55*opacity)))
	joystick_base.add_child(joystick_knob)
	_add_btn("JUMP","jump",Vector2(-126,-188),74)
	_add_btn("ATK","attack",Vector2(-220,-125),82)
	_add_btn("DASH","dash",Vector2(-116,-96),68)
	_add_btn("CHAIN","grapple",Vector2(-318,-78),70)
	_add_btn("PARRY","parry",Vector2(-313,-170),62)
	_add_btn("MASK","mask_cycle",Vector2(-410,-122),56)
	_add_btn("USE","interact",Vector2(-405,-54),52)
	_add_btn("II","pause",Vector2(-62,18),44,true)

func _add_btn(text:String,action:String,offset:Vector2,diameter:float,top:=false)->void:
	var b:=Button.new()
	b.text=text
	b.custom_minimum_size=Vector2(diameter,diameter)
	b.anchor_left=1
	b.anchor_right=1
	b.anchor_top=0 if top else 1
	b.anchor_bottom=0 if top else 1
	b.offset_left=offset.x-diameter
	b.offset_right=offset.x
	b.offset_top=offset.y-diameter if not top else offset.y
	b.offset_bottom=offset.y if not top else offset.y+diameter
	b.add_theme_font_size_override("font_size",11 if diameter<65 else 12)
	b.add_theme_stylebox_override("normal",_circle_style(Color(0.16,0.03,0.07,0.58*touch_opacity)))
	b.add_theme_stylebox_override("pressed",_circle_style(Color(0.7,0.03,0.12,0.78*touch_opacity)))
	b.button_down.connect(_press_action.bind(action))
	b.button_up.connect(_release_action.bind(action))
	add_child(b)

func _input(event:InputEvent)->void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var e:=event as InputEventScreenTouch
		if e.pressed and joystick_touch==-1 and e.position.x<get_viewport().get_visible_rect().size.x*.42 and e.position.y>get_viewport().get_visible_rect().size.y*.45:
			joystick_touch=e.index
			joystick_origin=e.position
			joystick_base.global_position = joystick_origin - joystick_base.size * 0.5
			joystick_knob.position=Vector2(41,41)
			_update_joystick(e.position)
		elif not e.pressed and e.index==joystick_touch:
			_reset_joystick()
	elif event is InputEventScreenDrag:
		var e:=event as InputEventScreenDrag
		if e.index==joystick_touch:
			_update_joystick(e.position)

func _update_joystick(pos:Vector2)->void:
	var delta:=pos-joystick_origin
	if delta.length()>62:
		delta=delta.normalized()*62
	joystick_knob.position=Vector2(41,41)+delta
	_set_axis("move_left",delta.x<-18)
	_set_axis("move_right",delta.x>18)
	_set_axis("move_down",delta.y>32)

func _set_axis(action:String,pressed:bool)->void:
	var old:=bool(active_actions.get(action,false))
	if pressed and not old:
		Input.action_press(action)
		active_actions[action]=true
	elif not pressed and old:
		Input.action_release(action)
		active_actions[action]=false

func _reset_joystick()->void:
	joystick_touch=-1
	joystick_knob.position=Vector2(41,41)
	joystick_base.position=Vector2(60,510)
	for a in ["move_left","move_right","move_down"]:
		Input.action_release(a)
		active_actions[a]=false

func _press_action(action: String) -> void:
	Input.action_press(action)

func _release_action(action: String) -> void:
	Input.action_release(action)
