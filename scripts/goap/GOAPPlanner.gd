# GOAPPlanner.gd
extends Node
class_name GOAPPlanner

## A* based planner that creates action sequences to achieve goals

class PlanNode:
	var state: Dictionary
	var parent: PlanNode
	var action: GOAPAction
	var cost: float
	var heuristic: float
	
	func _init(p_state: Dictionary, p_parent: PlanNode, p_action: GOAPAction, p_cost: float, p_heuristic: float):
		state = p_state
		parent = p_parent
		action = p_action
		cost = p_cost
		heuristic = p_heuristic
	
	func get_total_cost() -> float:
		return cost + heuristic

## Plan a sequence of actions to achieve a goal
func plan(agent: Node, available_actions: Array[GOAPAction], world_state: Dictionary, goal: GOAPGoal) -> Array[GOAPAction]:
	print("\n=== GOAP PLANNER DEBUG ===")
	print("Agent: ", agent.name)
	print("Goal: ", goal.goal_name)
	print("Current world state: ", world_state)
	print("Goal desired state: ", goal.desired_state)
	
	# Filter valid actions
	var valid_actions: Array[GOAPAction] = []
	for action in available_actions:
		var is_valid = action.is_valid(agent, world_state)
		print("  Action '", action.action_name, "' is_valid: ", is_valid)
		if is_valid:
			print("    - Preconditions: ", action.preconditions)
			print("    - Effects: ", action.effects)
			valid_actions.append(action)
	
	print("Valid actions: ", valid_actions.size(), " / ", available_actions.size())
	
	if valid_actions.is_empty():
		print("!!! No valid actions available !!!")
		return []
	
	# A* search
	var open_list: Array[PlanNode] = []
	var closed_list: Array[Dictionary] = []
	
	# Start node
	var start_node = PlanNode.new(
		world_state,
		null,
		null,
		0.0,
		_calculate_heuristic(world_state, goal.desired_state)
	)
	print("Starting heuristic: ", start_node.heuristic)
	open_list.append(start_node)
	
	var iterations = 0
	var max_iterations = 100
	
	while not open_list.is_empty() and iterations < max_iterations:
		iterations += 1
		# Get node with lowest cost
		var current_node = _get_lowest_cost_node(open_list)
		open_list.erase(current_node)
		
		# Check if goal is satisfied
		if goal.is_satisfied(current_node.state):
			print("!!! GOAL SATISFIED! Found plan with ", iterations, " iterations")
			return _reconstruct_plan(current_node)
		
		# Add to closed list
		closed_list.append(current_node.state)
		
		# Explore neighbors (possible actions)
		for action in valid_actions:
			var preconditions_met = action.check_preconditions(current_node.state)
			if iterations <= 3: # Only print first few iterations
				print("  Iteration ", iterations, ": Testing '", action.action_name, "' - preconditions met: ", preconditions_met)
				if not preconditions_met:
					print("    Required: ", action.preconditions, " | Current: ", current_node.state)
			
			if not preconditions_met:
				continue
			
			var new_state = action.apply_effects(current_node.state)
			if iterations <= 3:
				print("    Would create state: ", new_state)
			
			# Skip if already explored
			if _state_in_list(new_state, closed_list):
				continue
			
			var new_cost = current_node.cost + action.get_cost(agent, current_node.state)
			var new_heuristic = _calculate_heuristic(new_state, goal.desired_state)
			
			var new_node = PlanNode.new(new_state, current_node, action, new_cost, new_heuristic)
			
			# Check if better path exists in open list
			var existing_node = _find_node_with_state(new_state, open_list)
			if existing_node:
				if new_cost < existing_node.cost:
					open_list.erase(existing_node)
					open_list.append(new_node)
			else:
				open_list.append(new_node)
	
	# No plan found
	print("!!! Planning failed after ", iterations, " iterations !!!")
	print("Final open list size: ", open_list.size())
	print("Closed list size: ", closed_list.size())
	return []

## Calculate heuristic (number of unsatisfied conditions)
func _calculate_heuristic(current_state: Dictionary, desired_state: Dictionary) -> float:
	var unsatisfied: float = 0.0
	for key in desired_state:
		if not current_state.has(key) or current_state[key] != desired_state[key]:
			unsatisfied += 1.0
	return unsatisfied

## Get the node with the lowest total cost
func _get_lowest_cost_node(nodes: Array[PlanNode]) -> PlanNode:
	var lowest = nodes[0]
	for node in nodes:
		if node.get_total_cost() < lowest.get_total_cost():
			lowest = node
	return lowest

## Check if a state exists in the list
func _state_in_list(state: Dictionary, list: Array[Dictionary]) -> bool:
	for s in list:
		if _states_equal(s, state):
			return true
	return false

## Find a node with a specific state
func _find_node_with_state(state: Dictionary, nodes: Array[PlanNode]) -> PlanNode:
	for node in nodes:
		if _states_equal(node.state, state):
			return node
	return null

## Check if two states are equal
func _states_equal(state1: Dictionary, state2: Dictionary) -> bool:
	if state1.size() != state2.size():
		return false
	for key in state1:
		if not state2.has(key) or state1[key] != state2[key]:
			return false
	return true

## Reconstruct the plan from the goal node
func _reconstruct_plan(goal_node: PlanNode) -> Array[GOAPAction]:
	var action_plan: Array[GOAPAction] = []
	var current = goal_node
	
	while current.parent != null:
		action_plan.push_front(current.action)
		current = current.parent
	
	return action_plan
