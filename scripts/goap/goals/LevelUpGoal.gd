# LevelUpGoal.gd
extends GOAPGoal
class_name LevelUpGoal

## Goal: Level up by gathering enough experience/wood

@export var wood_required: int = 10

func _ready():
	print(owner)
	print(owner.name)
	desired_state.clear()
	_setup_goal()
	

func _setup_goal() -> void:
	goal_name = "LevelUp"
	base_priority = 5.0
	
	# Desired state: have enough wood to level up
	# If Agent is predator, replace has_wood with has_killed
	
	if owner:
		if owner.is_in_group("monster"):
				add_desired_state("has_killed", true)
				add_desired_state("is_hungry", false)
		else:
			add_desired_state("has_wood", true)
	else:
		add_desired_state("has_wood", true)
		
	print(desired_state)

func get_priority(agent: Node, world_state: Dictionary) -> float:
	# Higher priority if we're hungry
	if not world_state.get("is_hungry", false):
		return 1.0 # Lower priority when not hungry
	return base_priority

# Use base class is_satisfied() - checks if has_wood = true
# But we reset has_wood to false after collecting, so it cycles
