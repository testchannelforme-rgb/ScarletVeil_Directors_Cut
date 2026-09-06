extends Area2D

signal activated(ability_id: String, display_name: String, description: String)
var ability_id := "dash"
var display_name := "SCARLET DASH"
var description := "Cut through danger in a streak of Veilfire."
var used := false
var t := 0.0

func _ready() -> void:
	collision_layer=0
	collision_mask=1
	var c:=CollisionShape2D.new()
	var s:=CircleShape2D.new()
	s.radius=34.0
	c.shape=s
	add_child(c)
	body_entered.connect(_on_body)
	used=bool(SaveManager.data.get("abilities",{}).get(ability_id,false))
	queue_redraw()

func _draw() -> void:
	var a:=0.3+sin(t*2.5)*0.12
	draw_circle(Vector2(0,8),36,Color(0.65,0.01,0.08,a*0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(-24,26),Vector2(-18,-6),Vector2(0,-31),Vector2(18,-6),Vector2(24,26)]),Color("21151b"))
	draw_line(Vector2(0,-23),Vector2(0,18),Color("e0193c") if not used else Color("5e4650"),4)
	draw_circle(Vector2(0,-13),5,Color("fff0e9") if not used else Color("766b70"))

func _process(delta: float) -> void:
	t+=delta
	queue_redraw()

func _on_body(body: Node) -> void:
	if used or not body.is_in_group("player") or not body.has_method("unlock_ability"):
		return
	if bool(body.call("unlock_ability",ability_id,display_name)):
		used=true
		activated.emit(ability_id,display_name,description)
		queue_redraw()
