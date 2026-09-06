extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal veilfire_changed(current: float, maximum: float)
signal mask_changed(mask_id: String, display_name: String)
signal memory_changed(count: int)
signal ability_unlocked(id: String, display_name: String)
signal flow_changed(current: float, maximum: float)
signal perfect_parry
signal died

const MaskDB = preload("res://masks/mask_data.gd")

const SPEED := 355.0
const GROUND_ACCEL := 2900.0
const AIR_ACCEL := 1900.0
const FRICTION := 3500.0
const GRAVITY := 1900.0
const JUMP_VELOCITY := -635.0
const WALL_JUMP_X := 455.0
const WALL_JUMP_Y := -595.0
const WALL_SLIDE_SPEED := 135.0
const DASH_SPEED := 790.0
const DASH_DURATION := 0.155
const DASH_COOLDOWN := 0.42
const COYOTE_TIME := 0.13
const JUMP_BUFFER := 0.15
const BASE_GRAPPLE_RANGE := 500.0
const GRAPPLE_PULL := 1750.0
const MAX_VEILFIRE := 100.0
const MAX_FLOW := 100.0

var max_health := 6
var health := 6
var veilfire := MAX_VEILFIRE
var facing := 1.0
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var dashing := false
var invulnerability := 0.0
var attack_cooldown := 0.0
var attack_hold := 0.0
var attack_anim := 0.0
var combo_step := 0
var combo_reset := 0.0
var parry_timer := 0.0
var parry_flash := 0.0
var grapple_target: Node2D
var grapple_active := false
var diving := false
var was_on_floor := false
var shake_timer := 0.0
var shake_strength := 0.0
var dash_afterimage_timer := 0.0
var hurt_flash := 0.0
var dead := false
var air_dash_ready := true
var flow := 0.0
var flow_hold := 0.0

var abilities: Dictionary = {
	"wall_jump": false,
	"dash": false,
	"grapple": false,
	"down_strike": false,
	"veil_phase": false
}
var unlocked_masks: Array[String] = ["veilbound"]
var equipped_mask := "veilbound"

var scarf: Line2D
var chain: Line2D
var blade: Line2D
var camera: Camera2D
var glow: Polygon2D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	_build_body()
	load_from_save()
	health_changed.emit(health, max_health)
	veilfire_changed.emit(veilfire, MAX_VEILFIRE)
	flow_changed.emit(flow, MAX_FLOW)
	_emit_mask()
	queue_redraw()

func _build_body() -> void:
	var collider := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 13.5
	capsule.height = 54.0
	collider.shape = capsule
	collider.position = Vector2(0, -2)
	add_child(collider)

	glow = Polygon2D.new()
	glow.polygon = PackedVector2Array([Vector2(-22,-40),Vector2(22,-40),Vector2(32,36),Vector2(-32,36)])
	glow.color = Color(0.75,0.02,0.08,0.055)
	glow.z_index = -3
	add_child(glow)

	scarf = Line2D.new()
	scarf.width = 7.0
	scarf.default_color = Color("b30b27")
	scarf.antialiased = true
	scarf.z_index = -2
	add_child(scarf)

	chain = Line2D.new()
	chain.width = 2.2
	chain.default_color = Color("e21f42")
	chain.antialiased = true
	chain.visible = false
	chain.z_index = -1
	add_child(chain)

	blade = Line2D.new()
	blade.width = 3.0
	blade.default_color = Color("f5eee7")
	blade.antialiased = true
	blade.points = PackedVector2Array([Vector2.ZERO, Vector2(38,0), Vector2(46,-3)])
	blade.position = Vector2(8,4)
	add_child(blade)

	camera = Camera2D.new()
	camera.position = Vector2(95, -70)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.5
	camera.limit_top = -260
	camera.limit_bottom = 760
	camera.limit_left = -220
	camera.limit_right = 10650
	add_child(camera)
	camera.make_current()

