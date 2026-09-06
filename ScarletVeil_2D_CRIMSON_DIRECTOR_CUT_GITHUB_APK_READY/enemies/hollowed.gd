extends CharacterBody2D

@export var variant := "guardian"
const GRAVITY := 1750.0
var max_health := 4
var health := 4
var speed := 92.0
var target: Node2D
var facing := -1.0
var attack_cooldown := 0.0
var windup := 0.0
var stun_timer := 0.0
var patrol_origin := 0.0
var patrol_span := 125.0
var dead := false
var flash_timer := 0.0

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("enemies")
	add_to_group("grapple_enemy")
	collision_layer = 1
	collision_mask = 1
	patrol_origin = global_position.x
	if variant == "mourner":
		max_health=3
		health=3
		speed=118.0
	elif variant == "warden":
		max_health=6
		health=6
		speed=72.0
	_build_collision()
	queue_redraw()

func _build_collision() -> void:
	var c := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius=17.0
	capsule.height=52.0
	c.shape=capsule
	c.position=Vector2(0,-2)
	add_child(c)

func _draw() -> void:
	var main := Color("28141b") if variant != "mourner" else Color("35131d")
	if variant == "warden":
		main=Color("201a20")
	draw_colored_polygon(PackedVector2Array([Vector2(-17,-27),Vector2(15,-25),Vector2(22,18),Vector2(8,34),Vector2(-15,29),Vector2(-23,8)]),main)
	if variant == "warden":
		draw_rect(Rect2(-20,-21,40,31),Color("3d343b"))
		draw_line(Vector2(-18,-8),Vector2(18,-8),Color("7f2736"),4)
	elif variant == "mourner":
		draw_arc(Vector2(0,-13),18,PI,TAU,16,Color("9b1730"),5)
		draw_circle(Vector2(0,17),9,Color("16070b"))
	else:
		draw_line(Vector2(-14,-13),Vector2(14,-11),Color("8c2534"),4)
		draw_line(Vector2(-16,8),Vector2(16,10),Color("5f1a28"),3)
	var eye_col := Color.WHITE if flash_timer>0.0 else Color("f0183b")
	draw_colored_polygon(PackedVector2Array([Vector2(-5,-13),Vector2(8,-12),Vector2(2,-7)]),eye_col)
	# warped arm/weapon
	draw_line(Vector2(15,-4),Vector2(31*facing,10),Color("a88f87"),4)
	# Strong pre-attack silhouette: fair timing matters more than surprise damage.
	if windup > 0.0:
		draw_arc(Vector2(12*facing,-4),30,-1.0 if facing>0 else PI-1.0,0.75 if facing>0 else PI+0.75,18,Color(0.98,0.08,0.18,0.8),3.0)

func _physics_process(delta: float) -> void:
	if dead:
		return
	flash_timer=maxf(flash_timer-delta,0.0)
	windup=maxf(windup-delta,0.0)
	stun_timer=maxf(stun_timer-delta,0.0)
	attack_cooldown=maxf(attack_cooldown-delta,0.0)
	if not is_on_floor():
		velocity.y += GRAVITY*delta
	if stun_timer>0.0:
		velocity.x=move_toward(velocity.x,0.0,650.0*delta)
		move_and_slide()
		queue_redraw()
		return
	target=get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(target):
		var off:=target.global_position-global_position
		if absf(off.x)<410.0 and absf(off.y)<140.0:
			facing=signf(off.x) if absf(off.x)>3.0 else facing
			if absf(off.x)>58.0:
				velocity.x=move_toward(velocity.x,facing*speed,520.0*delta)
			else:
				velocity.x=move_toward(velocity.x,0.0,900.0*delta)
				_try_attack()
		else:
			_patrol(delta)
	else:
		_patrol(delta)
	move_and_slide()
	queue_redraw()

func _patrol(delta: float) -> void:
	if global_position.x<patrol_origin-patrol_span:
		facing=1.0
	elif global_position.x>patrol_origin+patrol_span:
		facing=-1.0
	velocity.x=move_toward(velocity.x,facing*speed*0.48,260.0*delta)

func _try_attack() -> void:
	if attack_cooldown>0.0:
		return
	attack_cooldown = 1.15 if variant!="mourner" else 0.85
	windup = 0.28 if variant!="warden" else 0.42
	queue_redraw()
	var tree:=get_tree()
	await tree.create_timer(windup, false).timeout
	windup = 0.0
	if dead or stun_timer>0.0:
		return
	var p:=tree.get_first_node_in_group("player") as Node2D
	if is_instance_valid(p) and global_position.distance_to(p.global_position)<76.0:
		p.call("take_damage",2 if variant=="warden" else 1,global_position,self)

func take_damage(amount: int, knockback: Vector2, _attacker=null) -> void:
	if dead:
		return
	health-=amount
	velocity=knockback+Vector2(0,-90)
	stun_timer=0.22
	flash_timer=0.10
	queue_redraw()
	if health<=0:
		_die()

func grapple_pull(force: Vector2) -> void:
	if dead:
		return
	velocity += force
	stun_timer=maxf(stun_timer,0.08)

func parried() -> void:
	stun_timer=1.05
	velocity=Vector2(-facing*260.0,-160.0)
	AudioManager.play_sfx("res://assets/audio/parry.wav",-8.0)

func _die() -> void:
	dead=true
	remove_from_group("damageable")
	remove_from_group("grapple_enemy")
	var t:=create_tween()
	t.tween_property(self,"modulate",Color(0.75,0.02,0.06,0.0),0.32)
	t.parallel().tween_property(self,"scale",Vector2(1.35,0.45),0.32)
	await t.finished
	queue_free()
