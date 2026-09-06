extends Area2D

signal choice_requested
var player_near := false
var t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new()
	s.radius = 62.0
	c.shape = s
	add_child(c)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	queue_redraw()

func _draw() -> void:
	var pulse := 0.65 + sin(t * 2.2) * 0.2
	draw_circle(Vector2.ZERO, 46.0, Color(0.72, 0.01, 0.08, 0.06 * pulse))
	draw_colored_polygon(PackedVector2Array([Vector2(-35,25),Vector2(35,25),Vector2(24,-8),Vector2(0,-46),Vector2(-24,-8)]), Color("26141b"))
	draw_line(Vector2(0,-35), Vector2(0,16), Color(0.9,0.04,0.13,pulse), 4.0)
	draw_arc(Vector2.ZERO, 24.0, 0, TAU, 28, Color(0.9,0.15,0.22,0.65*pulse), 2.0)
	if player_near:
		draw_string(ThemeDB.fallback_font, Vector2(-42,-70), "INTERACT", HORIZONTAL_ALIGNMENT_LEFT, 90, 13, Color("efe1db"))

func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if player_near and Input.is_action_just_pressed("interact"):
		choice_requested.emit()

func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = true
		queue_redraw()

func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = false
		queue_redraw()
