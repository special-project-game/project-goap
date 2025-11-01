# EatFoodAction.gd
extends GOAPAction
class_name EatFoodAction

## GOAP Action: Eat food to restore hunger

const EAT_RANGE: float = 20.0
var eat_timer: float = 0.0
const EAT_DURATION: float = 2.0

func _setup_action() -> void:
	action_name = "EatFood"
	cost = 1.0
	
	# Preconditions: must have food and be hungry
	add_precondition("has_food", true)
	add_precondition("is_hungry", true)
	
	# Effects: no longer hungry, no longer have food
	add_effect("is_hungry", false)
	add_effect("has_food", false)

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	eat_timer = 0.0
	print(agent.name, ": Starting to eat food")

func perform(agent: Node, delta: float) -> bool:
	# Stop moving
	agent.velocity = Vector2.ZERO
	
	eat_timer += delta
	
	if eat_timer >= EAT_DURATION:
		# Consume food from inventory (which also restores hunger)
		if agent.has_node("GOAPAgent"):
			var goap_agent = agent.get_node("GOAPAgent")
			if goap_agent.has_method("consume_food"):
				goap_agent.consume_food(1)
				print(agent.name, ": Finished eating! Hunger restored.")
			else:
				print(agent.name, ": ERROR - GOAPAgent doesn't have consume_food method!")
		
		return true
	
	return false

func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	agent.velocity = Vector2.ZERO
