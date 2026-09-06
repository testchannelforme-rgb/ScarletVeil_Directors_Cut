extends Area2D

var velocity := Vector2.ZERO
var damage := 1
var lifetime := 4.0
var radius := 12.0
var source
var t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new()
	s.radius = radius
	c.shape = s
	add_child(c)
	body_entered.connect(_on_body)
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	position += velocity * delta
	lifetime -= delta
	rotation += delta * 2.4
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	var pulse := 0.82 + sin(t * 8.0) * 0.14
	draw_circle(Vector2.ZERO, radius * 1.8, Color(0.8, 0.0, 0.08, 0.055 * pulse))
	draw_circle(Vector2.ZERO, radius, Color(0.74, 0.015, 0.095, 0.82))
	draw_arc(Vector2.ZERO, radius * 0.72, 0.0, TAU, 20, Color(1.0, 0.55, 0.62, 0.72), 1.5)
	draw_line(Vector2(-radius*0.7, 0), Vector2(radius*0.7, 0), Color(1.0,0.82,0.84,0.65), 1.0)

func _on_body(body: Node) -> void:
	if body == source:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.call("take_damage", damage, global_position, source)
		queue_free()
