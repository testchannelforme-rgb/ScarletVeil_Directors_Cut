extends CharacterBody2D

signal boss_health(current: int, maximum: int)
signal defeated

const ORB_SCENE := preload("res://bosses/VeilOrb.tscn")
const ENEMY_SCENE := preload("res://enemies/Hollowed.tscn")
const SHOCKWAVE := preload("res://bosses/Shockwave.tscn")
const GRAVITY := 1750.0

var max_health := 32
var health := 32
var state := "dormant"
var state_timer := 0.0
var target: Node2D
var facing := -1.0
var attack_index := 0
var dead := false
var defending := false
var flash := 0.0
var phase_two := false
var summoned_once := false

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("boss")
	collision_layer = 1
	collision_mask = 1
	var c := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 28.0
	cap.height = 82.0
	c.shape = cap
	c.position = Vector2(0, -5)
	add_child(c)
	boss_health.emit(health, max_health)
	queue_redraw()

func _draw() -> void:
	var cloth := Color.WHITE if flash > 0.0 else Color("3a1822")
	# Bent Hollowed silhouette wrapped around an empty cradle.
	draw_colored_polygon(PackedVector2Array([Vector2(-31,-40),Vector2(22,-46),Vector2(38,18),Vector2(14,49),Vector2(-30,42),Vector2(-43,7)]), cloth)
	draw_circle(Vector2(-8,-52), 18.0, Color("d0c3bd"))
	draw_line(Vector2(-18,-54),Vector2(4,-49),Color("7b0a22"),3.0)
	# Empty cradle held against her chest.
	draw_colored_polygon(PackedVector2Array([Vector2(-27,-6),Vector2(26,-8),Vector2(20,18),Vector2(-21,20)]),Color("2a171d"))
	draw_arc(Vector2(0,-5),25,PI,TAU,20,Color("a43145"),3)
	# Veil tendrils.
	for i in range(3):
		var off := float(i-1)*9.0
		draw_line(Vector2(off,35),Vector2(off*2.0,61+absf(off)*0.3),Color(0.7,0.02,0.09,0.45),4)
	if defending:
		draw_arc(Vector2(0,-5),55,0,TAU,36,Color(0.84,0.06,0.16,0.62),5)
	if state == "lullaby":
		for i in range(3):
			var a := TAU * float(i) / 3.0 + state_timer * 4.0
			draw_circle(Vector2(cos(a),sin(a))*39.0 + Vector2(0,-18),4.0,Color(0.95,0.08,0.18,0.78))
	elif state == "grief":
		draw_arc(Vector2(0,35),72,PI,TAU,28,Color(1.0,0.08,0.18,0.72),4.0)

func start_battle() -> void:
	state = "intro"
	state_timer = 1.25
	AudioManager.play_voice("res://assets/audio/voice_mother_thren.wav")

func _physics_process(delta: float) -> void:
	if dead:
		return
	flash = maxf(flash-delta, 0.0)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if state == "dormant":
		velocity.x = 0.0
		move_and_slide()
		return
	target = get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(target):
		var dx := target.global_position.x - global_position.x
		if absf(dx) > 2.0:
			facing = signf(dx)
	state_timer -= delta
	if not phase_two and health <= max_health / 2:
		phase_two = true
		_enter_grief_phase()
	match state:
		"intro":
			velocity.x = 0.0
			if state_timer <= 0.0:
				_choose_attack()
		"stalk":
			if is_instance_valid(target):
				velocity.x = move_toward(velocity.x, facing * (105.0 if not phase_two else 135.0), 440.0*delta)
			if state_timer <= 0.0:
				_choose_attack()
		"lullaby":
			velocity.x = 0.0
			if state_timer <= 0.0:
				_fire_lullaby()
		"grief":
			velocity.x = 0.0
			if state_timer <= 0.0:
				_grief_burst()
		"summon":
			velocity.x = 0.0
			if state_timer <= 0.0:
				_summon_children()
		"shield":
			velocity.x = 0.0
			if state_timer <= 0.0:
				defending = false
				state = "stalk"
				state_timer = 0.65
	move_and_slide()
	queue_redraw()

