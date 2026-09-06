extends CharacterBody2D

const ORB_SCENE := preload("res://bosses/VeilOrb.tscn")
var health := 3
var target: Node2D
var cooldown := 0.7
var t := 0.0
var dead := false
var stun := 0.0
var origin_y := 0.0
var flash := 0.0

func _ready()->void:
	add_to_group("damageable")
	add_to_group("enemies")
	add_to_group("grapple_enemy")
	collision_layer=1
	collision_mask=0
	origin_y=global_position.y
	var c:=CollisionShape2D.new()
	var s:=CircleShape2D.new()
	s.radius=17
	c.shape=s
	add_child(c)
	queue_redraw()

func _physics_process(delta:float)->void:
	if dead:
		return
	t += delta
	flash=maxf(flash-delta,0.0)
	stun=maxf(stun-delta,0.0)
	cooldown=maxf(cooldown-delta,0.0)
	global_position = Vector2(global_position.x, origin_y + sin(t * 1.8) * 16.0)
	target=get_tree().get_first_node_in_group("player") as Node2D
	if stun<=0.0 and is_instance_valid(target):
		var off:=target.global_position-global_position
		if off.length()<470.0:
			velocity.x=move_toward(velocity.x,signf(off.x)*52.0,110.0*delta)
			if cooldown<=0.0:
				_fire(off.normalized())
		else:
			velocity.x=move_toward(velocity.x,0.0,90.0*delta)
	else:
		velocity.x=move_toward(velocity.x,0.0,180.0*delta)
	move_and_slide()
	queue_redraw()

func _fire(dir:Vector2)->void:
	cooldown=1.25
	var o = ORB_SCENE.instantiate()
	get_parent().add_child(o)
	o.global_position = global_position
	o.velocity = dir * 250.0
	o.damage = 1
	o.source = self
	AudioManager.play_sfx("res://assets/audio/memory_pickup.wav",-14.0,1.25)

func _draw()->void:
	var paper:=Color.WHITE if flash>0 else Color("d4c8bd")
	draw_colored_polygon(PackedVector2Array([Vector2(-25,-18),Vector2(18,-22),Vector2(27,7),Vector2(4,23),Vector2(-22,13)]),Color("171118"))
	draw_colored_polygon(PackedVector2Array([Vector2(-18,-12),Vector2(14,-15),Vector2(17,7),Vector2(-15,10)]),paper)
	draw_circle(Vector2(2,-3),5,Color("c80e32"))
	for i in range(4):
		var a:=t*0.8+i*PI*.5
		draw_line(Vector2(0,10),Vector2(cos(a)*28,18+sin(a)*10),Color(0.45,0.02,0.08,0.5),2)

func take_damage(amount:int,knockback:Vector2,_attacker=null)->void:
	if dead:
		return
	health-=amount
	flash=.1
	velocity+=knockback*.4
	stun=.2
	if health <= 0:
		_die()

func grapple_pull(force:Vector2)->void:
	velocity+=force
	stun=maxf(stun,.08)

func parried()->void:
	stun=1.0
	velocity=Vector2.ZERO

func _die()->void:
	dead=true
	remove_from_group("damageable")
	remove_from_group("grapple_enemy")
	var tw:=create_tween()
	tw.tween_property(self,"modulate:a",0.0,.28)
	tw.parallel().tween_property(self,"scale",Vector2(1.7,.2),.28)
	await tw.finished
	queue_free()
