extends Area2D

signal picked(mask_id: String, display_name: String, description: String)
const MaskDB = preload("res://masks/mask_data.gd")
var mask_id := "hunter"
var t:=0.0
var base_y:=0.0

func _ready() -> void:
	base_y=position.y
	collision_layer=0
	collision_mask=1
	var c:=CollisionShape2D.new()
	var s:=CircleShape2D.new()
	s.radius=27.0
	c.shape=s
	add_child(c)
	body_entered.connect(_on_body)
	if mask_id in SaveManager.data.get("masks",[]):
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var accent: Color = MaskDB.get_mask(mask_id)["accent"]
	draw_circle(Vector2.ZERO,31,Color(accent.r,accent.g,accent.b,0.08+sin(t*3.0)*0.03))
	if mask_id=="hunter":
		draw_colored_polygon(PackedVector2Array([Vector2(-15,-18),Vector2(15,-18),Vector2(19,-8),Vector2(0,20),Vector2(-19,-8)]),accent)
		draw_colored_polygon(PackedVector2Array([Vector2(-15,-16),Vector2(-25,-25),Vector2(-18,-6)]),accent)
		draw_colored_polygon(PackedVector2Array([Vector2(15,-16),Vector2(25,-25),Vector2(18,-6)]),accent)
	else:
		draw_circle(Vector2.ZERO,19,accent)
		draw_colored_polygon(PackedVector2Array([Vector2(0,-19),Vector2(7,0),Vector2(0,19),Vector2(-7,0)]),Color("76106b"))

func _process(delta: float) -> void:
	t+=delta
	position.y = base_y + sin(t*2.0)*4.0
	queue_redraw()

func _on_body(body: Node) -> void:
	if not body.is_in_group("player") or not body.has_method("unlock_mask"):
		return
	if bool(body.call("unlock_mask",mask_id)):
		var d:=MaskDB.get_mask(mask_id)
		AudioManager.play_sfx("res://assets/audio/ability.wav",-3.0,1.12)
		picked.emit(mask_id,str(d["name"]),str(d["description"]))
		queue_free()
