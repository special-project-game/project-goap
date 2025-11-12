extends Area2D
class_name HitBoxComponent

@export var attack_component : Attack
@onready var collision_shape_2d = $CollisionShape2D


func _ready():
	collision_shape_2d.set_debug_color(Color(0.3, 0.5, 0.9, 0.5))

#func attack():
	#if not attack_component:
		#return
	#
	#if attack_component.can_attack():
		#attack_component.attack(target)
		

# hurtboxes store health component
# hitboxes store attack component
 #detect whether person hitbox touches tree hurtbox
# if person can attack, run attack(), emit signal: attacking
# tree hurtbox catch the signal and run damage()
