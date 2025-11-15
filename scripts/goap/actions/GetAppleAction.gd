# GetAppleAction.gd
extends GOAPAction
class_name GetAppleAction

## GOAP Action: Get an apple from a tree to eat later

const GET_RANGE: float = 20.0

func _setup_action() -> void:
	action_name = "GetApple"
	cost = 1.0
	
	# Preconditions: must be near a tree (from FindAppleTree action specifically)
	add_precondition("near_apple_tree", true)
	
	# Effects: have food to eat
	# Note: has_food_stock is managed by world state based on actual inventory count
	add_effect("has_food", true)
	add_effect("near_apple_tree", false)

func is_valid(agent: Node, _world_state: Dictionary) -> bool:
	# Check if we have a valid tree target from FindAppleTreeAction
	# AND that tree has an apple available
	if agent.has_node("GOAPAgent"):
		var goap_agent = agent.get_node("GOAPAgent")
		var find_action = _get_find_apple_tree_action(goap_agent)
		if find_action and is_instance_valid(find_action.target):
			var tree = find_action.target
			if "has_apple" in tree:
				return tree.has_apple
			return true # Fallback for trees without apple system
	
	# Valid as long as trees with apples exist
	return true

func _get_find_apple_tree_action(goap_agent: Node):
	"""Helper to get the FindAppleTreeAction from the GOAP agent"""
	for child in goap_agent.get_children():
		if child.has_method("_setup_action") and child.action_name == "FindAppleTree":
			return child
	return null

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	print(agent.name, ": Getting apple from tree")

func perform(agent: Node, _delta: float) -> bool:
	# Stop moving
	agent.velocity = Vector2.ZERO
	
	# Get the tree target
	if agent.has_node("GOAPAgent"):
		var goap_agent = agent.get_node("GOAPAgent")
		var find_action = _get_find_apple_tree_action(goap_agent)
		if find_action and is_instance_valid(find_action.target):
			var tree = find_action.target
			
			# Try to take apple from tree
			if tree.has_method("take_apple") and tree.take_apple():
				print(agent.name, ": Got an apple from ", tree.name, "!")
				
				# Update agent's food inventory
				if goap_agent.has_method("add_food"):
					goap_agent.add_food(1)
				
				return true
			else:
				print(agent.name, ": Failed to get apple - tree has no apples!")
				return false
	
	print(agent.name, ": Failed to get apple - no valid tree target!")
	return false

func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	agent.velocity = Vector2.ZERO
