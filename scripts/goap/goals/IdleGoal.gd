# IdleGoal.gd
extends GOAPGoal
class_name IdleGoal

## Goal: Just rest/idle when nothing else to do


func _setup_goal() -> void:
	goal_name = "Idle"
	base_priority = 1.0 # Very low priority - fallback goal
	
	# Desired state: resting
	add_desired_state("is_resting", true)

func get_priority(agent: Node, world_state: Dictionary) -> float:
	# Always low priority - only chosen when nothing else to do
	if owner.is_in_group("monster"):
		var prey_available = world_state.get("prey_available", false)
		
		if not prey_available:
			print("prey_available: ", prey_available)
			return base_priority + 5.0
	elif owner.is_in_group("person"):
		var has_target = world_state.get("has_target", false)
		
		if not has_target:
			print("has_target: ", has_target)
			return base_priority + 5.0

	return base_priority
