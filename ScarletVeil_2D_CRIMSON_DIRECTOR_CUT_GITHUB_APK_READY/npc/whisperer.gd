extends Area2D

signal dialogue_requested(lines: Array[String])
var lines: Array[String] = [
	"The bells remember what we chose to forget.",
	"Do not trust every memory that calls your name.",
	"A mask can preserve a life. It can also erase one."
]
var player_near:=false
var spoken:=false

func _ready() -> void:
	collision_layer=0
	collision_mask=1
	var c:=CollisionShape2D.new()
	var s:=CircleShape2D.new()
	s.radius=56.0
	c.shape=s
	add_child(c)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-15,-36),Vector2(15,-36),Vector2(25,28),Vector2(0,40),Vector2(-25,28)]),Color("160e16"))
	draw_colored_polygon(PackedVector2Array([Vector2(-12,-38),Vector2(12,-38),Vector2(16,-23),Vector2(0,-12),Vector2(-16,-23)]),Color("cabfb8"))
	draw_line(Vector2(-5,-27),Vector2(5,-27),Color("c81532"),1.5)
	if player_near:
		draw_circle(Vector2(0,-60),10,Color(0.7,0.04,0.12,0.2))
		draw_string(ThemeDB.fallback_font,Vector2(-4,-56),"!",HORIZONTAL_ALIGNMENT_LEFT,10,15,Color("f1e5dd"))

func _process(_delta: float) -> void:
	if player_near and Input.is_action_just_pressed("interact"):
		dialogue_requested.emit(lines)
		if not spoken:
			AudioManager.play_voice("res://assets/audio/voice_npc.wav")
			spoken=true

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = true
		queue_redraw()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = false
		queue_redraw()
