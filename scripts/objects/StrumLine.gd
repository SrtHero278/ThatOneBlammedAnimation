class_name StrumLine extends Node2D

@onready var notes = $Notes
@onready var held_notes = $HeldNotes
var note_material:ShaderMaterial = null
var temp_note = load("res://scripts/objects/Note.tscn").instantiate()

var hit_window:float = 0.15
var speed:float = 2.7:
	get: return speed
	set(new_speed):
		if speed == new_speed: return
		
		for note in notes.get_children():
			if note.sustain_length > 0.0:
				note.resize_sustain(note.sustain_length, new_speed)
		speed = new_speed

@export var cpu_input:bool = false
var actions:Array[String] = ["note_left", "note_down", "note_up", "note_right"]

var character:Character

var strums:Array[Sprite2D] = []
var glows:Array[Node2D] = []
var anim_play:Array[AnimationPlayer] = []
var mods:StrumMods

func make_note(note):
	var new_note = temp_note.duplicate()
	new_note.hit_time = note.time
	new_note.lane_id = note.lane
	new_note.crochet = note.crochet
	new_note.last_change = note.last_change - Gameplay.chart.song_offset
	new_note.sustain_length = note.length
	new_note.material = note_material
	notes.add_child(new_note)
	new_note.resize_sustain(note.length, speed)

func _ready():
	Note.load_textures()
	if Config.noteskins[Config.get_opt("note_skin", 0)] == "funkin":
		note_material = ShaderMaterial.new()
		note_material.shader = load("res://assets/images/notes/funkin/funkinNote.gdshader")
	
	for i in 4:
		var strum = load("res://scenes/game/receptor_skins/%s.tscn" % Config.noteskins[Config.get_opt("note_skin", 0)]).instantiate()
		strum.position.x = [-160, -54, 54, 160][i]
		strum.rotation_degrees = [0, -90, 90, 180][i]
		add_child(strum)
		strums.append(strum)
		glows.append(strum.get_node("Glow"))
		anim_play.append(strum.get_node("Anims"))
	move_child(notes, 5)
	move_child(held_notes, 6)
	mods = StrumMods.new(self)

func _process(delta):
	mods.position_strums()
	
	for note:Note in notes.get_children():
		mods.position_note(note)
		
		if cpu_input and note.hit_time < Conductor.cur_pos:
			hit_note(note)
			anim_play[note.lane_id].play("glow")
			anim_play[note.lane_id].seek(0.0)
		if not cpu_input and note.hit_time - Conductor.cur_pos < -hit_window:
			character.play_anim(["singLEFTmiss", "singDOWNmiss", "singUPmiss", "singRIGHTmiss"][note.lane_id], true)
			note_miss.emit(self, note)
			note.queue_free()
			
	var sin_mult = sin(fmod(Conductor.float_beat, 1.0) * PI) * 0.35 + 0.35
	for note:Note in held_notes.get_children():
		note.position = strums[note.lane_id].position
		note.note.modulate.a = sin_mult
		
		note.sustain_length -= delta
		if note.sustain_length <= 0:
			note.queue_free()
			glows[note.lane_id].modulate = note.modulate
			anim_play[note.lane_id].play("glow")
			anim_play[note.lane_id].seek(0.0)
		else:
			note.resize_sustain(note.sustain_length, speed)

func _unhandled_key_input(event):
	if not cpu_input:
		for i in 4:
			if event.is_action_pressed(actions[i]):
				press(i)
				break
			elif event.is_action_released(actions[i]):
				release(i)
				break
			
func press(index:int):
	var anim_to_play:String = "ghost"
	
	for note:Note in notes.get_children():
		if (note.lane_id != index): continue
		
		if abs(Conductor.cur_pos - note.hit_time) < hit_window:
			hit_note(note)
			anim_to_play = "glow"
			break
	anim_play[index].play(anim_to_play)
	anim_play[index].seek(0.0)

func hit_note(note:Note):
	character.play_anim(["singLEFT", "singDOWN", "singUP", "singRIGHT"][note.lane_id], true)
	note_hit.emit(self, note)
	if note.sustain_length <= 0:
		note.queue_free()
		glows[note.lane_id].modulate = note.modulate
	else:
		notes.remove_child(note)
		held_notes.add_child(note)
		note.sustain_length += note.hit_time - Conductor.cur_pos
		note.resize_sustain(note.sustain_length, speed)

func release(index:int):
	for note:Note in held_notes.get_children():
		if (note.lane_id != index): continue
		
		if (note.sustain_length > note.crochet * 0.25):
			note_miss.emit(self, note)
		note.queue_free()

signal note_hit(line:StrumLine, note:Note)
signal note_miss(line:StrumLine, note:Note)

signal pre_strum_process(strum:Node2D, index:int)
signal post_strum_process(strum:Node2D, index:int)

signal pre_note_process(note:Note)
signal post_note_process(note:Note)
