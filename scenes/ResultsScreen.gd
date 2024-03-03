extends CanvasLayer

class RankData extends Resource:
	var accuracy:float
	var image:String
	var subtitle:String
	var sound:String
	
	func _init(acc:float, img:String, sub:String, sfx:String):
		accuracy = acc
		image = img
		subtitle = sub
		sound = sfx

@onready var audio = $AudioStreamPlayer
@onready var label = $Label
@onready var rank = $Rank
@onready var rank_label = $RichTextLabel

@onready var option_list = $OptionList

var acc:float = 15.82
var cur_line:int = 0
var lines:PackedStringArray = [
	"Strumline Played: %s",
	"Notes Hit: %s / %s (%s Missed)",
	"Highest Combo: %s",
	"Accuracy: %.2f%%",
	"Average MS: %s",
	"Score: %s",
	"\n%s"
]
var line_data:Array[Array]
var ranks:Array[RankData] = [
	RankData.new(0, "res://assets/images/game/ranks/f.png", "What the [color=ff0000]fuck[/color] was that?", "res://assets/sounds/cancelMenu.ogg"),
	RankData.new(20, "res://assets/images/game/ranks/c.png", "Kinda [color=ff8000]crap.[/color]\nIt'll do though.", "res://assets/sounds/confirmMenu.ogg"),
	RankData.new(40, "res://assets/images/game/ranks/b.png", "Pretty [color=ffff00]basic.[/color]\nNot bad however!", "res://assets/sounds/confirmMenu.ogg"),
	RankData.new(80, "res://assets/images/game/ranks/a.png", "[color=00ff00]Awesome![/color]\nYou played well.", "res://assets/sounds/confirmMenu.ogg"),
	RankData.new(95, "res://assets/images/game/ranks/s.png", "That was pretty [color=00ffff]sick![/color]\nYou got the hang of FNF don't ya?", "res://assets/sounds/confirmMenu.ogg")
]
var used_botplay:bool = false

func _ready():
	if get_tree().current_scene == self:
		line_data = [
			["idk"],
			[69, 420, 351],
			[69],
			[15.82],
			[5.71],
			[373],
			["Failed Song"]
		]
	else:
		var game:Gameplay = get_tree().current_scene
		used_botplay = game.play_lane == Config.PlayLane.BOTPLAY
		var acc_ms = game.ms_calc / game.passed_notes
		acc = 100.0 - acc_ms / (game.strum_lines[0].hit_window * 1000) * 100
		line_data = [
			[["Player", "Opponent", "Camera Target", "All", "Botplay"][game.play_lane]],
			[game.notes_hit, game.passed_notes, game.misses],
			[game.highest_combo],
			[acc],
			[roundf(game.ms_sum / game.passed_notes * 100) * 0.01],
			[game.score]
		]
		var combo_rank = "Full Combo!"
		if game.misses > 0:
			combo_rank = "SDCB (< 10 Misses)" if game.misses < 10 else "Cleared Song"
		if game.failed_txt.visible:
			combo_rank = "Failed Song"
		line_data.append([combo_rank])
	new_line()

func new_line():
	await get_tree().create_timer(0.35 - 0.03 * cur_line).timeout
	
	if cur_line >= lines.size():
		var rank_data = ranks[0]
		for da_rank in ranks:
			if acc >= da_rank.accuracy:
				rank_data = da_rank
		if used_botplay:
			rank_data = RankData.new(100, "res://assets/images/game/ranks/auto.png", "Looks like you used [color=808080]Botplay.[/color]\nYa liked the show?", "res://assets/sounds/auto.ogg")
		audio.stream = load(rank_data.sound)
		rank.texture = load(rank_data.image)
		
		create_tween().tween_property(label, "position:x", 50, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		await get_tree().create_timer(1.5).timeout
		
		rank.visible = true
		rank_label.visible = true # prevent early button presses
		create_tween().tween_property(rank, "rotation_degrees", 10.0, 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		create_tween().tween_property(rank_label, "position:y", 485.0, 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		create_tween().tween_property(rank_label, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		
		rank_label.text += rank_data.subtitle
		audio.play()
		
		await get_tree().create_timer(1.5).timeout
		audio.stream = load("res://assets/music/title.ogg")
		audio.volume_db = -25
		audio.play()
		
		return
		
	audio.play()
	label.text += "\n" + (lines[cur_line] % line_data[cur_line]).replace("nan", "N/A")
	label.size.y = 0.0
	label.position.y -= 20
	create_tween().tween_property(label, "position:y", label.position.y + 20, 0.25 - 0.03 * cur_line).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	cur_line += 1
	new_line()

func _on_restart_pressed():
	get_tree().paused = false
	Gameplay.chart = Chart.parse_chart("blammed b3", "hard")
	Gameplay.song_folder = "blammed b3"
	if get_tree().current_scene != self:
		Conductor.beat_hit.disconnect($"../".beat_hit)
	get_tree().change_scene_to_file("res://scenes/game/Gameplay.tscn")

func _on_options_pressed():
	option_list.visible = not option_list.visible
