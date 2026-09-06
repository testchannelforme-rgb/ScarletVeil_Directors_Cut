extends AnimatableBody2D

var travel := Vector2(220,0)
var duration := 2.4
var phase := 0.0
var platform_size := Vector2(150,20)
var origin := Vector2.ZERO
var t := 0.0

func _ready()->void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	origin = global_position
	var c:=CollisionShape2D.new()
	var s:=RectangleShape2D.new()
	s.size=platform_size
	c.shape=s
	add_child(c)
	queue_redraw()

func _physics_process(delta:float)->void:
	t += delta
	var cycle := (t / maxf(duration,0.1)) * TAU + phase
	global_position = origin + travel * (sin(cycle)*0.5+0.5)
	queue_redraw()

func _draw()->void:
	draw_rect(Rect2(-platform_size*.5,platform_size),Color("37262e"))
	draw_line(Vector2(-platform_size.x*.5,-platform_size.y*.5),Vector2(platform_size.x*.5,-platform_size.y*.5),Color(0.72,0.13,0.22,0.55),2)
