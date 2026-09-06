extends CharacterBody2D

signal boss_health(current: int, maximum: int)
signal defeated

const ORB_SCENE := preload("res://bosses/VeilOrb.tscn")
const ENEMY_SCENE := preload("res://enemies/Hollowed.tscn")
const GRAVITY := 1750.0

var max_health := 46
var health := 46
var target: Node2D
var facing := -1.0
var state := "dormant"
var state_timer := 0.0
var attack_index := 0
var phase := 1
var dead := false
var flash := 0.0
var invuln := 0.0
var arena_left := 8650.0
var arena_right := 9700.0

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("boss")
	collision_layer = 1
	collision_mask = 1
	var c := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 22.0
	cap.height = 72.0
	c.shape = cap
	c.position = Vector2(0,-4)
	add_child(c)
	boss_health.emit(health,max_health)
	queue_redraw()

func _draw() -> void:
	var pale := Color.WHITE if flash>0.0 else Color("ddd2cb")
	# Long ceremonial silhouette.
	draw_colored_polygon(PackedVector2Array([Vector2(-18,-36),Vector2(18,-36),Vector2(24,40),Vector2(0,55),Vector2(-25,38)]),Color("29151c"))
	draw_colored_polygon(PackedVector2Array([Vector2(-13,-36),Vector2(13,-36),Vector2(15,23),Vector2(-13,23)]),pale)
	# Cracked porcelain crown.
	draw_colored_polygon(PackedVector2Array([Vector2(-15,-50),Vector2(-9,-68),Vector2(-1,-55),Vector2(6,-72),Vector2(15,-50)]),Color("e4d9d2"))
	draw_line(Vector2(1,-68),Vector2(-5,-55),Color("7b1829"),2)
	draw_line(Vector2(-4,-55),Vector2(5,-43),Color("7b1829"),2)
	# Blade.
	draw_line(Vector2(13,-8),Vector2(64*facing,18),Color("eee6df"),5)
	draw_line(Vector2(52*facing,12),Vector2(72*facing,-34),Color("f7eee7"),3)
	# Veil halo grows each phase.
	if phase >= 2:
		draw_arc(Vector2(0,-20),38,0,TAU,30,Color(0.77,0.02,0.1,0.38),2+phase)
	# Telegraphs are deliberately bright: difficult attacks should still feel readable on a phone screen.
	if state == "lunge_windup":
		draw_line(Vector2(18*facing,-4),Vector2(105*facing,10),Color(1.0,0.12,0.2,0.72),3.0)
	elif state == "veil_windup":
		draw_arc(Vector2(0,-18),55,0,TAU,36,Color(0.95,0.04,0.18,0.68),4.0)
	elif state == "vanish":
		draw_arc(Vector2.ZERO,64,0,TAU,36,Color(0.82,0.02,0.1,0.35),2.0)

func start_battle() -> void:
	state = "intro"
	state_timer = 1.5
	AudioManager.play_voice("res://assets/audio/voice_regent_intro.wav")

func _physics_process(delta:float)->void:
	if dead:
		return
	flash=maxf(flash-delta,0.0)
	invuln=maxf(invuln-delta,0.0)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if state=="dormant":
		velocity.x=0
		move_and_slide()
		return
	target=get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(target):
		var dx:=target.global_position.x-global_position.x
		if absf(dx) > 3:
			facing = signf(dx)
	state_timer-=delta
	var new_phase := 3 if health <= 14 else (2 if health <= 30 else 1)
	if new_phase != phase:
		phase = new_phase
		_phase_transition()
	match state:
		"intro":
			velocity.x=0
			if state_timer <= 0:
				_choose_attack()
		"chase":
			velocity.x=move_toward(velocity.x,facing*(125.0+phase*18.0),620.0*delta)
			if state_timer <= 0:
				_choose_attack()
		"lunge_windup":
			velocity.x=move_toward(velocity.x,0.0,1200.0*delta)
			if state_timer <= 0:
				_lunge()
		"veil_windup":
			velocity.x=0
			if state_timer <= 0:
				_veil_fan()
		"vanish":
			velocity.x=0
			if state_timer <= 0:
				_reappear()
	move_and_slide()
	global_position=Vector2(clampf(global_position.x,arena_left,arena_right),global_position.y)
	queue_redraw()

