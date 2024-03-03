class_name Gameplay extends Node2D

@onready var hud = $HUD
@onready var strum_lines:Array[StrumLine] = [$HUD/StrumLine, $HUD/StrumLine2]
@onready var panels:Array[Panel] = [$HUD/Panel, $HUD/Panel2]
@onready var hit_info = $HUD/HitInfo
@onready var score_info = $HUD/AnchorWorkaround/ScoreInfo
@onready var anchor_workaround = $HUD/AnchorWorkaround

@onready var scripts = $Scripts
@onready var tracks = $Tracks
@onready var camera:Camera2D = $Camera2D

@onready var bar_box = $HUD/ColorRect
@onready var health_bar = $HUD/ColorRect/Health
@onready var time_bar = $HUD/ColorRect/Time
@onready var failed_txt = $HUD/ColorRect/Label
@onready var ded = $HUD/ColorRect/Ded

@export var ms_gradient:Gradient = Gradient.new()
@export var hp_gradient:Gradient = Gradient.new()

var play_lane:Config.PlayLane
var stage:Stage
var player:Character
var spectator:Character
var opponent:Character

static var song_folder:String = "mismatch"
static var chart:Chart
var first_track:AudioStreamPlayer
var combo:int = 0
var highest_combo:int = 0

var score:int = 0
var misses:int = 0
var health:float = 0.5
var length:float = 0

var ms_sum:float = 0
var ms_calc:float = 0
var notes_hit:int = 0
var passed_notes:int = 0

var queued_index:int = 0
var event_index:int = 0

var events:Array[Array] = []

func _ready():
	Conductor.bpm = chart.bpm
	Conductor.crochet = 60 / chart.bpm
	Conductor.bpm_changes = chart.bpm_changes
	Conductor.quant_offset = chart.song_offset

	Conductor.cur_pos = -Conductor.crochet
	Conductor.float_beat = 0.0
	Conductor.cur_beat = 0
	
	load_background()
	strum_lines[0].character = player
	strum_lines[1].character = opponent
	
	play_lane = Config.get_opt("playing_target", Config.PlayLane.PLAYER)
	strum_lines[0].cpu_input = play_lane == Config.PlayLane.OPPONENT or play_lane == Config.PlayLane.BOTPLAY
	strum_lines[1].cpu_input = play_lane != Config.PlayLane.OPPONENT and play_lane != Config.PlayLane.ALL
	check_middlescroll()
	
	for panel in panels:
		panel.modulate.a = Config.get_opt("panel_alpha", 1.0)
	var scroll_mult = 1 - int(Config.get_opt("upscroll", false)) * 2
	for line in strum_lines:
		line.speed = (Config.get_opt("scroll", 2.5) if Config.get_opt("force_scroll", false) else chart.speed) * scroll_mult
		line.position.y = 290 * scroll_mult
	for script in Chart.get_scripts(song_folder):
		script.game = self
		script.hud = hud
		scripts.add_child(script)
	
	for ev in chart.events:
		prepare_event(ev)
	
	for event in events:
		if event.size() < 3:
			event.append([])
		elif not (event[2] is Array):
			event[2] = []
	
	events.filter(func(event):
		return 	event[0] is float \
			and event[1] is Callable
	)
	events.sort_custom(func(a, b): return a[0] < b[0])
	
	await get_tree().create_timer(Conductor.crochet).timeout

	for track in Chart.get_tracks(song_folder):
		tracks.add_child(track)
		track.play()
	first_track = tracks.get_child(0)
	length = first_track.stream.get_length()
		
	Conductor.beat_hit.connect(beat_hit)

func check_middlescroll():
	if not Config.get_opt("middlescroll", false): return
	
	if play_lane == Config.PlayLane.OPPONENT:
		panels[0].size.x = 220
		panels[0].pivot_offset.x = 110
		panels[0].position.x += 165
		strum_lines[0].scale *= 0.5
		strum_lines[0].position.x += 55
		
		panels[1].position.x = -220
		strum_lines[1].position.x = 0
	else:
		panels[1].size.x = 220
		panels[1].pivot_offset.x = 110
		panels[1].position.x += 55
		strum_lines[1].scale *= 0.5
		strum_lines[1].position.x -= 55
		
		panels[0].position.x = -220
		strum_lines[0].position.x = 0

