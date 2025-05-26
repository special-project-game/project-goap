extends State

@onready var animation_tree = %AnimationTree
@onready var move_speed : float = owner.move_speed

var direction : Vector2
var wander_time : float

func randomize_wander():	
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	direction = direction.normalized()
	wander_time = randf_range(0, 1)

func Enter():
	call_deferred("randomize_wander")

func Update(delta):
	if wander_time > 0:
		wander_time -= delta
	else:
		randomize_wander()

func Physics_Update(delta):
	owner.velocity = direction * move_speed
	if direction == Vector2.ZERO:
		pass
	else:
		animation_tree.set("parameters/Walk/blend_position", direction.x)
	
