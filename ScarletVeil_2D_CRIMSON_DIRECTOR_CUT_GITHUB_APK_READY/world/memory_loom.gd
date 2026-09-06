extends Area2D

signal choice_requested

var player_inside := false
var activated := false
var t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var c := CollisionShape2D.new()
	var s := CircleShape2D.new()
	s.radius = 56.0
	c.shape = s
	add_child(c)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	activated = SaveManager.data.get("important_choices", {}).has("mercy_or_truth")
	queue_redraw()

func _process(delta:float)->void:
	t += delta
	if player_inside and Input.is_action_just_pressed("interact") and not activated:
		choice_requested.emit()
	queue_redraw()

func mark_activated()->void:
	activated = true
	queue_redraw()

func _draw()->void:
	var pulse := 0.75 + sin(t*2.5)*0.15
	draw_circle(Vector2.ZERO,42,Color(0.55,0.01,0.07,0.055*pulse))
	draw_arc(Vector2.ZERO,31,0,TAU,32,Color(0.72,0.05,0.12,0.45),2)
	draw_colored_polygon(PackedVector2Array([Vector2(0,-28),Vector2(17,0),Vector2(0,30),Vector2(-17,0)]),Color(0.86,0.78,0.72,0.66 if activated else 0.88))
	draw_line(Vector2(-10,-9),Vector2(10,9),Color("8b1026"),2)
	draw_line(Vector2(10,-9),Vector2(-10,9),Color("8b1026"),2)
	if player_inside and not activated:
		draw_string(ThemeDB.fallback_font,Vector2(-48,-55),"USE — CHOOSE A MEMORY",HORIZONTAL_ALIGNMENT_LEFT,100,13,Color(0.95,0.84,0.82,0.9))

func _on_body_entered(body:Node)->void:
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body:Node)->void:
	if body.is_in_group("player"):
		player_inside = false
