extends Area2D

var direction := 1.0
var speed := 480.0
var life := 2.2
var hit := false

func _ready() -> void:
	collision_layer=0
	collision_mask=1
	var c:=CollisionShape2D.new()
	var s:=RectangleShape2D.new()
	s.size=Vector2(58,28)
	c.shape=s
	add_child(c)
	body_entered.connect(_on_body)
	queue_redraw()

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-34,13),Vector2(-17,-8),Vector2(0,6),Vector2(18,-18),Vector2(35,13)]),Color(0.85,0.03,0.1,0.48))
	draw_polyline(PackedVector2Array([Vector2(-34,13),Vector2(-17,-8),Vector2(0,6),Vector2(18,-18),Vector2(35,13)]),Color("ff3853"),2.0)

func _physics_process(delta: float) -> void:
	position.x += direction*speed*delta
	life-=delta
	modulate.a=clampf(life,0.0,1.0)
	if life<=0.0:
		queue_free()

func _on_body(body: Node) -> void:
	if hit:
		return
	if body.is_in_group("player"):
		hit=true
		body.call("take_damage",1,global_position,self)
		queue_free()
