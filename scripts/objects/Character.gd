class_name Character extends Node2D

@export_enum("Player", "Opponent", "Spectator") var common_position:int = 0

@export var dance_anims:Array[StringName] = []
var dance_index:int = 0
var til_dance:float = 0.0

var stop_sing:bool = false
var cur_anim:StringName = ""
@onready var anim_player:AnimationPlayer = $AnimationPlayer
@onready var cam_pos:Node2D = $CameraPosition
var add_pos:Node2D

func _ready():
	Conductor.beat_hit.connect(beat_hit)
	play_anim(dance_anims[0])

func _process(delta):
	if cur_anim.begins_with("sing"):
		til_dance -= delta
		if til_dance <= 0.0:
			beat_hit(0)

func play_anim(anim_name:StringName, force:bool = false):
	if stop_sing and anim_name.begins_with("sing"): return
	cur_anim = anim_name
	anim_player.play(anim_name)
	if force: anim_player.seek(0.0)
	
	til_dance = Conductor.crochet

func beat_hit(_beat):
	if dance_anims.has(cur_anim) or til_dance <= 0.0:
		play_anim(dance_anims[dance_index])
		dance_index = (dance_index + 1) % dance_anims.size()
	
func get_cam_pos():
	if add_pos == null: return position + cam_pos.position
	return add_pos.position + position + cam_pos.position
