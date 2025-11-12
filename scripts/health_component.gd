extends Node2D
class_name HealthComponent

@export var MAX_HEALTH := 10.0
var health : float

func _ready():
	health = MAX_HEALTH

func damage(attack):
	health -= attack
	
	var sprite2d = owner.get_node("Sprite2D") # I assume every being has sprite2D
	sprite2d.set_modulate(Color(1.0, 0.0, 0.0, 1.0))
	await get_tree().create_timer(0.2).timeout
	sprite2d.set_modulate(Color(1.0, 1.0, 1.0, 1.0))
	
	if health <= 0:
		print("person queue freed by Person's code")
		get_parent().queue_free()
	
