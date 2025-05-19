extends CharacterBody2D

@export var move_speed : float = 10.0
@export var animation_tree : AnimationTree

var direction: Vector2
var wander_time: float

func randomize_wander():	
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	direction = direction.normalized()
	print(direction)
	wander_time = randf_range(0, 10)

func _ready():
	call_deferred("randomize_wander")

func _process(delta):
	if wander_time > 0:
		wander_time -= delta
	else:
		
		randomize_wander()

func _physics_process(delta):
	velocity = direction * move_speed
	
	if velocity == Vector2.ZERO:
		pass
	else:
		animation_tree.set("parameters/Walk/blend_position", velocity.normalized())

	move_and_slide()
	
