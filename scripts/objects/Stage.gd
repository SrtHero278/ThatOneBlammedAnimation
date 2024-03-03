class_name Stage extends Node2D

@export var default_zoom:float = 1.05

@export_group("Character Positions")
@export var player_position:NodePath
@export var spectator_position:NodePath
@export var opponent_position:NodePath

@export_group("Character Camera Offsets")
@export var player_cam_offset:Vector2
@export var spectator_cam_offset:Vector2
@export var opponent_cam_offset:Vector2

var game:Gameplay
var plr_pos:Node2D = null
var spec_pos:Node2D = null
var cpu_pos:Node2D = null

func _ready():
	if player_position != null and has_node(player_position): plr_pos = get_node(player_position)
	if spectator_position != null and has_node(spectator_position): spec_pos = get_node(spectator_position)
	if opponent_position != null and has_node(opponent_position): cpu_pos = get_node(opponent_position)
