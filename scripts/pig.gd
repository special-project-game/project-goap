extends CharacterBody2D

const SPEED : float = 10.0

@export var move_speed : float = SPEED
@export var animation_tree : AnimationTree
@onready var health_component = $HealthComponent

var direction : Vector2
var wander_time : float
var thinking : bool = false
var last_facing_direction := Vector2(0, -1)

func randomize_wander():
	thinking = false
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	direction = direction.normalized()
	wander_time = randf_range(0, 10)
	print("Pig Health: " + str(health_component.health))

func _ready():
	animation_tree.active = true
	call_deferred("randomize_wander")

func _process(delta):
	if wander_time < 3:
		thinking = true

	if wander_time > 0:
		wander_time -= delta
	else:
		randomize_wander()

func _physics_process(delta):
	if thinking:
		move_speed = 0.0
	else:
		move_speed = SPEED

	velocity = direction * move_speed
	
	var idle = !velocity
	if !idle:
		last_facing_direction = velocity.normalized()

	
	if velocity == Vector2.ZERO:
		pass
	else:
		animation_tree.set("parameters/Walk/blend_position", last_facing_direction.x)
		move_and_slide()
	
