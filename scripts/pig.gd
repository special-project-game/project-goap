extends CharacterBody2D

const SPEED : float = 10.0

@export var move_speed : float = SPEED
@export var animation_tree : AnimationTree
@onready var health_component = $HealthComponent

func _physics_process(delta):
	move_and_slide()
	
