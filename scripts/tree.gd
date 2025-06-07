extends StaticBody2D

enum States {Baby, Teen, Adult, Old}

@export var state: State
@onready var timer = $Timer
@onready var sprite = $Sprite2D

var current_state := States.Baby

func _ready():
	timer.one_shot = true
	enter_state(current_state)



func enter_state(new_state: States):
	current_state = new_state
	match current_state:
		States.Baby:
			sprite.frame = 0
			timer.wait_time = 5
			timer.start()
		States.Teen:
			sprite.frame = 1
			timer.wait_time = 10
			timer.start()
		States.Adult:
			sprite.frame = 2
			timer.wait_time = 15
			timer.start()
		States.Old:
			sprite.frame = 3


func _on_timer_timeout():
	if current_state == States.Old:
		pass

	enter_state(current_state + 1)
	print(current_state)
