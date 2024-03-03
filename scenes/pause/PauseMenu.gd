extends CanvasLayer

@onready var music = $Music
var is_title:bool = false

var cur_opt:String = "Select an Option"
var opt_lerp:float = 0.0
const PRESS_SIZE = Vector2(0.9, 0.9)
@onready var options = $Options
@onready var option_label = $OptionLabel

@onready var resume = $Options/Resume
@onready var restart = $Options/Restart
@onready var icon = $Icon
var icon_back:Node2D
@onready var bg = $BG
@onready var viewport = get_viewport()

func _ready():
	is_title = self == get_tree().current_scene
	if is_title:
		options.remove_child(resume)
		resume.queue_free()
		restart.name = "Start Song"
		icon.texture = load("res://assets/images/pause/logo.png")
		music.stream = load("res://assets/music/title.ogg")
		
		icon_back = icon.duplicate()
		icon_back.modulate = Color.BLACK
		add_child(icon_back)
		move_child(icon_back, 1)
	else:
		bg.modulate.a = 0.5
		create_tween().tween_property(icon, "position:y", 200.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	music.play()
	
	var child_count = options.get_child_count()
	var width = 75 * child_count
	for i in child_count:
		options.get_child(i).position.x = 75 * i - width * 0.5

func _process(delta):
	if is_title:
		icon.position.y = 200 + 25 * sin(Conductor.cur_pos * PI / 0.6)
		icon_back.position.y = 200 + 25 * sin((Conductor.cur_pos + 0.075) * PI / 0.6)
	
	var mouse_pos = viewport.get_mouse_position()
	for button in options.get_children():
		var hovered = button.get_global_rect().has_point(mouse_pos)
		var target_y:float = -20.0 if hovered else -37.5
		button.position.y = lerpf(button.position.y, target_y, delta * 4.0)
		button.scale = PRESS_SIZE if hovered and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else Vector2.ONE
		button.modulate.v = 0.8 if hovered and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else 1.0
		
		if hovered and cur_opt != button.name:
			cur_opt = button.name
			option_label.text = cur_opt
			opt_lerp = 1.0

	opt_lerp = lerpf(opt_lerp, 0.0, delta * 8.0)
	option_label.modulate.a = 1.0 - opt_lerp
	option_label.position.y = 450 - opt_lerp * 10.0

func _on_resume_pressed():
	create_tween().tween_property(icon, "position:y", -300.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD).finished.connect(finish_resume)

func finish_resume():
	get_tree().paused = false
	queue_free()

func _on_songs_pressed():
	get_tree().paused = false
	Gameplay.chart = Chart.parse_chart("blammed b3", "hard")
	Gameplay.song_folder = "blammed b3"
	if get_tree().current_scene != self:
		Conductor.beat_hit.disconnect($"../".beat_hit)
	get_tree().change_scene_to_file("res://scenes/game/Gameplay.tscn")
