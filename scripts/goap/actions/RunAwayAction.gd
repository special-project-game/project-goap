# RunAwayAction.gd
extends GOAPAction
class_name RunAwayAction

@onready var navigation_agent : NavigationAgent2D

var goap_agent: GOAPAgent
var chaser: Node
const SAFETY_THRESHOLD: float = 50.0

func _setup_action() -> void:
	action_name = "RunAway"
	cost = 1.0
	
	add_precondition("is_safe", false)
	
	add_effect("is_safe", true)

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	print(agent.name, ": Running away from predators.")
	
	agent.move_speed += 2.0
	
	if agent.has_node("NavigationAgent2D"):
		navigation_agent = agent.get_node("NavigationAgent2D")
	
	if agent.has_node("GOAPAgent"):
		goap_agent = agent.get_node("GOAPAgent")
		chaser = goap_agent.chaser
	
func perform(agent: Node, delta: float) -> bool:
	if not is_instance_valid(chaser):
		return true

	var current_position = agent.global_position
	var chaser_position = chaser.global_position
	
	var direction = current_position - chaser_position
	direction = direction.normalized()
	agent.velocity = direction * agent.move_speed
	
	if current_position.distance_to(chaser_position) >= SAFETY_THRESHOLD:
		return true
	
	return false
	
	
func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	agent.velocity = Vector2.ZERO
	goap_agent.is_target = false
	goap_agent.chaser = null
	agent.move_speed = agent.DEFAULT_SPEED
	