func beat_hit(beat):
	call_scripts("beat_hit", [beat])
	if beat % 4 == 0:
		camera.zoom += Vector2(0.015, 0.015)
		hud.scale += Vector2(0.03, 0.03)
	if abs(first_track.get_playback_position() - Conductor.cur_pos) >= 0.02:
		for track in tracks.get_children():
			track.seek(Conductor.cur_pos)

func load_background():
	stage = load("res://scenes/game/stages/%s.tscn" % chart.stage).instantiate()
	stage.game = self
	add_child(stage)
	move_child(stage, 3)
	
	player = load("res://scenes/game/characters/%s.tscn" % chart.characters[0]).instantiate()
	var pos_to_use = stage.spec_pos if (stage.spec_pos != null and player.common_position == 2) else stage.plr_pos
	if pos_to_use != null:
		player.add_pos = pos_to_use
		pos_to_use.add_child(player)
	camera.position = stage.plr_pos.position + player.position + player.cam_pos.position
	if player.common_position != 0: player.scale.x *= -1
		
	spectator = load("res://scenes/game/characters/%s.tscn" % chart.characters[1]).instantiate()
	if stage.spec_pos != null:
		spectator.add_pos = stage.spec_pos
		stage.spec_pos.add_child(spectator)
	if spectator.common_position == 0: spectator.scale.x *= -1
		
	opponent = load("res://scenes/game/characters/%s.tscn" % chart.characters[2]).instantiate()
	pos_to_use = stage.spec_pos if (stage.spec_pos != null and opponent.common_position == 2) else stage.cpu_pos
	if pos_to_use != null:
		opponent.add_pos = pos_to_use
		pos_to_use.add_child(opponent)
	if opponent.common_position == 0: opponent.scale.x *= -1
	
func prepare_event(ev:Chart.ChartEvent):
	match ev.name:
		"Change Camera Target": events.append([ev.beat, move_camera, ev.params])
	call_scripts("prepare_event", [ev])

func move_camera(is_plr:bool):
	camera.position = player.get_cam_pos() if is_plr else opponent.get_cam_pos()
	if play_lane == Config.PlayLane.CAM_TARGET:
		strum_lines[0].cpu_input = not is_plr
		strum_lines[1].cpu_input = is_plr
		
	if Config.get_opt("middlescroll", false) and play_lane > Config.PlayLane.OPPONENT:
		var plr_mult = int(is_plr)
		var tween = get_tree().create_tween().set_parallel()
		tween.tween_property(panels[0], "size:x", 220 + 220 * plr_mult, Conductor.crochet * 0.25)
		tween.tween_property(panels[0], "position:x", 265 - 485 * plr_mult, Conductor.crochet * 0.25)
		tween.tween_property(strum_lines[0], "scale:x", 0.5 + 0.5 * plr_mult, Conductor.crochet * 0.25)
		tween.tween_property(strum_lines[0], "scale:y", 0.5 + 0.5 * plr_mult, Conductor.crochet * 0.25)
		tween.tween_property(strum_lines[0], "position:x", 375 * (1 - plr_mult), Conductor.crochet * 0.25)
		tween.tween_property(panels[1], "size:x", 440 - 220 * plr_mult, Conductor.crochet * 0.25)
		tween.tween_property(panels[1], "position:x", -220 - 265 * plr_mult, Conductor.crochet * 0.25)
		tween.tween_property(strum_lines[1], "scale:x", 1.0 - 0.5 * plr_mult, Conductor.crochet * 0.25)
		tween.tween_property(strum_lines[1], "scale:y", 1.0 - 0.5 * plr_mult, Conductor.crochet * 0.25)
		tween.tween_property(strum_lines[1], "position:x", -375 * plr_mult, Conductor.crochet * 0.25)

