# BeSafeGoal.gd
extends GOAPGoal
class_name BeSafeGoal

# Goal: Get to safety by running away from predators

func _ready():
	pass
	
func _setup_goal() -> void:
	goal_name = "BeSafe"
	base_priority = 1.0
	
	add_desired_state("is_safe", true)

func get_priority(agent: Node, world_state: Dictionary) -> float:
	if not world_state["is_safe"]:
		return base_priority + 99
	return base_priority
