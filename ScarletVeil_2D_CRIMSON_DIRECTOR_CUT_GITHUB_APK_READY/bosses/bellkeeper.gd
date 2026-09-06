extends CharacterBody2D

signal boss_health(current: int, maximum: int)
signal defeated
const SHOCKWAVE := preload("res://bosses/Shockwave.tscn")
const GRAVITY := 1800.0
var max_health:=34
var health:=34
var target: Node2D
var facing:=-1.0
var state:="dormant"
var state_timer:=0.0
var attack_index:=0
var defending:=false
var stun_timer:=0.0
var dead:=false
var flash:=0.0
var arena_center:=6200.0

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("boss")
	collision_layer=1
	collision_mask=1
	var c:=CollisionShape2D.new()
	var cap:=CapsuleShape2D.new()
	cap.radius=31.0
	cap.height=92.0
	c.shape=cap
	c.position=Vector2(0,-8)
	add_child(c)
	boss_health.emit(health,max_health)
	queue_redraw()

func _draw() -> void:
	# giant layered armor and warning bell motif
	var armor:=Color.WHITE if flash>0 else Color("33272b")
	draw_colored_polygon(PackedVector2Array([Vector2(-32,-48),Vector2(30,-48),Vector2(42,28),Vector2(19,53),Vector2(-30,47),Vector2(-45,10)]),armor)
	draw_colored_polygon(PackedVector2Array([Vector2(-25,-57),Vector2(25,-57),Vector2(31,-33),Vector2(0,-18),Vector2(-31,-33)]),Color("ddd1c8"))
	draw_line(Vector2(-20,-39),Vector2(20,-39),Color("8d0c23"),4)
	draw_circle(Vector2(0,1),18,Color("6d1323"))
	draw_arc(Vector2(0,1),14,0,TAU,24,Color("e43a50"),3)
	draw_line(Vector2(29,-4),Vector2(62*facing,20),Color("b7aaa2"),7)
	draw_line(Vector2(61*facing,20),Vector2(75*facing,-28),Color("ece3dc"),5)
	if defending:
		draw_arc(Vector2(0,-5),58,-1.4,1.4,30,Color(0.95,0.2,0.32,0.75),6)
	if state == "sword_windup":
		draw_line(Vector2(25*facing,-8),Vector2(104*facing,18),Color(1.0,0.1,0.18,0.75),4.0)
	elif state == "bell_windup":
		draw_arc(Vector2(0,1),42,0,TAU,32,Color(1.0,0.08,0.18,0.68),4.0)
	elif state == "slam_windup":
		draw_arc(Vector2(0,38),88,PI,TAU,28,Color(0.95,0.05,0.14,0.6),4.0)

func _physics_process(delta: float) -> void:
	if dead:
		return
	# Stay inert until World.start_battle() is called when Seren enters Bell Court.
	if state == "dormant":
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		else:
			velocity.x = 0.0
		move_and_slide()
		queue_redraw()
		return
	flash=maxf(flash-delta,0.0)
	stun_timer=maxf(stun_timer-delta,0.0)
	if not is_on_floor():
		velocity.y += GRAVITY*delta
	if stun_timer>0.0:
		velocity.x=move_toward(velocity.x,0.0,700.0*delta)
		move_and_slide()
		queue_redraw()
		return
	target=get_tree().get_first_node_in_group("player") as Node2D
	state_timer-=delta
	if is_instance_valid(target):
		facing=signf(target.global_position.x-global_position.x) if absf(target.global_position.x-global_position.x)>4 else facing
	match state:
		"intro":
			velocity.x=0
			if state_timer<=0:
				_choose_attack()
		"chase":
			if is_instance_valid(target):
				velocity.x=move_toward(velocity.x,facing*118.0,420.0*delta)
			if state_timer<=0:
				_choose_attack()
		"sword_windup":
			velocity.x=move_toward(velocity.x,0.0,900.0*delta)
			if state_timer<=0:
				_do_sword()
		"slam_windup":
			velocity.x=0
			if state_timer<=0:
				_do_slam()
		"bell_windup":
			velocity.x=0
			if state_timer<=0:
				_do_bell()
		"bell_recover":
			velocity.x=0
		"defend":
			velocity.x=0
			if state_timer<=0:
				defending=false
				_set_chase(0.7)
	move_and_slide()
	queue_redraw()

