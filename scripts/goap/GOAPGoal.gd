# GOAPGoal.gd
extends Node
class_name GOAPGoal

## Represents a goal that an agent wants to achieve
## Contains desired world state and priority

@export var goal_name: String = ""
@export var base_priority: float = 1.0

var desired_state: Dictionary = {}

func _init():
	_setup_goal()

## Override this in child classes to set up the desired state
func _setup_goal() -> void:
	pass

## Add a desired state condition
func add_desired_state(key: String, value) -> void:
	desired_state[key] = value

## Calculate the priority of this goal based on current world state
## Override in child classes for dynamic priorities
func get_priority(agent: Node, world_state: Dictionary) -> float:
	return base_priority

## Check if this goal has been satisfied
func is_satisfied(world_state: Dictionary) -> bool:
	for key in desired_state:
		if not world_state.has(key) or world_state[key] != desired_state[key]:
			return false
	return true
