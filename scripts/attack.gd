extends Node2D
class_name Attack

@export var attack_damage := 5.0
@export var cooldown_time := 2.0

var target: Node2D

var last_attack_time : float

func can_attack():
	return (Time.get_ticks_msec() / 1000) - last_attack_time >= cooldown_time

func attack(target: Node2D) -> void:
	if not can_attack():
		return

	last_attack_time = Time.get_ticks_msec() / 1000
	
	if is_instance_valid(target) and target.has_node("HurtBoxComponent"):
		var target_hurtbox = target.get_node("HurtBoxComponent")
		target_hurtbox.damage(attack_damage)
		print(owner.name + " attacked " + target.name + ", inflicted: " + str(attack_damage))
	else:
		print(owner.name + " tried to attack an invalid target or target without HurtBoxComponent.")

	#GlobalSignal.Attacking.emit(attack_damage)
	#print(owner.name + " is attacking, atk dmg: " + str(attack_damage))
