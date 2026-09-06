extends Area2D

signal collected(memory_id: String, title: String, text: String)

var memory_id := "unknown"
var memory_title := "Fragment"
var memory_text := "A memory without a name."
var hidden_until_echo := false
var base_y := 0.0
var t := 0.0
var revealed := true

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	add_to_group("memory_shards")
	base_y = position.y
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new()
	s.radius = 19.0
	c.shape = s
	add_child(c)
	body_entered.connect(_on_body)
	if memory_id in SaveManager.data.get("memory_shards", []):
		queue_free()
		return
	if hidden_until_echo:
		set_revealed(false)
	queue_redraw()

func _draw() -> void:
	var pulse := 0.72 + sin(t*4.0)*0.18
	draw_circle(Vector2.ZERO, 28.0, Color(0.8,0.01,0.08,0.06*pulse))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-23),Vector2(13,0),Vector2(0,24),Vector2(-13,0)]),Color(0.88,0.03,0.12,0.88))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-13),Vector2(6,0),Vector2(0,14),Vector2(-6,0)]),Color("fff2ec"))
	draw_line(Vector2(-19,0),Vector2(19,0),Color(0.95,0.16,0.24,0.35),1.5)

func _process(delta: float) -> void:
	t += delta
	position.y = base_y + sin(t*2.1)*6.0
	rotation = sin(t*1.4)*0.07
	queue_redraw()

func set_revealed(value: bool) -> void:
	revealed = value
	visible = value
	monitoring = value

func _on_body(body: Node) -> void:
	if not body.is_in_group("player") or not body.has_method("collect_memory"):
		return
	if bool(body.call("collect_memory",memory_id)):
		AudioManager.play_sfx("res://assets/audio/memory_pickup.wav",-3.0)
		collected.emit(memory_id,memory_title,memory_text)
		var tw := create_tween()
		tw.tween_property(self,"scale",Vector2(2.2,2.2),0.16)
		tw.parallel().tween_property(self,"modulate:a",0.0,0.22)
		await tw.finished
		queue_free()
