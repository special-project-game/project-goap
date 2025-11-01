# FindTreeAction.gd
extends GOAPAction
class_name FindTreeAction

## GOAP Action: Navigate to the nearest tree

@onready var scanner_component: Area2D
@onready var navigation_agent: NavigationAgent2D

const ARRIVED_THRESHOLD: float = 30.0

func _setup_action() -> void:
	action_name = "FindTree"
	cost = 1.0
	
	# No preconditions - can always look for a tree
	
	# Effects: now near a tree
	add_effect("near_tree", true)

func is_valid(agent: Node, world_state: Dictionary) -> bool:
	# Check if there are any trees available
	return _find_nearest_tree(agent) != null

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	
	# Get references
	if agent.has_node("ScannerComponent"):
		scanner_component = agent.get_node("ScannerComponent")
	if agent.has_node("NavigationAgent2D"):
		navigation_agent = agent.get_node("NavigationAgent2D")
	
	# Find target tree
	target = _find_nearest_tree(agent)
	
	if is_instance_valid(target) and navigation_agent:
		# Cache the position before await in case tree gets freed
		var target_pos = target.global_position
		await agent.get_tree().physics_frame
		navigation_agent.target_position = target_pos
		print(agent.name, ": Navigating to tree at ", target_pos)

func perform(agent: Node, delta: float) -> bool:
	# Always check validity before accessing target properties
	if not is_instance_valid(target):
		return false # Failed - no tree
	
	if not navigation_agent:
		return false # Failed - no navigation
	
	# Check if we've arrived (safe now that we validated target)
	var distance_to_tree = agent.global_position.distance_to(target.global_position)
	if distance_to_tree < ARRIVED_THRESHOLD:
		print(agent.name, ": Arrived near tree")
		agent.velocity = Vector2.ZERO
		return true
	
	# Update navigation target
	navigation_agent.target_position = target.global_position
	
	# Move towards tree
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

func _find_nearest_tree(agent: Node) -> Node:
	if not scanner_component:
		if agent.has_node("ScannerComponent"):
			scanner_component = agent.get_node("ScannerComponent")
		else:
			return null
	
	var nearby_bodies = scanner_component.get_overlapping_bodies()
	var nearest_tree: Node = null
	var nearest_distance: float = INF
	
	for body in nearby_bodies:
		if body.is_in_group("trees"):
			var distance = agent.global_position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_tree = body
	
	return nearest_tree
