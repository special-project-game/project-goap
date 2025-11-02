# RestAction.gd
extends GOAPAction
class_name RestAction

## GOAP Action: Rest/idle when nothing else to do

var rest_timer: float = 0.0
const REST_DURATION: float = 3.0

func _setup_action() -> void:
	action_name = "Rest"
	cost = 10.0 # High cost - only do this when nothing else to do
	
	# No preconditions - can always rest
	
	# Effects: feeling rested
	add_effect("is_resting", true)

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	rest_timer = 0.0
	print(agent.name, ": Resting...")

func perform(agent: Node, delta: float) -> bool:
	# Stop moving
	agent.velocity = Vector2.ZERO
	
	rest_timer += delta
	
	if rest_timer >= REST_DURATION:
		return true
	
	return false

func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	agent.velocity = Vector2.ZERO
