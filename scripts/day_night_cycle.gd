# DayNightCycle.gd
extends Node2D

@onready var directional_light_2d = %DirectionalLight2D
@onready var canvas_layer = $CanvasLayer
@onready var ui = $CanvasLayer/DayNightCycleUI

enum TIME_OF_THE_DAY {DAWN, MORNING, NOON, AFTERNOON, DUSK, NIGHT, MIDNIGHT}
#const TIME_TO_INITIAL_HOUR = {
	#TIME_OF_THE_DAY.DAWN: 5,
	#TIME_OF_THE_DAY.MORNING: 6,
	#TIME_OF_THE_DAY.NOON: 12,
	#TIME_OF_THE_DAY.AFTERNOON: 13,
	#TIME_OF_THE_DAY.DUSK: 18,
	#TIME_OF_THE_DAY.NIGHT: 19,
	#TIME_OF_THE_DAY.MIDNIGHT: 0,
#}

@export var gradient: GradientTexture1D
@export var MINUTES_PER_REAL_SECOND: float = 1.0 # How many in-game minutes pass per real second (1.0 = realistic, 60.0 = 1 hour per second)
@export var INITIAL_HOUR: int = 12:
	set(h):
		INITIAL_HOUR = h
		time = INITIAL_HOUR * MINUTES_PER_HOUR


const MINUTES_PER_DAY = 1440
const MINUTES_PER_HOUR = 60

signal time_tick(day: int, hour: int, minute: int)
signal night_started()
signal night_ended()

var time: float = 0.0
var past_minute: float = -1.0

var hour: int
var minute: int
var time_of_the_day: TIME_OF_THE_DAY

var is_night: bool = false


func _ready():
	time = INITIAL_HOUR * MINUTES_PER_HOUR
	canvas_layer.visible = true
	time_tick.connect(ui.set_daytime)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# delta is in seconds, so multiply by MINUTES_PER_REAL_SECOND to get in-game minutes elapsed
	time += delta * MINUTES_PER_REAL_SECOND
	#is_night = time_of_the_day == TIME_OF_THE_DAY.NIGHT
		
	# Convert time (in minutes) to radians for the day/night cycle (0 to 2*PI over 1440 minutes)
	var time_radians = (time / MINUTES_PER_DAY) * 2 * PI
	var value = (sin(time_radians - PI / 2) + 1.0) / 2.0
	var color = gradient.gradient.sample(value)
	directional_light_2d.color = color
	_recalculate_time()
	
	if hour == 19:
		night_started.emit()
	if hour == 5:
		night_ended.emit()
	
	
func _recalculate_time() -> void:
	var total_minutes = int(time)
	var day = int(total_minutes / MINUTES_PER_DAY)
	var current_day_minutes = total_minutes % MINUTES_PER_DAY
	hour = int(current_day_minutes / MINUTES_PER_HOUR)
	minute = int(current_day_minutes % MINUTES_PER_HOUR)
	
	if past_minute != minute:
		past_minute = minute
		time_tick.emit(day, hour, minute)

func set_time(new_time: float) -> void:
	time = new_time
	_recalculate_time()

func get_time() -> float:
	return time
