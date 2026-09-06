extends Area2D
var t:=0.0
var hidden_until_echo:=false

func _ready() -> void:
	add_to_group("grapple_anchor")
	collision_layer=0
	collision_mask=0
	queue_redraw()

func _draw() -> void:
	var pulse:=0.75+sin(t*4.0)*0.2
	draw_circle(Vector2.ZERO,14,Color(0.85,0.03,0.12,0.12*pulse))
	draw_arc(Vector2.ZERO,9,0,TAU,20,Color(0.9,0.15,0.22,pulse),2.0)
	draw_line(Vector2(-7,0),Vector2(7,0),Color("efe1da"),1.5)
	draw_line(Vector2(0,-7),Vector2(0,7),Color("efe1da"),1.5)

func _process(delta: float) -> void:
	t+=delta
	queue_redraw()