func _choose_attack() -> void:
	attack_index = (attack_index + 1) % 5
	if attack_index == 0 or (phase_two and attack_index == 3):
		state = "lullaby"
		state_timer = 0.62
	elif attack_index == 1:
		state = "grief"
		state_timer = 0.5
	elif attack_index == 2 and not summoned_once:
		state = "summon"
		state_timer = 0.7
	else:
		state = "stalk"
		state_timer = 1.0

func _fire_lullaby() -> void:
	if not is_instance_valid(target):
		_choose_attack()
		return
	var base_dir := (target.global_position - global_position).normalized()
	var count := 5 if phase_two else 3
	for i in range(count):
		var spread := (float(i) - float(count-1)*0.5) * 0.16
		var dir := base_dir.rotated(spread)
		_spawn_orb(global_position + Vector2(facing*32,-24), dir * (290.0 if phase_two else 245.0))
	AudioManager.play_sfx("res://assets/audio/memory_pickup.wav", -10.0, 0.72)
	state = "stalk"
	state_timer = 0.75

func _grief_burst() -> void:
	for dir in [-1.0, 1.0]:
		var w = SHOCKWAVE.instantiate()
		w.direction = dir
		w.global_position = global_position + Vector2(dir*44, 36)
		get_parent().add_child(w)
	if is_instance_valid(target) and global_position.distance_to(target.global_position) < 125.0:
		target.call("take_damage", 2, global_position, self)
	AudioManager.play_sfx("res://assets/audio/heartbeat.wav", -8.0, 0.8)
	_screen_shake(8.0,0.18)
	state = "stalk"
	state_timer = 0.8

func _summon_children() -> void:
	summoned_once = true
	for off in [-115.0, 120.0]:
		var e = ENEMY_SCENE.instantiate()
		e.variant = "mourner"
		e.global_position = global_position + Vector2(off, 0)
		get_parent().add_child(e)
	state = "stalk"
	state_timer = 0.9

func _enter_grief_phase() -> void:
	defending = true
	state = "shield"
	state_timer = 1.7
	for i in range(7):
		var a := TAU * float(i) / 7.0
		_spawn_orb(global_position, Vector2(cos(a),sin(a))*185.0)
	_screen_shake(10.0,0.22)

func _spawn_orb(pos: Vector2, vel: Vector2) -> void:
	var o = ORB_SCENE.instantiate()
	o.global_position = pos
	o.velocity = vel
	o.damage = 1
	o.source = self
	get_parent().add_child(o)

func take_damage(amount: int, knockback: Vector2, _attacker=null) -> void:
	if dead:
		return
	var applied := maxi(1, int(ceil(amount * (0.25 if defending else 1.0))))
	health -= applied
	flash = 0.1
	if not defending:
		velocity += knockback * 0.18
	boss_health.emit(maxi(health,0),max_health)
	queue_redraw()
	if health <= 0:
		_die()

func parried() -> void:
	defending = false
	state = "stalk"
	state_timer = 1.25
	velocity = Vector2(-facing*260,-160)

func _screen_shake(strength:float,duration:float)->void:
	var p = get_tree().get_first_node_in_group("player")
	if is_instance_valid(p) and p.has_method("shake"):
		p.call("shake",strength,duration)

func _die() -> void:
	dead = true
	remove_from_group("damageable")
	SaveManager.data["bosses_defeated"]["mother_thren"] = true
	SaveManager.save_to_disk()
	defeated.emit()
	var t := create_tween()
	t.tween_property(self,"modulate",Color(0.78,0.02,0.08,0.0),1.0)
	t.parallel().tween_property(self,"scale",Vector2(1.15,0.72),1.0)
	await t.finished
	queue_free()
