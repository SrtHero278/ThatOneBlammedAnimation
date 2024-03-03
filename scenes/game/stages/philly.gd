extends Stage

var light_colors:Array[Color] = [
	Color("#31A2FD"),
	Color("#31FD8C"),
	Color("#FB33F5"),
	Color("#FD4531"),
	Color("#FBA633")
]

@onready var buildings = $"0-3/Buildings"
@onready var train = $"1-0/Train"
@onready var train_sound = $TrainSound
@onready var tunnel_wall = $"0-3/TunnelWall"

@export var building_scroll_mult:float = 0.0
var building_scroll_add:float = 0.0
var train_moving:bool = false
var train_cars:int = 8
var train_finishing:bool = false
var train_cooldown:int = 0
var started_moving:bool = false

func _ready():
	super()
	buildings.self_modulate = light_colors[randi_range(0, light_colors.size() - 1)]
	Conductor.beat_hit.connect(beat_hit)

func _process(delta):
	building_scroll_add += delta * building_scroll_mult
	buildings.material.set_shader_parameter("uv_add", building_scroll_add)
	buildings.self_modulate.a = 1.0 - fposmod(Conductor.float_beat * 0.25, 1.0)
	
	if train_sound.get_playback_position() >= 4.7:
		started_moving = true
		game.spectator.play_anim("hairBlow")
		game.spectator.til_dance = 999.0
		
	if started_moving:
		train.position.x -= 400.0 * 24.0 * delta
		
		if train.position.x < -2000.0 and not train_finishing:
			train.position.x = -1150.0
			train_cars -= 1
			train_finishing = train_finishing or train_cars <= 0
			
		if train.position.x < -4000.0 and train_finishing:
			game.spectator.play_anim("hairFall")
			game.spectator.anim_player.animation_finished.connect(func(_name):
				game.spectator.play_anim("danceRight")
				game.spectator.dance_index = 0
			, CONNECT_ONE_SHOT)
			train.position.x = 1480
			
			train_moving = false
			train_sound.stop()
			train_cars = 8
			train_finishing = false
			started_moving = false

func beat_hit(beat):
	if beat % 4 == 0:
		buildings.self_modulate = light_colors[randi_range(0, light_colors.size() - 1)]
		
	if not train_moving: train_cooldown += 1
		
	if beat <= 80 and beat % 8 == 4 and randi_range(1, 10) <= 3 and not train_moving and train_cooldown > 8 and not train_sound.playing:
		train_cooldown = randi_range(-4, 0)
		train_moving = true
		train_sound.play()
