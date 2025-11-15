# DayNightCycleUI.gd
extends Control

@onready var day_label_background: Label = %DayLabelBackground
@onready var day_label: Label = %DayLabel
@onready var time_label_background: Label = %TimeLabelBackground
@onready var time_label: Label = %TimeLabel
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_daytime(day: int, hour: int, minute: int) -> void:
	day_label.text = "Day: " + str(day+1)
	day_label_background.text = day_label.text
	time_label.text = str(hour) + ":" + str(minute)
	time_label_background.text = time_label.text
