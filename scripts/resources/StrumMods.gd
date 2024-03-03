class_name StrumMods extends Resource

var prop_list:Array[String] = []

var strum_line:StrumLine

var norm_positions:Array[float] = []
var spacing_mult:float = 1.0
var position_offset:Vector2 = Vector2.ZERO

## Moves the strums from LDUR to RUDL.
var flip_percent:float = 0.0
## Moves the strums from LDUR to DLRU.
var invert_percent:float = 0.0

var wavy:float = 0.0
var wavy_intensity:float = 1.0

enum BounceType {TILT, VERTICALS, HORIZONTALS, ALTERNATING, INVERT_ALTERNATING}
var bounce_type:BounceType = BounceType.TILT
var bounce_pixels:float = 0.0
var _bounce_mult:Array[Array] = [[-1.5, -0.5, 0.5, 1.5], [0, -1, 1, 0], [-1, 0, 0, 1], [0, 1, 0, 1], [1, 0, 1, 0]]

var _backup:Dictionary = {}

func position_strums():
	for i in strum_line.strums.size():
		var strum = strum_line.strums[i]
		make_backup()
		strum_line.pre_strum_process.emit(strum, i)
		
		var invert_i:int = i - ((i % 2) * 2 - 1)
		strum.position.x = lerpf(norm_positions[i], norm_positions[invert_i], invert_percent)
		strum.position.x -= strum.position.x * 2.0 * flip_percent
		strum.position.x *= spacing_mult
		strum.position.y = bounce_pixels * _bounce_mult[bounce_type][i]
		strum.position += position_offset
		
		strum_line.post_strum_process.emit(strum, i)
		recover()

func position_note(note:Note):
	make_backup()
	strum_line.pre_note_process.emit(note)
	note.position.x = strum_line.strums[note.lane_id].position.x \
					+ wavy * sin((Conductor.cur_pos - note.hit_time) / Conductor.crochet * PI * wavy_intensity) # wavy mod
					
	note.note.rotation = strum_line.strums[note.lane_id].rotation
	
	note.position.y = strum_line.strums[note.lane_id].position.y \
					+ strum_line.speed * 450 * (Conductor.cur_pos - note.hit_time) # basic positioning
	strum_line.post_note_process.emit(note)
	recover()

func make_backup():
	for prop in prop_list:
		_backup[prop] = get(prop)

func recover():
	for prop in prop_list:
		set(prop, _backup[prop])

func _init(line):
	for prop in get_property_list():
		if not prop["name"].begins_with("_"):
			prop_list.append(prop["name"])
	
	strum_line = line
	for strum in strum_line.strums:
		norm_positions.append(strum.position.x)
