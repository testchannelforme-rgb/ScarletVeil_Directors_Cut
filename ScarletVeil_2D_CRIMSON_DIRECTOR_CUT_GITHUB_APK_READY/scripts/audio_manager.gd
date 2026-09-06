extends Node

var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var current_music := ""
var _voice_ducked := false
var _music_base_db := -13.0
var _ambience_base_db := -18.0

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -13.0
	add_child(music_player)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.volume_db = -18.0
	add_child(ambience_player)
	voice_player = AudioStreamPlayer.new()
	voice_player.volume_db = -3.0
	add_child(voice_player)
	voice_player.finished.connect(_on_voice_finished)
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.volume_db = -7.0
		add_child(p)
		sfx_players.append(p)

func _music_enabled() -> bool:
	return bool(SaveManager.data.get("settings", {}).get("music", true))

func _sfx_enabled() -> bool:
	return bool(SaveManager.data.get("settings", {}).get("sfx", true))

func _voice_enabled() -> bool:
	return bool(SaveManager.data.get("settings", {}).get("voice", true))

func play_music(path: String, volume_db := -13.0) -> void:
	if not _music_enabled():
		music_player.stop()
		return
	if current_music == path and music_player.playing:
		return
	current_music = path
	var stream = load(path)
	if stream == null:
		return
	if stream is AudioStreamWAV:
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_player.stream = stream
	_music_base_db = volume_db
	music_player.volume_db = volume_db
	music_player.play()

func stop_music(fade := 0.35) -> void:
	if not music_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(music_player, "volume_db", -50.0, fade)
	await tween.finished
	music_player.stop()
	music_player.volume_db = -13.0
	current_music = ""

func play_ambience(path := "res://assets/audio/ambient.wav") -> void:
	if not _music_enabled():
		ambience_player.stop()
		return
	if ambience_player.playing:
		return
	var stream = load(path)
	if stream is AudioStreamWAV:
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambience_player.stream = stream
	_ambience_base_db = ambience_player.volume_db
	ambience_player.play()

func stop_ambience() -> void:
	ambience_player.stop()

func play_sfx(path: String, volume_db := -7.0, pitch := 1.0) -> void:
	if not _sfx_enabled():
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = load(path)
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return
	var p := sfx_players[0]
	p.stream = load(path)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func play_voice(path: String) -> void:
	if not _voice_enabled():
		return
	voice_player.stream = load(path)
	_duck_for_voice()
	voice_player.play()

func _duck_for_voice() -> void:
	_voice_ducked = true
	var t := create_tween()
	if music_player.playing:
		t.parallel().tween_property(music_player, "volume_db", _music_base_db - 8.0, 0.12)
	if ambience_player.playing:
		t.parallel().tween_property(ambience_player, "volume_db", _ambience_base_db - 6.0, 0.12)

func _on_voice_finished() -> void:
	if not _voice_ducked:
		return
	_voice_ducked = false
	var t := create_tween()
	if music_player.playing:
		t.parallel().tween_property(music_player, "volume_db", _music_base_db, 0.28)
	if ambience_player.playing:
		t.parallel().tween_property(ambience_player, "volume_db", _ambience_base_db, 0.28)

func apply_settings() -> void:
	if not _music_enabled():
		music_player.stop()
		ambience_player.stop()