func _process(delta):
	while events.size() > event_index and events[event_index][0] <= Conductor.float_beat:
		var event = events[event_index]
		event[1].callv(event[2])
		event_index += 1
	
	camera.zoom = lerp(camera.zoom, Vector2(stage.default_zoom, stage.default_zoom), delta * 2.4)
	hud.scale = lerp(hud.scale, Vector2.ONE, delta * 2.4)
	
	var beat_progress = 1 - fmod(Conductor.float_beat, 1.0)
	anchor_workaround.scale.x = 1 + (beat_progress * beat_progress * 0.1)
	anchor_workaround.scale.y = anchor_workaround.scale.x
	
	hit_info.rotation = lerpf(hit_info.rotation, 0, delta * 7)
	hit_info.modulate.a -= delta * 3
	
	while chart.notes.size() > queued_index and chart.notes[queued_index].time - Conductor.cur_pos < 2:
		strum_lines[chart.notes[queued_index].parent].make_note(chart.notes[queued_index])
		queued_index += 1
		
	if Input.is_action_just_pressed("ui_text_submit"):
		get_tree().paused = true
		var menu = load("res://scenes/pause/PauseMenu.tscn").instantiate()
		add_child(menu)
		
	if first_track != null:
		time_bar.value = Conductor.cur_pos / length
		health_bar.value = lerpf(health_bar.value, health, delta * 3)
		health_bar.tint_progress = hp_gradient.sample(health_bar.value)
		
		if Conductor.cur_pos >= length:
			get_tree().paused = true
			var menu = load("res://scenes/ResultsScreen.tscn").instantiate()
			add_child(menu)

var oop_color:Color = Color(1, 0.15, 0.15)

func _note_hit(strum, note):
	if strum.cpu_input:
		call_scripts("note_hit", [strum, note])
		return
	combo += 1
	notes_hit += 1
	highest_combo = maxi(highest_combo, combo)
		
	if not failed_txt.visible:
		var ms = roundf((Conductor.cur_pos - note.hit_time) * 100000) * 0.01
		ms_sum += ms
		ms_calc += abs(ms)
		if ms < 0:
			hit_info.text = "< %s ms\nCombo: %s" % [ms, combo]
			hit_info.rotation_degrees = -10 * Config.get_opt("combo_tilt", 1.0)
		else:
			hit_info.text = "%s ms >\nCombo: %s" % [ms, combo]
			hit_info.rotation_degrees = 10 * Config.get_opt("combo_tilt", 1.0)
		
		ms *= 0.001
		var score_mult = 1 - abs(ms / strum_lines[0].hit_window)
		score += 350 * score_mult + floori(5 * (combo / 20.0))
		health = minf(1.0, health + 0.015 * (score_mult - 0.25))
		hit_info.modulate = ms_gradient.sample(score_mult)
		hit_info.modulate.a = 1.5
		if health <= 0.0:
			failed_txt.visible = true
			bar_box.modulate = oop_color
			bar_box.scale *= 2.0
			get_tree().create_tween().tween_property(bar_box, "scale", bar_box.scale * 0.5, 0.25)
			ded.play()
	else:
		ms_calc += strum_lines[0].hit_window * 1000
		hit_info.modulate = oop_color
		hit_info.modulate.a = 1.5
		
		var ms = roundf((Conductor.cur_pos - note.hit_time) * 100000) * 0.01
		ms_sum += ms
		if ms < 0:
			hit_info.text = "< %s ms\nCombo: %s" % [ms, combo]
			hit_info.rotation_degrees = -10 * Config.get_opt("combo_tilt", 1.0)
		else:
			hit_info.text = "%s ms >\nCombo: %s" % [ms, combo]
			hit_info.rotation_degrees = 10 * Config.get_opt("combo_tilt", 1.0)
			
	update_score()
	
	call_scripts("note_hit", [strum, note])

func _note_miss(strum, note):
	combo = 0
	score -= 10
	misses += 1
	ms_calc += strum_lines[0].hit_window * 1000
	hit_info.text = "oops..."
	hit_info.rotation_degrees = (10 if hit_info.rotation < 0 else -10) * Config.get_opt("combo_tilt", 1.0)
	hit_info.modulate = oop_color
	hit_info.modulate.a = 1.5
	health = maxf(0.0, health - 0.02)
	if health <= 0.0 and not failed_txt.visible:
		failed_txt.visible = true
		bar_box.modulate = oop_color
		bar_box.scale *= 2.0
		get_tree().create_tween().tween_property(bar_box, "scale", bar_box.scale * 0.5, 0.25)
		ded.play()
	update_score()
	
	call_scripts("note_miss", [strum, note])

func update_score():
	passed_notes += 1
	var av_ms = roundf(ms_sum / passed_notes * 100) * 0.01
	var acc_ms = ms_calc / passed_notes
	var acc = 100 - acc_ms / (strum_lines[0].hit_window * 1000) * 100
	score_info.text = "Score: %s\nMisses: %s\nAccuracy: %.2f%%\nAverage MS: %s" % [score, misses, acc, av_ms]



func call_scripts(func_name:String, params:Array[Variant]):
	for script in scripts.get_children():
		if script.has_method(func_name):
			script.callv(func_name, params)
