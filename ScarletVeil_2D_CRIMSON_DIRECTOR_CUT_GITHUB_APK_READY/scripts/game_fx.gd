extends Node

var _hitstop_serial := 0

func hitstop(duration := 0.045, scale := 0.12) -> void:
	_hitstop_serial += 1
	var serial := _hitstop_serial
	Engine.time_scale = clampf(scale, 0.05, 1.0)
	await get_tree().create_timer(duration, true, false, true).timeout
	if serial == _hitstop_serial:
		Engine.time_scale = 1.0

func reset_time_scale() -> void:
	_hitstop_serial += 1
	Engine.time_scale = 1.0
