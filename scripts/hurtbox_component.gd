extends Area2D
class_name HurtBoxComponent

@export var health_component : HealthComponent
@onready var collision_shape_2d = $CollisionShape2D

func _ready():
	collision_shape_2d.set_debug_color(Color(0.9, 0.5, 0.3, 0.5))
	

func damage(attack):
	if health_component:
		health_component.damage(attack)
		print("dmg received: " + str(attack))


#func _on_area_entered(hitbox: HitBoxComponent):
	#GlobalSignal.Attacking.connect(receive_attack)
	##print("receive_attacak connected to " + str(owner.name))
#
#func receive_attack(attack_damage):
	#print(owner.name + " IS TAKING DAMAGE")
	#damage(attack_damage)
#
#
#func _on_area_exited(hitbox: HitBoxComponent):
	#GlobalSignal.Attacking.disconnect(receive_attack)
	##if owner:
		##print("receive_attack disconnected from " + str(owner.name))
#
## for person to take damage
