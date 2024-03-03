extends Node

const noteskins:PackedStringArray = ["idk", "delta", "funkin"]
const notesizes:PackedFloat32Array = [0.7, 0.65, 0.7]
enum PlayLane {PLAYER, OPPONENT, CAM_TARGET, ALL, BOTPLAY}

var options:ConfigFile

func _ready():
	options = ConfigFile.new()
	if FileAccess.file_exists("user://idkOptions.cfg"):
		options.load("user://idkOptions.cfg")
	Overlay.cur_vol = get_opt("volume", 0.5)

func get_opt(opt:StringName, default:Variant):
	return options.get_value("Options", opt, default)
	
func set_opt(opt:StringName, val:Variant):
	options.set_value("Options", opt, val)
	if has_method("SET_OPT" + opt):
		call("SET_OPT" + opt, val)

func save():
	options.save("user://idkOptions.cfg")

func SET_OPTantialiasing(val:Variant):
	RenderingServer.viewport_set_default_canvas_item_texture_filter(get_viewport().get_viewport_rid(), RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_LINEAR if val else RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST)

func SET_OPTframerate(val:Variant):
	Engine.max_fps = val
