# GOAPAgent.gd
extends Node
class_name GOAPAgent

## GOAP Agent that manages goals, actions, and planning

signal plan_found(plan: Array)
signal plan_failed()
signal goal_completed(goal: GOAPGoal)
signal action_started(action: GOAPAction)
signal action_completed(action: GOAPAction)

@export var entity: Node ## Reference to the entity (Person, etc.)
@export var update_interval: float = 0.5 ## How often to replan (in seconds)

var planner: GOAPPlanner
var available_actions: Array[GOAPAction] = []
var available_goals: Array[GOAPGoal] = []
var world_state: Dictionary = {}

var current_plan: Array[GOAPAction] = []
var current_goal: GOAPGoal = null
var current_action: GOAPAction = null
var current_action_index: int = 0

var time_since_update: float = 0.0
var is_planning: bool = false

func _ready():
	planner = GOAPPlanner.new()
	add_child(planner)
	
	# Collect actions and goals from children
	var agent_name = "Agent"
	if entity:
		agent_name = entity.name
	
	for child in get_children():
		if child is GOAPAction:
			available_actions.append(child)
			print(agent_name, ": Registered action: ", child.action_name)
		elif child is GOAPGoal:
			available_goals.append(child)
			print(agent_name, ": Registered goal: ", child.goal_name)
	
	print(agent_name, ": Total actions: ", available_actions.size(), ", Total goals: ", available_goals.size())
	
	call_deferred("_initialize_world_state")

func _initialize_world_state() -> void:
	# Override or extend this in subclasses to set initial world state
	pass

func _process(delta: float):
	if not entity or available_goals.is_empty():
		return
	
	time_since_update += delta
	
	# Update world state and check for replanning
	if time_since_update >= update_interval:
		print(entity.name, ": Update triggered. current_goal=", current_goal.goal_name if current_goal else "None", " plan_size=", current_plan.size())
		time_since_update = 0.0
		_update_world_state()
		
		# Check if we need to select a new goal:
		# 1. No current goal
		# 2. Current goal is satisfied
		# 3. We have a goal but no plan (plan failed or completed)
		var needs_replan = not current_goal or current_goal.is_satisfied(world_state) or current_plan.is_empty()
		
		if needs_replan:
			print(entity.name, ": Goal check - current_goal exists: ", current_goal != null, " is_satisfied: ", current_goal.is_satisfied(world_state) if current_goal else "N/A", " plan_empty: ", current_plan.is_empty())
			if current_goal and current_goal.is_satisfied(world_state):
				goal_completed.emit(current_goal)
			_select_new_goal()
	
	# Execute current plan
	if current_action and not is_planning:
		var action_complete = current_action.perform(entity, delta)
		
		if action_complete:
			action_completed.emit(current_action)
			
			# Apply action effects to the actual world state
			print(entity.name, ": Applying effects for ", current_action.action_name)
			for key in current_action.effects:
				print(entity.name, ":   ", key, " = ", current_action.effects[key])
				world_state[key] = current_action.effects[key]
			
			current_action.on_exit(entity)
			current_action = null
			current_action_index += 1
			
			# Check if plan is complete
			if current_action_index >= current_plan.size():
				_on_plan_completed()
			else:
				_start_next_action()

## Update the world state based on current conditions
func _update_world_state() -> void:
	# Override in subclasses to update based on entity state
	pass

## Select the highest priority goal
func _select_new_goal() -> void:
	var highest_priority_goal: GOAPGoal = null
	var highest_priority: float = -1.0
	
	print(entity.name, ": Selecting new goal from ", available_goals.size(), " goals")
	print(entity.name, ": World state: has_wood=", world_state.get("has_wood"), " is_resting=", world_state.get("is_resting"), " is_hungry=", world_state.get("is_hungry"))
	
	for goal in available_goals:
		var is_satisfied = goal.is_satisfied(world_state)
		var priority = goal.get_priority(entity, world_state)
		print(entity.name, ": Goal ", goal.goal_name, " - Satisfied: ", is_satisfied, " Priority: ", priority)
		
		if is_satisfied:
			continue
		
		if priority > highest_priority:
			highest_priority = priority
			highest_priority_goal = goal
	
	print(entity.name, ": Selected goal: ", highest_priority_goal.goal_name if highest_priority_goal else "None", " Priority: ", highest_priority)
	
	# Always set a new goal, even if it's the same
	# This handles cases where the previous plan failed
	if highest_priority_goal:
		if highest_priority_goal != current_goal or current_plan.is_empty():
			_set_new_goal(highest_priority_goal)
	elif current_goal:
		# No valid unsatisfied goals - clear current goal
		current_goal = null
		current_plan.clear()

## Set a new goal and create a plan
func _set_new_goal(goal: GOAPGoal) -> void:
	# Cancel current action if any
	if current_action:
		current_action.on_exit(entity)
		current_action = null
	
	current_goal = goal
	current_plan.clear()
	current_action_index = 0
	
	if not goal:
		return
	
	# Create a plan
	is_planning = true
	current_plan = planner.plan(entity, available_actions, world_state, goal)
	is_planning = false
	
	if current_plan.is_empty():
		print(entity.name, ": Failed to find plan for goal: ", goal.goal_name)
		plan_failed.emit()
		current_goal = null
	else:
		print(entity.name, ": Plan found for ", goal.goal_name, " with ", current_plan.size(), " actions")
		plan_found.emit(current_plan)
		_start_next_action()

## Start the next action in the plan
func _start_next_action() -> void:
	if current_action_index < current_plan.size():
		current_action = current_plan[current_action_index]
		current_action.on_enter(entity)
		action_started.emit(current_action)
		print(entity.name, ": Starting action: ", current_action.action_name)

## Called when the entire plan is completed
func _on_plan_completed() -> void:
	print(entity.name, ": Plan completed for goal: ", current_goal.goal_name if current_goal else "None")
	current_plan.clear()
	current_action_index = 0
	# Force immediate replan by resetting timer
	time_since_update = update_interval

## Get current world state value
func get_state(key: String, default = null):
	return world_state.get(key, default)

## Set world state value
func set_state(key: String, value) -> void:
	world_state[key] = value

## Force immediate replanning
func replan() -> void:
	if current_goal:
		_set_new_goal(current_goal)
