extends ScriptNode

@onready var anim_player:AnimationPlayer = game.stage.get_node("SpecialAnim")
@onready var shader:ShaderMaterial = ShaderMaterial.new()
var og_scroll_add:float = 0.0
var shadow:ColorRect
var label:Label
var label_settings:LabelSettings

#96 - enter tain
#112 - bf enter tain
#128 - effect
#144 - bf sing
#160 - pico sing again
#176 - bf sing again
#188 - final effect section
#192 - effect over

#1, 3,   4, 5.5 6, 7
#1, 3,   4, 5.5 6, 7
#1, 3,   4, 5.5 6, 7
#1, 2.5, 4, 5.5 6, 7
#repeat but last section = #1, 2, 3, 4

func _ready():
	shader.shader = load("res://assets/shaders/lightsOut.gdshader")
	game.player.material = shader
	game.player.modulate = game.stage.get_node("1-0/BfTrain").modulate
	game.opponent.material = shader
	game.opponent.modulate = game.stage.get_node("1-0/PicoTrain").modulate
	game.events.append([112.01, snap_to_opponent])
	for beat in 7:
		game.events.append([132.5 + 8.0 * beat, swoosh, [true, 0.4]])
	game.events.append([153.5, swoosh, [false, 0.9]])
	game.events.append([185.5, swoosh, [false, 0.9]])
	
	game.opponent.visible = false
	game.spectator.visible = false
	game.player.visible = false
	game.stage.default_zoom *= 2.0
	game.camera.zoom = Vector2(game.stage.default_zoom, game.stage.default_zoom)
	
	shadow = ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.5)
	shadow.size = Vector2(1280, 720)
	shadow.position = shadow.size * -0.5
	hud.add_child(shadow)
	
	label_settings = LabelSettings.new()
	label_settings.font = load("res://assets/fonts/vcr.ttf")
	label_settings.font_size = 30
	label_settings.outline_size = 4
	label_settings.outline_color = Color.BLACK
	
	label = Label.new()
	label.label_settings = label_settings
	hud.add_child(label)
	label.text = '"idk rhythm" and\n"That One Blammed Animation"\ncoded by Srt (hi :D)'
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position.x = -600.0
	label.position.y = -label.size.y * 0.5
	
	for panel in game.panels: panel.scale.x = 0.0
	for lane in game.strum_lines: lane.modulate.a = 0.0
	var window = get_window()
	window.size_changed.connect(func():
		shader.set_shader_parameter("window_scale", maxf(1.0, 1280.0 / window.size.x)))

func _process(_delta):
	if Conductor.float_beat >= 96.0 and Conductor.float_beat <= 102.0:
		game.camera.position = game.opponent.get_cam_pos()

func snap_to_opponent():
	game.camera.position = game.opponent.get_cam_pos()
	game.camera.align()
	game.camera.position_smoothing_enabled = true
	game.stage.building_scroll_mult = 3.0
	game.stage.building_scroll_add = og_scroll_add + Conductor.crochet * 24.0

func swoosh(left:bool, mult:float = 0.9):
	if left:
		var tween = get_tree().create_tween().set_parallel()
		for lane in game.strum_lines:
			lane.mods.position_offset.x = -50
			lane.mods.bounce_type = StrumMods.BounceType.VERTICALS
			lane.mods.bounce_pixels = 50
			tween.tween_property(lane, "mods:bounce_pixels", 0.0, Conductor.crochet * mult)
			tween.tween_property(lane, "mods:position_offset:x", 0, Conductor.crochet * mult)
	else:
		var tween = get_tree().create_tween().set_parallel()
		for lane in game.strum_lines:
			lane.mods.position_offset.x = 50
			lane.mods.bounce_type = StrumMods.BounceType.VERTICALS
			lane.mods.bounce_pixels = -50
			tween.tween_property(lane, "mods:bounce_pixels", 0.0, Conductor.crochet * mult)
			tween.tween_property(lane, "mods:position_offset:x", 0, Conductor.crochet * mult)

