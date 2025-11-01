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

## Called every frame while the action is running
## Returns true when complete, false while still running
func perform(agent: Node, delta: float) -> bool:
	return true

## Called when the action completes or is interrupted
func on_exit(agent: Node) -> void:
	is_running = false
	target = null

## Get the cost of this action (can be dynamic based on world state)
func get_cost(agent: Node, world_state: Dictionary) -> float:
	return cost

## Reset the action to its initial state
func reset() -> void:
	is_running = false
	target = null
