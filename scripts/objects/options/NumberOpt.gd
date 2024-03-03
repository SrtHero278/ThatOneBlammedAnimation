extends SpinBox

@export var option_name:String = "framerate"
@export var default_value:float = 120

func _ready():
	value = Config.get_opt(option_name, default_value)
	value_changed.connect(value_change)
	value_change(value)
	get_line_edit().focus_mode = Control.FOCUS_CLICK

func value_change(new_value):
	Config.set_opt(option_name, new_value)
