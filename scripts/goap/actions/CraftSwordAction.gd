# CraftSwordAction.gd
extends GOAPAction
class_name CraftSwordAction

## GOAP Action: Craft a sword from wood
## Requires 5 wood, consumes it, and creates a sword

const WOOD_REQUIRED: int = 5
const CRAFT_TIME: float = 2.0 # Time in seconds to craft sword

var craft_timer: float = 0.0

func _setup_action() -> void:
	action_name = "CraftSword"
	cost = 3.0
	
	# Preconditions: none - we'll check wood_count dynamically
	# (We can't use exact value preconditions for numeric comparisons)
	
	# Effects: gain sword, lose wood
	add_effect("has_sword", true)

func check_preconditions(world_state: Dictionary) -> bool:
	# Override to check if we have enough wood
	var wood_count = world_state.get("wood_count", 0)
	return wood_count >= WOOD_REQUIRED

func apply_effects(world_state: Dictionary) -> Dictionary:
	# Override to properly decrement wood_count
	var new_state = super.apply_effects(world_state)
	new_state["wood_count"] = max(0, new_state.get("wood_count", 0) - WOOD_REQUIRED)
	new_state["sword_count"] = new_state.get("sword_count", 0) + 1
	return new_state

func is_valid(agent: Node, world_state: Dictionary) -> bool:
	# Always return true for planning purposes
	# The planner will simulate wood_count changes
	# We check if we ACTUALLY have enough wood in on_enter()
	return true

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	craft_timer = 0.0
	print(agent.name, ": Starting to craft sword...")

func perform(agent: Node, delta: float) -> bool:
	craft_timer += delta
	
	if craft_timer >= CRAFT_TIME:
		# Crafting complete - consume wood and add sword
		var goap_agent = agent.get_node_or_null("GOAPAgent")
		if goap_agent:
			if goap_agent.has_method("consume_wood"):
				goap_agent.consume_wood(WOOD_REQUIRED)
			
			if goap_agent.has_method("add_sword"):
				goap_agent.add_sword(1)
			
			print(agent.name, ": Crafted a sword! Used ", WOOD_REQUIRED, " wood")
		else:
			print(agent.name, ": ERROR - Could not find GOAPAgent to craft sword")
		
		return true # Action complete
	
	return false # Still crafting

func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	craft_timer = 0.0
