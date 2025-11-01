# GetAppleAction.gd
extends GOAPAction
class_name GetAppleAction

## GOAP Action: Get an apple from a tree to eat later

const GET_RANGE: float = 20.0

func _setup_action() -> void:
	action_name = "GetApple"
	cost = 1.0
	
	# Preconditions: must be near a tree and hungry
	add_precondition("near_tree", true)
	add_precondition("is_hungry", true)
	
	# Effects: have food to eat
	add_effect("has_food", true)
	add_effect("near_tree", false)

func is_valid(_agent: Node, _world_state: Dictionary) -> bool:
	# Valid as long as trees exist (FindTreeAction will get us there)
	return true

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	print(agent.name, ": Getting apple from tree")

func perform(agent: Node, delta: float) -> bool:
	# Stop moving
	agent.velocity = Vector2.ZERO
	
	# Instantly get apple (could add animation/delay here)
	print(agent.name, ": Got an apple!")
	
	# Update agent's food inventory
	if agent.has_node("GOAPAgent"):
		var goap_agent = agent.get_node("GOAPAgent")
		if goap_agent.has_method("add_food"):
			goap_agent.add_food(1)
	
	return true

func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	agent.velocity = Vector2.ZERO
