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
	# Always very low priority - only chosen when nothing else to do
	# Removed the +5.0 bonus as it was preventing resource gathering
	return base_priority