func _choose_attack()->void:
	attack_index=(attack_index+1)%6
	if attack_index in [0,3]:
		state="lunge_windup"
		state_timer=0.28 if phase>=2 else 0.38
	elif attack_index in [1,4] and phase>=2:
		state="veil_windup"
		state_timer=0.46
	elif attack_index==2 and phase>=2:
		state="vanish"
		state_timer=0.28
		modulate.a=0.18
		invuln=0.4
	else:
		state="chase"
		state_timer=0.75

func _lunge()->void:
	velocity.x=facing*(650.0 if phase==1 else 760.0)
	if is_instance_valid(target) and global_position.distance_to(target.global_position)<145.0:
		target.call("take_damage",2,global_position,self)
	AudioManager.play_sfx("res://assets/audio/heavy_slash.wav",-3.0,1.08+phase*.06)
	_screen_shake(5.0,0.1)
	state="chase"
	state_timer=0.52

func _veil_fan()->void:
	if not is_instance_valid(target):
		_choose_attack()
		return
	var base:=(target.global_position-global_position).normalized()
	var count:=7 if phase>=3 else 5
	for i in range(count):
		var spread:=(float(i)-float(count-1)*0.5)*0.15
		_spawn_orb(global_position+Vector2(0,-24),base.rotated(spread)*(330.0+phase*25.0))
	state="chase"
	state_timer=0.7

func _reappear()->void:
	if is_instance_valid(target):
		var side := -signf(target.global_position.x-global_position.x)
		if side == 0:
			side = 1
		global_position = Vector2(clampf(target.global_position.x + side * 210.0, arena_left + 70.0, arena_right - 70.0), global_position.y)
	modulate.a=1.0
	invuln=0.12
	if phase>=3:
		for a in [-0.5,0.0,0.5]:
			_spawn_orb(global_position+Vector2(0,-22),Vector2(facing*260,-70).rotated(a))
	state="lunge_windup"
	state_timer=0.18

func _phase_transition()->void:
	state="intro"
	state_timer=0.65
	invuln=0.6
	_screen_shake(10.0,0.22)
	if phase==3:
		# The Regent externalises borrowed memories as attackers.
		for off in [-150.0,150.0]:
			var e = ENEMY_SCENE.instantiate()
			e.variant = "warden"
			e.position = Vector2(clampf(global_position.x + off, arena_left + 60.0, arena_right - 60.0), global_position.y)
			get_parent().add_child(e)

func _spawn_orb(pos:Vector2,vel:Vector2)->void:
	var o = ORB_SCENE.instantiate()
	get_parent().add_child(o)
	o.global_position = pos
	o.velocity = vel
	o.damage = 1
	o.source = self

func take_damage(amount:int,knockback:Vector2,_attacker=null)->void:
	if dead or invuln > 0.0:
		return
	health-=amount
	flash=.1
	velocity+=knockback*.12
	boss_health.emit(maxi(health,0),max_health)
	if health <= 0:
		_die()

func parried()->void:
	state="chase"
	state_timer=1.15
	invuln=0.0
	velocity=Vector2(-facing*350,-155)

func _screen_shake(strength:float,duration:float)->void:
	var p=get_tree().get_first_node_in_group("player")
	if is_instance_valid(p) and p.has_method("shake"):
		p.call("shake",strength,duration)

func _die()->void:
	dead=true
	remove_from_group("damageable")
	SaveManager.data["bosses_defeated"]["pale_regent"] = true
	SaveManager.save_to_disk()
	defeated.emit()
	AudioManager.play_voice("res://assets/audio/voice_regent.wav")
	var t=create_tween()
	t.tween_property(self,"modulate",Color(0.9,0.06,0.12,0.0),1.25)
	t.parallel().tween_property(self,"scale",Vector2(0.78,1.28),1.25)
	await t.finished
	queue_free()