func _draw() -> void:
	var mask_def := MaskDB.get_mask(equipped_mask)
	var accent: Color = mask_def["accent"]
	# Cloak / silhouette.
	draw_colored_polygon(PackedVector2Array([Vector2(-17,-8),Vector2(17,-8),Vector2(23,30),Vector2(5,43),Vector2(-22,30)]), Color("2b0711"))
	draw_colored_polygon(PackedVector2Array([Vector2(-10,-15),Vector2(10,-15),Vector2(12,26),Vector2(-12,26)]), Color("120d13"))
	# Shoulder Heartglass clips.
	draw_circle(Vector2(-14,-9),3.5,Color("a30c24"))
	draw_circle(Vector2(14,-9),3.5,Color("a30c24"))
	# Mask shapes visibly differ.
	if equipped_mask == "hunter":
		draw_colored_polygon(PackedVector2Array([Vector2(-13,-34),Vector2(13,-34),Vector2(17,-24),Vector2(8,-11),Vector2(0,-7),Vector2(-8,-11),Vector2(-17,-24)]), accent)
		draw_colored_polygon(PackedVector2Array([Vector2(-13,-31),Vector2(-24,-39),Vector2(-17,-22)]),accent)
		draw_colored_polygon(PackedVector2Array([Vector2(13,-31),Vector2(24,-39),Vector2(17,-22)]),accent)
		draw_line(Vector2(-9,-23),Vector2(-2,-21),Color("650313"),2.5)
		draw_line(Vector2(9,-23),Vector2(2,-21),Color("650313"),2.5)
	elif equipped_mask == "echo":
		draw_circle(Vector2(0,-23),17.0,accent)
		draw_colored_polygon(PackedVector2Array([Vector2(0,-38),Vector2(8,-23),Vector2(0,-7),Vector2(-8,-23)]),Color("6a135e"))
		draw_arc(Vector2(0,-23),9,0,TAU,24,Color("fff0ff"),1.5)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(-12,-35),Vector2(12,-35),Vector2(15,-22),Vector2(0,-8),Vector2(-15,-22)]),accent)
		draw_colored_polygon(PackedVector2Array([Vector2(0,-32),Vector2(5,-21),Vector2(0,-11),Vector2(-5,-21)]),Color("8b0920"))
	# Veilfire eye slit / damage flash.
	var eye_col := Color("ff2347") if hurt_flash <= 0.0 else Color.WHITE
	draw_line(Vector2(-7,-23),Vector2(7,-23),eye_col,1.4)
	# Small boots.
	draw_line(Vector2(-8,28),Vector2(-11,39),Color("0a070a"),6)
	draw_line(Vector2(8,28),Vector2(11,39),Color("0a070a"),6)

func load_from_save() -> void:
	var d: Dictionary = SaveManager.data
	max_health = int(d.get("max_health", 6))
	health = clampi(int(d.get("health", max_health)), 1, max_health)
	veilfire = clampf(float(d.get("veilfire", MAX_VEILFIRE)), 0.0, MAX_VEILFIRE)
	var saved_abilities = d.get("abilities", {})
	if saved_abilities is Dictionary:
		for key in abilities.keys():
			abilities[key] = bool(saved_abilities.get(key, abilities[key]))
	unlocked_masks.clear()
	for mask_id in d.get("masks", ["veilbound"]):
		unlocked_masks.append(str(mask_id))
	if unlocked_masks.is_empty():
		unlocked_masks.append("veilbound")
	equipped_mask = str(d.get("equipped_mask", "veilbound"))
	if not unlocked_masks.has(equipped_mask):
		equipped_mask = unlocked_masks[0]
	queue_redraw()

func _physics_process(delta: float) -> void:
	if dead:
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
		move_and_slide()
		_update_visuals(delta)
		return
	_tick_timers(delta)
	_handle_actions(delta)
	_handle_grapple(delta)
	_handle_movement(delta)
	was_on_floor = is_on_floor()
	move_and_slide()
	if diving and is_on_floor() and not was_on_floor:
		_finish_down_strike()
	_update_visuals(delta)
	_update_camera(delta)

func _tick_timers(delta: float) -> void:
	coyote_timer = maxf(coyote_timer - delta, 0.0)
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	dash_cooldown = maxf(dash_cooldown - delta, 0.0)
	dash_afterimage_timer = maxf(dash_afterimage_timer - delta, 0.0)
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	combo_reset = maxf(combo_reset - delta, 0.0)
	parry_timer = maxf(parry_timer - delta, 0.0)
	parry_flash = maxf(parry_flash - delta, 0.0)
	invulnerability = maxf(invulnerability - delta, 0.0)
	attack_anim = maxf(attack_anim - delta, 0.0)
	hurt_flash = maxf(hurt_flash - delta, 0.0)
	if combo_reset <= 0.0:
		combo_step = 0
	flow_hold = maxf(flow_hold - delta, 0.0)
	if flow_hold <= 0.0 and flow > 0.0:
		var decay := 7.0 if SaveManager.data.get("important_choices", {}).get("mercy_or_truth", "") == "truth" else 10.0
		flow = maxf(0.0, flow - decay * delta)
		flow_changed.emit(flow, MAX_FLOW)
	if not dashing and not grapple_active:
		var regen := 16.0 if flow >= 60.0 else 12.0
		veilfire = minf(MAX_VEILFIRE, veilfire + regen * delta)
		veilfire_changed.emit(veilfire, MAX_VEILFIRE)

