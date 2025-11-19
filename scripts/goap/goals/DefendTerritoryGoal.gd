# DefendTerritoryGoal.gd
extends GOAPGoal
class_name DefendTerritoryGoal

## Goal: Hunt and defeat predators when Person has a sword
## This goal has high priority when armed, making Person agents aggressive

func _ready():
	desired_state.clear()
	_setup_goal()

func _setup_goal() -> void:
	goal_name = "DefendTerritory"
	base_priority = 8.0 # Higher than GetSword (6.0), lower than BeSafe when unarmed
	
	# Desired state: killed a predator
	add_desired_state("has_killed_predator", true)

func get_priority(agent: Node, world_state: Dictionary) -> float:
	# Only active if we have a sword
	if not world_state.get("has_sword", false):
		return 0.0
	
	# If we're hungry, lower priority (survival first)
	if world_state.get("is_hungry", false):
		return 3.0
	
	# If we're unsafe (predator nearby) and have a sword, HIGH priority to fight!
	if not world_state.get("is_safe", true):
		return base_priority + 92.0 # Almost as high as BeSafe, but we fight instead of flee
	
	# Otherwise, moderate priority - patrol for predators
	return base_priority

func is_satisfied(world_state: Dictionary) -> bool:
	# Goal is never truly "satisfied" - we always want to defend territory
	# But we return true if we just killed a predator so we can replan
	return world_state.get("has_killed_predator", false)
