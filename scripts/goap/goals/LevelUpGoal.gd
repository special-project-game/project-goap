# LevelUpGoal.gd
extends GOAPGoal
class_name LevelUpGoal

## Goal: Level up by gathering enough experience/wood

@export var wood_required: int = 10

func _setup_goal() -> void:
	goal_name = "LevelUp"
	base_priority = 5.0
	
	# Desired state: have enough wood to level up
	add_desired_state("has_wood", true)

func get_priority(agent: Node, world_state: Dictionary) -> float:
	# Higher priority if we're not hungry
	if world_state.get("is_hungry", false):
		return 1.0 # Lower priority when hungry
	
	# Always try to gather more wood (continuous goal)
	return base_priority

# Use base class is_satisfied() - checks if has_wood = true
# But we reset has_wood to false after collecting, so it cycles