func _handle_actions(delta: float) -> void:
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
		attack_hold = 0.0
		if not is_on_floor() and Input.is_action_pressed("move_down") and abilities.get("down_strike", false):
			_start_down_strike()
		else:
			_light_attack()
	if Input.is_action_pressed("attack"):
		attack_hold += delta
		if attack_hold > 0.62 and attack_cooldown <= 0.0 and not diving:
			_heavy_attack()
			attack_hold = -999.0
	if Input.is_action_just_released("attack"):
		attack_hold = 0.0
	if Input.is_action_just_pressed("parry") and parry_timer <= 0.0 and veilfire >= 5.0:
		parry_timer = 0.18
		parry_flash = 0.26
		veilfire -= 5.0
		veilfire_changed.emit(veilfire, MAX_VEILFIRE)
		AudioManager.play_sfx("res://assets/audio/parry.wav", -5.0)
		shake(2.0,0.08)
	if Input.is_action_just_pressed("mask_cycle"):
		cycle_mask()

func _handle_movement(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		air_dash_ready = true
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER
	if dashing:
		dash_timer -= delta
		if dash_afterimage_timer <= 0.0:
			dash_afterimage_timer = 0.035
			_spawn_dash_afterimage()
		if dash_timer <= 0.0:
			dashing = false
		return
	if Input.is_action_just_pressed("dash") and abilities.get("dash", false) and dash_cooldown <= 0.0 and veilfire >= 8.0:
		if is_on_floor() or air_dash_ready:
			_start_dash()
			return
	if diving:
		velocity.y = maxf(velocity.y, 860.0)
		return
	var axis := Input.get_axis("move_left","move_right")
	if absf(axis) > 0.05:
		facing = signf(axis)
		var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
		velocity.x = move_toward(velocity.x, axis * SPEED, accel * delta)
	else:
		var friction := FRICTION if is_on_floor() else AIR_ACCEL * 0.28
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	if not is_on_floor() and not grapple_active:
		var gravity_scale := 1.0
		if absf(velocity.y) < 125.0 and Input.is_action_pressed("jump"):
			gravity_scale = 0.56
		elif velocity.y > 260.0:
			gravity_scale = 1.10
		velocity.y += GRAVITY * gravity_scale * delta
	if is_on_wall() and not is_on_floor() and velocity.y > WALL_SLIDE_SPEED:
		velocity.y = move_toward(velocity.y, WALL_SLIDE_SPEED, GRAVITY * delta * 1.7)
	if jump_buffer_timer > 0.0:
		if coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
		elif is_on_wall() and abilities.get("wall_jump", false):
			var normal := get_wall_normal()
			velocity = Vector2(normal.x * WALL_JUMP_X, WALL_JUMP_Y)
			facing = normal.x
			jump_buffer_timer = 0.0
			AudioManager.play_sfx("res://assets/audio/dash.wav", -15.0, 1.25)
	if Input.is_action_just_released("jump") and velocity.y < -220.0:
		velocity.y *= 0.50

func _start_dash() -> void:
	if not is_on_floor():
		air_dash_ready = false
	dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN
	invulnerability = maxf(invulnerability, 0.13)
	veilfire -= 8.0
	veilfire_changed.emit(veilfire, MAX_VEILFIRE)
	var dir := Input.get_axis("move_left","move_right")
	if absf(dir) < 0.1:
		dir = facing
	var mask := MaskDB.get_mask(equipped_mask)
	var bonus := 1.10 if equipped_mask == "hunter" else 1.0
	velocity = Vector2(signf(dir) * DASH_SPEED * bonus, 0.0)
	AudioManager.play_sfx("res://assets/audio/dash.wav", -6.0)
	shake(2.8,0.10)

func _spawn_dash_afterimage() -> void:
	var ghost := Polygon2D.new()
	ghost.polygon = PackedVector2Array([Vector2(-16,-32),Vector2(16,-32),Vector2(23,28),Vector2(4,42),Vector2(-22,28)])
	ghost.color = Color(0.78,0.015,0.08,0.26)
	ghost.scale.x = facing
	ghost.z_index = -1
	get_parent().add_child(ghost)
	ghost.global_position = global_position
	var tw := ghost.create_tween()
	tw.tween_property(ghost,"modulate:a",0.0,0.16)
	tw.parallel().tween_property(ghost,"scale",Vector2(facing*1.18,0.92),0.16)
	tw.finished.connect(ghost.queue_free)

func _light_attack() -> void:
	combo_step = (combo_step % 3) + 1
	combo_reset = 0.42
	attack_anim = 0.18
	var mask := MaskDB.get_mask(equipped_mask)
	attack_cooldown = (0.16 + combo_step * 0.015) * float(mask["attack_speed"])
	var damage := 1
	var reach := 82.0 if combo_step < 3 else 96.0
	var hits := _damage_arc(damage, reach, 0.15)
	if hits > 0:
		_add_flow(7.0 + combo_step * 2.0)
		GameFX.hitstop(0.025 if combo_step < 3 else 0.04, 0.2)
	AudioManager.play_sfx("res://assets/audio/slash.wav", -7.0, 0.96 + combo_step*0.05)
	_spawn_slash_fx(false)

func _heavy_attack() -> void:
	attack_anim = 0.31
	var mask := MaskDB.get_mask(equipped_mask)
	attack_cooldown = 0.38 * float(mask["attack_speed"])
	var hits := _damage_arc(3, 118.0, 0.32)
	if hits > 0:
		_add_flow(18.0)
		GameFX.hitstop(0.055, 0.12)
	velocity.x -= facing * 65.0
	AudioManager.play_sfx("res://assets/audio/heavy_slash.wav", -3.0)
	_spawn_slash_fx(true)
	shake(5.0,0.13)

func _damage_arc(base_damage: int, reach: float, knock: float) -> int:
	var hit_count := 0
	var mask := MaskDB.get_mask(equipped_mask)
	var damage := maxi(1, int(round(base_damage * float(mask["damage"]))))
	for node in get_tree().get_nodes_in_group("damageable"):
		if not is_instance_valid(node) or node == self or not (node is Node2D):
			continue
		var n := node as Node2D
		var off := n.global_position - global_position
		if off.length() > reach:
			continue
		if absf(off.y) > 72.0:
			continue
		if signf(off.x) != facing and absf(off.x) > 20.0:
			continue
		if node.has_method("take_damage"):
			node.call("take_damage", damage, Vector2(facing * 340.0 * knock, -130.0), self)
			hit_count += 1
	return hit_count

func _spawn_slash_fx(heavy: bool) -> void:
	var line := Line2D.new()
	line.width = 5.0 if heavy else 3.0
	line.default_color = Color(0.95,0.85,0.82,0.82)
	line.antialiased = true
	var pts := PackedVector2Array()
	var r := 62.0 if heavy else 48.0
	for i in range(9):
		var a := lerpf(-0.9,0.75,float(i)/8.0)
		pts.append(Vector2(cos(a)*r*facing, sin(a)*r-5))
	line.points = pts
	line.z_index = 5
	add_child(line)
	var t := create_tween()
	t.tween_property(line,"modulate:a",0.0,0.16 if not heavy else 0.24)
	t.parallel().tween_property(line,"scale",Vector2(1.22,1.22),0.18)
	t.finished.connect(line.queue_free)

func _start_down_strike() -> void:
	diving = true
	attack_anim = 0.3
	velocity = Vector2(velocity.x*0.3, 880.0)
	AudioManager.play_sfx("res://assets/audio/heavy_slash.wav", -8.0, 1.3)

func _finish_down_strike() -> void:
	diving = false
	attack_cooldown = 0.30
	for node in get_tree().get_nodes_in_group("damageable"):
		if is_instance_valid(node) and node is Node2D and node != self:
			var off := (node as Node2D).global_position - global_position
			if off.length() < 110.0 and absf(off.y) < 85.0 and node.has_method("take_damage"):
				node.call("take_damage", 2, Vector2(signf(off.x)*260.0,-230.0), self)
	AudioManager.play_sfx("res://assets/audio/bell.wav", -16.0, 1.8)
	_add_flow(12.0)
	GameFX.hitstop(0.045, 0.14)
	shake(7.0,0.18)

func _handle_grapple(delta: float) -> void:
	if not abilities.get("grapple", false):
		return
	if Input.is_action_just_pressed("grapple") and not grapple_active and veilfire >= 4.0:
		grapple_target = _find_grapple_target()
		if is_instance_valid(grapple_target):
			grapple_active = true
			veilfire -= 4.0
			veilfire_changed.emit(veilfire, MAX_VEILFIRE)
			AudioManager.play_sfx("res://assets/audio/grapple.wav", -5.0)
	if grapple_active:
		if not Input.is_action_pressed("grapple") or not is_instance_valid(grapple_target):
			_stop_grapple()
			return
		veilfire = maxf(0.0, veilfire - 4.0*delta)
		veilfire_changed.emit(veilfire, MAX_VEILFIRE)
		if veilfire <= 0.0:
			_stop_grapple()
			return
		var to_target := grapple_target.global_position - global_position
		var dist := to_target.length()
		var dir := to_target.normalized()
		if grapple_target.is_in_group("grapple_enemy") and grapple_target.has_method("grapple_pull"):
			grapple_target.call("grapple_pull", -dir * 900.0 * delta)
		else:
			velocity += dir * GRAPPLE_PULL * delta
			velocity.y += GRAVITY * 0.18 * delta
			if dist < 135.0:
				var tangent := Vector2(-dir.y,dir.x)
				var input_axis := Input.get_axis("move_left","move_right")
				velocity += tangent * input_axis * 720.0 * delta
				if velocity.dot(dir) > 80.0:
					velocity -= dir * velocity.dot(dir) * 0.45

func _find_grapple_target() -> Node2D:
	var mask := MaskDB.get_mask(equipped_mask)
	var range := BASE_GRAPPLE_RANGE * float(mask["grapple_range"])
	var best: Node2D
	var best_d := range
	for node in get_tree().get_nodes_in_group("grapple_anchor"):
		if node is Node2D and is_instance_valid(node):
			var d := global_position.distance_to((node as Node2D).global_position)
			if d < best_d:
				best_d = d
				best = node as Node2D
	if equipped_mask == "hunter":
		for node in get_tree().get_nodes_in_group("grapple_enemy"):
			if node is Node2D and is_instance_valid(node):
				var d := global_position.distance_to((node as Node2D).global_position)
				if d < minf(best_d,300.0):
					best_d=d
					best=node as Node2D
	return best

func _stop_grapple() -> void:
	if grapple_active and velocity.length() > 360.0:
		velocity *= 1.035
		_add_flow(3.0)
	grapple_active = false
	grapple_target = null
	chain.visible = false

func take_damage(amount: int, source_pos: Vector2, attacker = null) -> void:
	if health <= 0 or invulnerability > 0.0:
		return
	if parry_timer > 0.0:
		parry_timer = 0.0
		veilfire = minf(MAX_VEILFIRE, veilfire + 20.0)
		veilfire_changed.emit(veilfire, MAX_VEILFIRE)
		_add_flow(26.0)
		if is_instance_valid(attacker) and attacker.has_method("parried"):
			attacker.call("parried")
		AudioManager.play_sfx("res://assets/audio/parry.wav", -1.0, 1.18)
		GameFX.hitstop(0.075, 0.08)
		shake(8.0,0.16)
		perfect_parry.emit()
		return
	var defense := float(MaskDB.get_mask(equipped_mask)["defense"])
	var applied := maxi(1, int(ceil(amount * defense)))
	health -= applied
	flow = maxf(0.0, flow - 34.0)
	flow_changed.emit(flow, MAX_FLOW)
	invulnerability = 0.72
	hurt_flash = 0.2
	var away := signf(global_position.x - source_pos.x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away*360.0,-285.0)
	AudioManager.play_sfx("res://assets/audio/hurt.wav", -5.0)
	health_changed.emit(maxi(health,0),max_health)
	queue_redraw()
	shake(7.0,0.18)
	if health <= 0:
		dead = true
		_stop_grapple()
		died.emit()

func _add_flow(amount: float) -> void:
	flow = clampf(flow + amount, 0.0, MAX_FLOW)
	flow_hold = 1.8
	flow_changed.emit(flow, MAX_FLOW)

func collect_memory(memory_id: String) -> bool:
	var arr: Array = SaveManager.data.get("memory_shards", [])
	if arr.has(memory_id):
		return false
	arr.append(memory_id)
	SaveManager.data["memory_shards"] = arr
	memory_changed.emit(arr.size())
	SaveManager.save_to_disk()
	return true

func unlock_ability(id: String, display_name: String) -> bool:
	if bool(abilities.get(id,false)):
		return false
	abilities[id] = true
	SaveManager.data["abilities"][id] = true
	SaveManager.save_to_disk()
	ability_unlocked.emit(id,display_name)
	AudioManager.play_sfx("res://assets/audio/ability.wav", -4.0)
	return true

func unlock_mask(id: String) -> bool:
	if unlocked_masks.has(id):
		return false
	unlocked_masks.append(id)
	SaveManager.data["masks"] = unlocked_masks.duplicate()
	equipped_mask = id
	SaveManager.data["equipped_mask"] = id
	SaveManager.save_to_disk()
	_emit_mask()
	queue_redraw()
	return true

func cycle_mask() -> void:
	if unlocked_masks.size() <= 1:
		return
	var idx := unlocked_masks.find(equipped_mask)
	equipped_mask = unlocked_masks[(idx+1)%unlocked_masks.size()]
	SaveManager.data["equipped_mask"] = equipped_mask
	SaveManager.save_to_disk()
	_emit_mask()
	queue_redraw()
	AudioManager.play_sfx("res://assets/audio/ui_click.wav", -6.0, 1.3)

func _emit_mask() -> void:
	mask_changed.emit(equipped_mask, str(MaskDB.get_mask(equipped_mask)["name"]))

func get_save_snapshot() -> Dictionary:
	return {
		"player_position": [global_position.x,global_position.y],
		"health": maxi(health,1),
		"max_health": max_health,
		"veilfire": veilfire,
		"abilities": abilities.duplicate(true),
		"masks": unlocked_masks.duplicate(),
		"equipped_mask": equipped_mask
	}

func heal_full() -> void:
	dead = false
	health = max_health
	veilfire = MAX_VEILFIRE
	flow = 0.0
	flow_changed.emit(flow, MAX_FLOW)
	health_changed.emit(health,max_health)
	veilfire_changed.emit(veilfire,MAX_VEILFIRE)

func shake(strength: float, duration: float) -> void:
	shake_strength = maxf(shake_strength, strength * float(SaveManager.data.get("settings",{}).get("screen_shake",1.0)))
	shake_timer = maxf(shake_timer,duration)

func _update_visuals(delta: float) -> void:
	var speed_factor := clampf(absf(velocity.x)/SPEED,0.0,1.4)
	var base := Vector2(-7.0*facing,-14)
	var wind := Vector2(-facing*(26+speed_factor*20), 8+sin(Time.get_ticks_msec()*0.008)*4)
	scarf.points = PackedVector2Array([base,base+wind*0.55,base+wind,base+wind*1.45+Vector2(0,5)])
	if grapple_active and is_instance_valid(grapple_target):
		chain.visible = true
		chain.points = PackedVector2Array([Vector2(11*facing,0),to_local(grapple_target.global_position)])
	else:
		chain.visible = false
	var attack_phase := attack_anim / 0.31 if attack_anim > 0 else 0.0
	if attack_anim > 0.0:
		blade.rotation = lerpf(-1.05,0.95,1.0-attack_phase) * facing
	else:
		blade.rotation = -0.2*facing
	blade.scale.x = facing
	glow.modulate.a = 0.6 + sin(Time.get_ticks_msec()*0.004)*0.2
	if parry_flash > 0.0:
		glow.color = Color(0.95,0.85,0.9,0.18)
	else:
		glow.color = Color(0.75,0.02,0.08,0.055)
	if hurt_flash > 0.0:
		queue_redraw()

func _update_camera(delta: float) -> void:
	camera.position.x = lerpf(camera.position.x, facing*95.0, minf(1.0,delta*5.5))
	if shake_timer > 0.0:
		shake_timer -= delta
		camera.offset = Vector2(randf_range(-shake_strength,shake_strength),randf_range(-shake_strength,shake_strength))
		shake_strength = move_toward(shake_strength,0.0,delta*28.0)
	else:
		camera.offset = camera.offset.lerp(Vector2.ZERO,minf(1.0,delta*18.0))
