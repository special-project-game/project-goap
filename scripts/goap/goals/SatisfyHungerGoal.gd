# SatisfyHungerGoal.gd
extends GOAPGoal
class_name SatisfyHungerGoal

## Goal: Satisfy hunger by eating food

@export var hunger_threshold: float = 70.0

func _setup_goal() -> void:
	goal_name = "SatisfyHunger"
	base_priority = 10.0 # Very high priority
	
	# Desired state: not hungry
	add_desired_state("is_hungry", false)

func get_priority(agent: Node, world_state: Dictionary) -> float:
	var hunger = world_state.get("hunger", 0.0)
	
	if hunger < hunger_threshold:
		return 0.0 # Not hungry
	
	# Priority increases with hunger level
	var hunger_ratio = hunger / 100.0
	return base_priority * hunger_ratio

func is_satisfied(world_state: Dictionary) -> bool:
	return not world_state.get("is_hungry", false)
