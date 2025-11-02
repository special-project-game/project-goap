# FindFoodAction.gd
extends GOAPAction
class_name FindFoodAction

## GOAP Action: Navigate to the nearest food source (berry bush)

@onready var scanner_component: Area2D
@onready var navigation_agent: NavigationAgent2D

const ARRIVED_THRESHOLD: float = 30.0

func _setup_action() -> void:
	action_name = "FindFood"
	cost = 1.0
	
	# Precondition: must be hungry
	add_precondition("is_hungry", true)
	
	# Effects: now near food
	add_effect("near_food", true)

func is_valid(agent: Node, world_state: Dictionary) -> bool:
	if not super.is_valid(agent, world_state):
		return false
	
	# Check if there is food available
	return _find_nearest_food(agent) != null

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	
	# Get references
	if agent.has_node("ScannerComponent"):
		scanner_component = agent.get_node("ScannerComponent")
	if agent.has_node("NavigationAgent2D"):
		navigation_agent = agent.get_node("NavigationAgent2D")
	
	# Find target food
	target = _find_nearest_food(agent)
	
	if target and navigation_agent:
		await agent.get_tree().physics_frame
		navigation_agent.target_position = target.global_position
		print(agent.name, ": Navigating to food at ", target.global_position)

func perform(agent: Node, delta: float) -> bool:
	if not is_instance_valid(target):
		return false # Failed - no food
	
	if not navigation_agent:
		return false
	
	# Check if we've arrived
	var distance_to_food = agent.global_position.distance_to(target.global_position)
	if distance_to_food < ARRIVED_THRESHOLD:
		print(agent.name, ": Arrived near food")
		agent.velocity = Vector2.ZERO
		return true
	
	# Update navigation target
	navigation_agent.target_position = target.global_position
	
	# Move towards food
	if not navigation_agent.is_navigation_finished():
		var next_position = navigation_agent.get_next_path_position()
		var direction = agent.global_position.direction_to(next_position)
		agent.velocity = direction * agent.move_speed
	else:
		agent.velocity = Vector2.ZERO
		return true
	
	return false

func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	agent.velocity = Vector2.ZERO
	
	# Clear navigation target to remove debug visualization
	if navigation_agent:
		navigation_agent.target_position = agent.global_position

func _find_nearest_food(agent: Node) -> Node:
	if not scanner_component:
		if agent.has_node("ScannerComponent"):
			scanner_component = agent.get_node("ScannerComponent")
		else:
			return null
	
	var nearby_bodies = scanner_component.get_overlapping_bodies()
	var nearest_food: Node = null
	var nearest_distance: float = INF
	
	for body in nearby_bodies:
		if body.is_in_group("food") or body.is_in_group("berry_bush"):
			var distance = agent.global_position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_food = body
	
	return nearest_food
