# GetSwordGoal.gd
extends GOAPGoal
class_name GetSwordGoal

## Goal: Craft a sword by gathering enough wood (5 wood needed)
## Higher priority than LevelUpGoal to ensure sword crafting takes precedence

func _ready():
	desired_state.clear()
	_setup_goal()

func _setup_goal() -> void:
	goal_name = "GetSword"
	base_priority = 6.0 # Higher than LevelUpGoal (5.0)
	
	# Desired state: have a sword
	add_desired_state("has_sword", true)

func get_priority(agent: Node, world_state: Dictionary) -> float:
	# If already have a sword, lower priority
	if world_state.get("has_sword", false):
		return 1.0
	
	# If hungry, lower priority (survival first)
	if world_state.get("is_hungry", false):
		return 2.0
	
	# Otherwise, high priority to get sword
	return base_priority
