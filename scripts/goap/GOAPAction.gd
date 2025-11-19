# GOAPAction.gd
extends Node
class_name GOAPAction

## Base class for all GOAP actions
## Defines preconditions, effects, and how to execute the action

@export var action_name: String = ""
@export var cost: float = 1.0

var preconditions: Dictionary = {}
var effects: Dictionary = {}
var target: Node = null
var is_running: bool = false

# Periodic target recalculation
@export var target_recalc_interval: float = 2.0 ## How often to recalculate nearest target (in seconds)
var time_since_last_recalc: float = 0.0

func _init():
	_setup_action()

## Override this in child classes to set up preconditions and effects
func _setup_action() -> void:
	pass

## Add a precondition that must be met for this action to be valid
func add_precondition(key: String, value) -> void:
	preconditions[key] = value

## Add an effect that this action will have on the world state
func add_effect(key: String, value) -> void:
	effects[key] = value

## Check if this action's preconditions are met given the current world state
func check_preconditions(world_state: Dictionary) -> bool:
	for key in preconditions:
		if not world_state.has(key) or world_state[key] != preconditions[key]:
			return false
	return true

## Apply this action's effects to the world state
func apply_effects(world_state: Dictionary) -> Dictionary:
	var new_state = world_state.duplicate()
	for key in effects:
		new_state[key] = effects[key]
	return new_state

## Check if this action is valid in the current context
## Override in child classes for specific validation (e.g., is target available?)
func is_valid(agent: Node, world_state: Dictionary) -> bool:
	return check_preconditions(world_state)

## Called when the action starts executing
func on_enter(agent: Node) -> void:
	is_running = true
	time_since_last_recalc = 0.0 # Reset timer when action starts

## Called every frame while the action is running
## Returns true when complete, false while still running
func perform(agent: Node, delta: float) -> bool:
	return true

## Called when the action completes or is interrupted
func on_exit(agent: Node) -> void:
	is_running = false
	# Don't clear target here - let subsequent actions in the plan use it
	# Target will be cleared when action is reset or invalidated

## Get the cost of this action (can be dynamic based on world state)
func get_cost(agent: Node, world_state: Dictionary) -> float:
	return cost

## Reset the action to its initial state
func reset() -> void:
	is_running = false
	target = null
	time_since_last_recalc = 0.0

## Helper method for actions that need to periodically recalculate their target
## Override _recalculate_target() in child classes to implement custom logic
func should_recalculate_target(delta: float) -> bool:
	time_since_last_recalc += delta
	if time_since_last_recalc >= target_recalc_interval:
		time_since_last_recalc = 0.0
		return true
	return false

## Override this in child classes to implement target recalculation
## Should return the new target node or null if no valid target found
func _recalculate_target(agent: Node) -> Node:
	return target # Default: keep current target
