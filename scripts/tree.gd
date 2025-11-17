extends StaticBody2D

enum States {Baby, Teen, Adult, Old}

@export var state: State
@onready var timer = $Timer
@onready var sprite = $Sprite2D
@onready var apple_sprite = $AppleSprite

var current_state := States.Baby
var has_apple: bool = false
var apple_regen_time: float = 10.0 # Seconds until apple regenerates

func _ready():
	timer.one_shot = true
	enter_state(current_state)
	update_apple_visibility()


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
			has_apple = true
			update_apple_visibility()
		States.Old:
			sprite.frame = 3
			has_apple = true
			update_apple_visibility()


func _on_timer_timeout():
	if current_state == States.Old:
		pass
	else:
		enter_state(current_state + 1)
		print(current_state)

func take_apple() -> bool:
	"""Take an apple from the tree if available"""
	if not has_apple:
		return false
	
	has_apple = false
	update_apple_visibility()
	print(name, ": Apple taken, will regenerate in ", apple_regen_time, " seconds")
	
	# Start regeneration timer
	var regen_timer = Timer.new()
	regen_timer.name = "AppleRegenTimer"
	regen_timer.wait_time = apple_regen_time
	regen_timer.one_shot = true
	regen_timer.timeout.connect(_on_apple_regen)
	add_child(regen_timer)
	regen_timer.start()
	
	return true

func _on_apple_regen():
	"""Called when apple regenerates"""
	# Only regenerate if tree is Adult or Old
	if current_state == States.Adult or current_state == States.Old:
		has_apple = true
		update_apple_visibility()
		print(name, ": Apple regenerated!")
	# Remove the timer after it completes
	if has_node("AppleRegenTimer"):
		get_node("AppleRegenTimer").queue_free()

func update_apple_visibility():
	"""Update the visibility of the apple sprite based on availability"""
	if apple_sprite:
		apple_sprite.visible = has_apple
