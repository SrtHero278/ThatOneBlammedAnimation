class_name Note extends Node2D

#var quant_values = [
#	[4, Color8(249, 57, 63)],
#	[8, Color8(83, 107, 239)],
#	[12, Color8(194, 75, 153)],
#	[16, Color8(0, 229, 80)],
#	[20, Color8(96, 103, 137)],
#	[24, Color8(255, 122, 215)],
#	[32, Color8(255, 232, 61)],
#	[48, Color8(174, 54, 230)],
#	[64, Color8(15, 235, 255)],
#	[192, Color8(96, 103, 137)]
#]
var quant_values = [
	[4, Color8(255, 56, 112)],
	[8, Color8(0, 200, 255)],
	[12, Color8(192, 66, 255)],
	[16, Color8(0, 255, 123)],
	[20, Color8(196, 196, 196)],
	[24, Color8(255, 150, 234)],
	[32, Color8(255, 255, 82)],
	[48, Color8(170, 0, 255)],
	[64, Color8(0, 255, 255)],
	[192, Color8(196, 196, 196)]
]

@onready var note = $Note
var hold_rect:Control

var hit_time:float = 0
var lane_id:int = 0
var sustain_length:float = 0
var crochet:float = 0.5
var last_change:float = 0.0

static var note_tex:Texture2D
static var hold_tex:Texture2D
static var tail_tex:Texture2D
static var note_scale:float

static func load_textures():
	var skin = Config.noteskins[Config.get_opt("note_skin", 0)]
	note_tex = load("res://assets/images/notes/%s/arrow.png" % skin)
	hold_tex = load("res://assets/images/notes/%s/hold.png" % skin)
	tail_tex = load("res://assets/images/notes/%s/tail.png" % skin)
	note_scale = Config.notesizes[Config.get_opt("note_skin", 0)]

func resize_sustain(length:float, speed:float):
	hold_rect.size.y = abs(45 * (length * speed * 15))
	hold_rect.rotation_degrees = 180.0 if speed > 0.0 else 0.0

func _ready():
	note.texture = note_tex
	make_sustain()
	scale = Vector2(note_scale, note_scale)
	
	var mes_time = crochet * 4
	var smallest_quant_index = quant_values.size() - 1
	var smallest_deviation = mes_time / quant_values[smallest_quant_index][0]
	
	for quant in quant_values:
		var quant_time = mes_time / quant[0]
		if fmod(hit_time - last_change + smallest_deviation, quant_time) < smallest_deviation * 2:
			modulate = quant[1]
			return
	modulate = quant_values[smallest_quant_index][1]

func make_sustain():
	hold_rect = Control.new()
	hold_rect.clip_contents = true
	hold_rect.use_parent_material = true
	add_child(hold_rect)
	move_child(hold_rect, 0)

	var tail = TextureRect.new()
	tail.use_parent_material = true
	tail.texture = tail_tex
	tail.layout_mode = 1
	tail.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tail.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tail.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var hold = TextureRect.new()
	hold.use_parent_material = true
	hold.texture = hold_tex
	hold.layout_mode = 1
	hold.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hold.set_anchors_preset(Control.PRESET_FULL_RECT)
	hold.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -tail.texture.get_height() + 1.0)
	hold.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hold.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	hold_rect.size.x = maxf(tail.texture.get_width(), hold.texture.get_width())
	hold_rect.position.x -= hold_rect.size.x * 0.5
	hold_rect.pivot_offset.x = -hold_rect.position.x
	hold_rect.add_child(hold)
	hold_rect.add_child(tail)