func start_battle() -> void:
	state="intro"
	state_timer=1.25
	AudioManager.play_voice("res://assets/audio/voice_bellkeeper.wav")
	AudioManager.play_sfx("res://assets/audio/bell.wav",-8.0)

func _choose_attack() -> void:
	attack_index=(attack_index+1)%5
	if health<max_health/2 and attack_index==0:
		_start_defend()
		return
	if attack_index in [0,3]:
		state="sword_windup"
		state_timer=0.38
	elif attack_index==1:
		state="bell_windup"
		state_timer=0.78
	elif attack_index==2:
		state="slam_windup"
		state_timer=0.62
	else:
		_set_chase(1.0)

func _set_chase(time: float) -> void:
	state="chase"
	state_timer=time

func _do_sword() -> void:
	if is_instance_valid(target) and global_position.distance_to(target.global_position)<128.0:
		target.call("take_damage",2,global_position,self)
	velocity.x=facing*220.0
	AudioManager.play_sfx("res://assets/audio/heavy_slash.wav",-3.0,0.8)
	_screen_shake(5.0,0.12)
	_set_chase(0.65)

func _do_bell() -> void:
	# Leave the windup state immediately so the async second pulse cannot retrigger every physics frame.
	state="bell_recover"
	state_timer=0.4
	AudioManager.play_sfx("res://assets/audio/bell.wav",-2.0)
	_spawn_wave(-1.0)
	_spawn_wave(1.0)
	_screen_shake(10.0,0.28)
	# delayed second pulse below half health
	if health<max_health/2:
		await get_tree().create_timer(0.28, false).timeout
		if not dead:
			_spawn_wave(-1.0)
			_spawn_wave(1.0)
	if not dead:
		_set_chase(0.8)

func _do_slam() -> void:
	if is_instance_valid(target) and global_position.distance_to(target.global_position)<150.0:
		target.call("take_damage",2,global_position,self)
	_spawn_wave(-1.0)
	_spawn_wave(1.0)
	_screen_shake(13.0,0.32)
	AudioManager.play_sfx("res://assets/audio/bell.wav",-7.0,1.35)
	_set_chase(0.9)

func _start_defend() -> void:
	defending=true
	state="defend"
	state_timer=1.45

func _spawn_wave(dir: float) -> void:
	var w=SHOCKWAVE.instantiate()
	w.direction=dir
	w.global_position=global_position+Vector2(dir*55.0,34.0)
	get_parent().add_child(w)

func take_damage(amount: int, knockback: Vector2, _attacker=null) -> void:
	if dead:
		return
	var applied:=maxi(1,int(ceil(amount*(0.28 if defending else 1.0))))
	health-=applied
	flash=0.10
	if not defending:
		velocity+=knockback*0.28
		stun_timer=0.09
	boss_health.emit(maxi(health,0),max_health)
	queue_redraw()
	if health<=0:
		_die()

func parried() -> void:
	defending=false
	state="chase"
	state_timer=1.15
	stun_timer=1.15
	velocity=Vector2(-facing*300.0,-150.0)

func _screen_shake(strength: float,duration: float) -> void:
	var p:=get_tree().get_first_node_in_group("player")
	if is_instance_valid(p) and p.has_method("shake"):
		p.call("shake",strength,duration)

func _die() -> void:
	dead=true
	remove_from_group("damageable")
	SaveManager.data["bosses_defeated"]["bellkeeper"]=true
	SaveManager.save_to_disk()
	defeated.emit()
	AudioManager.play_voice("res://assets/audio/voice_command.wav")
	var t:=create_tween()
	t.tween_property(self,"modulate",Color(0.85,0.04,0.08,0.0),1.1)
	t.parallel().tween_property(self,"rotation",0.38,1.1)
	await t.finished
	queue_free()
