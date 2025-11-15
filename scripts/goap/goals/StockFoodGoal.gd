# StockFoodGoal.gd
extends GOAPGoal
class_name StockFoodGoal

## Goal: Maintain a stock of food items in inventory for emergencies
## This ensures the person always has food available when hungry

@export var desired_food_count: int = 3

func _setup_goal() -> void:
	goal_name = "StockFood"
	base_priority = 7.0 # Medium priority - higher than wood gathering (5.0), lower than immediate hunger (10.0)
	
	# Desired state: have food (the planner will keep executing until food_count >= 3)
	# We check actual satisfaction in is_satisfied() based on inventory count
	add_desired_state("has_food", true)

func get_priority(agent: Node, world_state: Dictionary) -> float:
	var food_count = world_state.get("food_count", 0)
	
	# If already hungry, let SatisfyHungerGoal handle it
	if world_state.get("is_hungry", false):
		return 0.0
	
	# If we have enough food, goal is satisfied - no priority
	if food_count >= desired_food_count:
		return 0.0
	
	# Keep priority high until fully stocked
	# Stay above LevelUpGoal (5.0) for all incomplete states
	var shortage = desired_food_count - food_count
	var urgency = float(shortage) / float(desired_food_count)
	
	# Minimum priority 5.5 when we have 2/3, max 7.0 when empty
	return base_priority * (0.8 + 0.2 * urgency) # Range: 5.6 to 7.0

func is_satisfied(world_state: Dictionary) -> bool:
	# Goal is satisfied when we have enough food AND has_food is true
	# has_food acts as a flag that gets set to true when food_count >= 3
	# This allows the planner to find a path (has_food becomes true after actions)
	# and the runtime check ensures we actually have the items
	return world_state.get("has_food", false)
