extends Area2D
class_name HurtBoxComponent

@export var health_component : HealthComponent
@onready var collision_shape_2d = $CollisionShape2D

func _ready():
	collision_shape_2d.set_debug_color(Color(0.9, 0.5, 0.3, 0.5))

func damage(attack: Attack):
	if health_component:
		health_component.damage(attack)
