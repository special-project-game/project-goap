extends Node2D
class_name Attack

@export var attack_damage := 5.0
@export var cooldown_time := 2.0

var last_attack_time : float

func can_attack():
	return (Time.get_ticks_msec() / 1000) - last_attack_time >= cooldown_time

func attack():
	if not can_attack():
		return

	last_attack_time = Time.get_ticks_msec() / 1000

	GlobalSignal.Attacking.emit(attack_damage)
	print(owner.name + " is attacking, atk dmg: " + str(attack_damage))
