class_name Chart extends Resource

class ChartNote extends Resource:
	var time:float
	var lane:int
	var parent:int
	var length:float
	var crochet:float
	var last_change:float
	
	func _init(_time:float, _lane:int, _parent:int, _length:float, _crochet:float, _last:float):
		self.time = _time
		self.lane = _lane
		self.parent = _parent
		self.length = _length
		self.crochet = _crochet
		self.last_change = _last
class ChartEvent extends Resource:
	var beat:float
	var name:String
	var params:Array[Variant]
	
	func _init(_beat:float, _name:String, _params:Array[Variant]):
		self.beat = _beat
		self.name = _name
		self.params = _params

var extra_data:Dictionary = {}

var characters:Array[String] = ["bf", "gf", "pico"]
var stage:String = "philly"

var bpm:float = 120
var bpm_changes:Array[Array] = []

var events:Array[ChartEvent] = []
var notes:Array[ChartNote] = []
var speed:float = 2.7

var song_offset:float = 0.0

func _init(_bpm:float):
	self.bpm = _bpm

static func parse_chart(song:String, diff:String):
	var da_chart = null
	
	var file_formats = [
		["res://assets/songs/%s/%s.json" % [song, diff.to_lower()], 	Chart.parse_fnf],
		["res://assets/songs/%s/%s.sm" % [song, song], 				SmParser.parse_sm]
	]
	for path in file_formats:
		if FileAccess.file_exists(path[0]):
			da_chart = path[1].call(path[0], diff)
	
	if da_chart == null:
		da_chart = Chart.new(120) # fallback
					
	return da_chart

static func parse_fnf(path:String, _diff):
	var json = JSON.parse_string(FileAccess.get_file_as_string(path)).song
	var chart = Chart.new(json.bpm)
	var must_hit = true
	chart.speed = json.speed
	
	if 'player1' in json: chart.characters[0] = json.player1
	if 'gfVersion' in json: chart.characters[1] = json.gfVersion
	if 'player2' in json: chart.characters[2] = json.player2
	if 'stage' in json: chart.stage = json.stage
	if 'songOffset' in json: chart.song_offset = json.songOffset
	
	var cur_bpm:float = json.bpm
	var cur_crochet:float = 60 / cur_bpm
	var cur_time:float = 0.0
	var cur_beat:float = 0.0
	var last_time:float = 0.0
	
	var times:Array[Array] = [[], [], [], [], [], [], [], []]
	for sec in json.notes:
		if "changeBPM" in sec and sec.changeBPM:
			cur_bpm = sec.bpm
			cur_crochet = 60 / sec.bpm
			last_time = cur_time
			chart.bpm_changes.append([cur_bpm, cur_crochet, cur_time, cur_beat])
		if "mustHitSection" in sec and must_hit != sec.mustHitSection:
			must_hit = sec.mustHitSection
			chart.events.append(ChartEvent.new(cur_beat, "Change Camera Target", [sec.mustHitSection]))
			
		for note in sec.sectionNotes:
			var round_time = roundf(note[0] * 100)
			var check_dir = (int(note[1]) + 4 * int(sec.mustHitSection)) % 8
			var dir:int = note[1]
		
			if dir < 0 or times[check_dir].has(round_time): print("bye bye! %s | %s" % [check_dir, round_time * 0.01]); continue
			times[check_dir].append(round_time)
			chart.notes.append(ChartNote.new(
				note[0] * 0.001,
				dir % 4,
				int((dir < 4) != sec.mustHitSection),
				note[2] * 0.001,
				cur_crochet,
				last_time
			))
			
		var sec_beats = sec.lengthInSteps * 0.25 if (not "sectionBeats" in sec) else sec.sectionBeats # PSYCH ENGIN-
		cur_time += cur_crochet * sec_beats
		cur_beat += sec_beats
		
	chart.notes.sort_custom(func(a, b): return a.time < b.time)
	return chart

static func get_tracks(song:String):
	var tracks:Array[AudioStreamPlayer] = []
	
	var audio_path = "res://assets/songs/%s/audio" % song
	var audio_files = DirAccess.get_files_at(audio_path)
	audio_path += "/"
	
	var exts = ["ogg", "mp3"]
	var added_files = []
	for file in audio_files:
		if file.ends_with(".import"): # to prevent duplicates caused by ".import" files
			file = file.get_basename()
		if added_files.has(file):
			continue
			
		if exts.has(file.get_extension()):
			var music:AudioStreamPlayer = AudioStreamPlayer.new()
			music.stream = load(audio_path + file)
			tracks.append(music)
			added_files.append(file)
			
	return tracks;

static func get_scripts(song:String):
	var script_path = "res://assets/songs/%s/scripts" % song
	if not DirAccess.dir_exists_absolute(script_path): return []
	
	var scripts:Array[ScriptNode] = []
	var script_files = DirAccess.get_files_at(script_path)
	script_path += "/"

	var found:Array[String] = []
	for file in script_files:
		file = file.replace(".remap", "").replace(".gdc", ".gd")
		var ext = file.get_extension()
		var basename = file.get_basename()

		if ext == "gd" and found.has(basename + ".tscn"):
			continue
		if ext == "tscn" and found.has(basename + ".gd"):
			found[found.find(basename + ".gd")] = file
			continue
		found.append(file)
		
	for file in found:
		var script = load(script_path + file).new() if file.get_extension() == "gd" else load(script_path + file).instantiate()
		scripts.append(script)
		
	return scripts