func beat_hit(beat):
	if beat >= 128 and beat < 188:
			match beat % 8:
				0, 3, 5: swoosh(true)
				2:
					if beat % 32 < 24:
						swoosh(false)
				6: swoosh(false)
	
	match beat:
		0, 1, 2, 3, 4, 5: # i lag a bit so imma just make this case scuffed.
			game.camera.position_smoothing_enabled = false
			game.camera.position = game.spectator.get_cam_pos()
			game.camera.position.y -= 450
			game.camera.align()
		8:
			label.text = '"That One Blammed Animation"\ninspired by well,\nthat animation.\n(Animation by Razur and Cyber)\n(Remix by Biddle3)'
			label.size = Vector2.ZERO
			label.position.x = 600.0 - label.size.x
			label.position.y = -label.size.y * 0.5
			
			game.player.visible = true
			game.camera.position = game.player.get_cam_pos()
			game.camera.position.x += 200
			game.camera.position.y += 80
			game.camera.align()
		16:
			label.text = "Use Psych or Codename for one shots?\nNah, make your own fnf engine in Godot."
			label.size = Vector2.ZERO
			label.position.x = -label.size.x * 0.5
			label.position.y = -260
			
			game.spectator.visible = true
			game.camera.position = game.spectator.get_cam_pos()
			game.camera.align()
		24:
			label.queue_free()
			
			game.opponent.visible = true
			game.camera.position = game.opponent.get_cam_pos()
			game.camera.position.x -= 200
			game.camera.position.y += 80
			game.camera.align()
			game.camera.position_smoothing_enabled = true

			var tween = get_tree().create_tween().set_parallel()
			for panel in game.panels: tween.tween_property(panel, "scale:x", 1.0, Conductor.crochet * 4.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			for lane in game.strum_lines: tween.tween_property(lane, "modulate:a", 1.0, Conductor.crochet * 4.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		32:
			game.stage.default_zoom *= 0.5
			
			var tween = get_tree().create_tween()
			tween.tween_property(shadow, "modulate:a", 0.0, Conductor.crochet * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween.finished.connect(shadow.queue_free)
		88:
			anim_player.play("picoTrain")
			game.opponent.cam_pos.position.y += 100.0
		94:
			game.player.play_anim("singLEFTmiss", true)
			game.player.til_dance *= 4.0
			game.player.stop_sing = true
			game.camera.position_smoothing_speed = 80.0
		103:
			anim_player.play("bfTrain")
			game.camera.position_smoothing_speed = 3.0
			game.camera.position_smoothing_enabled = false
		104:
			game.camera.position = game.player.get_cam_pos()
			game.camera.align()
			game.stage.building_scroll_mult = 0.0
			og_scroll_add = game.stage.building_scroll_add
			game.stage.building_scroll_add = 0.0
		109, 111:
			game.player.play_anim("pre-attack")
		110:
			game.player.play_anim("attack")
		112:
			game.player.play_anim("idle", true)
			game.player.stop_sing = false
			game.player.cam_pos.position.y += 60.0
		128:
			# bind was being weird...
			var tween = get_tree().create_tween().set_parallel()
			tween.tween_method(func(num):
				shader.set_shader_parameter("effect_max", num),
			0.0, 1280.0, Conductor.crochet * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(game.stage.tunnel_wall, "size:x", 1280.0, Conductor.crochet * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		188, 189, 190, 191:
			game.stage.default_zoom += 0.1
			
			var inc = 50 * (1 - ((beat % 2) * 2))
			var tween = get_tree().create_tween().set_parallel()
			for lane in game.strum_lines:
				lane.position.x += inc
				lane.mods.bounce_type = StrumMods.BounceType.TILT
				lane.mods.bounce_pixels = -inc
				tween.tween_property(lane, "mods:bounce_pixels", 0.0, Conductor.crochet * 0.9)
				tween.tween_property(lane, "position:x", lane.position.x - inc, Conductor.crochet * 0.9)
		192:
			game.stage.default_zoom -= 0.4
			game.camera.zoom = Vector2(2.2, 2.2)
			var tween = get_tree().create_tween().set_parallel()
			tween.tween_method(func(num):
				shader.set_shader_parameter("effect_min", num),
			0.0, 1280.0, Conductor.crochet * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(game.stage.tunnel_wall, "position:x", 1280.0, Conductor.crochet * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(game.stage.tunnel_wall, "size:x", 0.0, Conductor.crochet * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
