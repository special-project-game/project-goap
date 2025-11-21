extends Node2D

@onready var directional_light_2d = %DirectionalLight2D
@onready var canvas_layer = $CanvasLayer
@onready var ui = $CanvasLayer/DayNightCycleUI

@onready var day_player: AudioStreamPlayer = $DayAmbience
@onready var night_player: AudioStreamPlayer = $NightAmbience

enum TIME_OF_THE_DAY {DAWN, MORNING, NOON, AFTERNOON, DUSK, NIGHT, MIDNIGHT}

@export var gradient: GradientTexture1D
@export var MINUTES_PER_REAL_SECOND: float = 1.0
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
var is_night: bool = false


func _ready():
	time = INITIAL_HOUR * MINUTES_PER_HOUR

	canvas_layer.visible = true
	time_tick.connect(ui.set_daytime)

	day_player.volume_db = -60
	night_player.volume_db = -60

	day_player.playing = false
	night_player.playing = false

	_play_day_ambience()


func _process(delta):
	time += delta * MINUTES_PER_REAL_SECOND

	var time_radians = (time / MINUTES_PER_DAY) * 2 * PI
	var value = (sin(time_radians - PI / 2) + 1.0) / 2.0
	directional_light_2d.color = gradient.gradient.sample(value)

	_recalculate_time()

	if hour == 19 and not is_night:
		is_night = true
		_on_night_started()

	if hour == 5 and is_night:
		is_night = false
		_on_night_ended()


func _recalculate_time():
	var total_minutes = int(time)
	var day = int(total_minutes / MINUTES_PER_DAY)
	var current_day_minutes = total_minutes % MINUTES_PER_DAY

	hour = int(current_day_minutes / MINUTES_PER_HOUR)
	minute = current_day_minutes % MINUTES_PER_HOUR

	if past_minute != minute:
		past_minute = minute
		time_tick.emit(day, hour, minute)

func _crossfade(from_player: AudioStreamPlayer, to_player: AudioStreamPlayer, to_target_db: float, fade_time := 2.0):
	if from_player and not from_player.playing:
		from_player.play()
	if to_player and not to_player.playing:
		to_player.play()

	to_player.volume_db = -20

	var t := create_tween()
	t.tween_property(to_player, "volume_db", to_target_db, fade_time)\
		.set_trans(Tween.TRANS_SINE)

	t.parallel().tween_property(from_player, "volume_db", -25, fade_time)\
		.set_trans(Tween.TRANS_SINE)

	t.finished.connect(func():
		var cleanup := create_tween()
		cleanup.tween_property(from_player, "volume_db", -60, 1.5)
		cleanup.finished.connect(func():
			from_player.stop()
		)
	)


func _play_day_ambience():
	_crossfade(night_player, day_player, -10)


func _play_night_ambience():
	_crossfade(day_player, night_player, -2)


func _on_night_started():
	_play_night_ambience()


func _on_night_ended():
	_play_day_ambience()
