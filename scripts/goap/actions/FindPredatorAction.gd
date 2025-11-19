# FindPredatorAction.gd
extends GOAPAction
class_name FindPredatorAction

## GOAP Action: Find predator to attack when Person has a sword
## Similar to FindPreyAction but for Person agents hunting Predators

@onready var navigation_agent: NavigationAgent2D
@onready var scanner_component: Area2D
@onready var goap_target: GOAPAgent

const ARRIVED_THRESHOLD: float = 10.0

func _setup_action() -> void:
	action_name = "FindPredator"
	cost = 1.0
	
	# Preconditions: Must have a sword to hunt predators
	add_precondition("has_sword", true)
	
	# Effects: We'll be near a predator
	add_effect("near_predator", true)

func is_valid(agent: Node, world_state: Dictionary) -> bool:
	# Action is only valid if we have a sword and predators exist
	if not world_state.get("has_sword", false):
		return false
	
	# Check if there are any predators available
	var predator_found = _find_nearest_predator(agent)
	return predator_found != null

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	
	# Get references
	if agent.has_node("ScannerComponent"):
		scanner_component = agent.get_node("ScannerComponent")
	if agent.has_node("NavigationAgent2D"):
		navigation_agent = agent.get_node("NavigationAgent2D")
	
	target = _find_nearest_predator(agent)
	
	if is_instance_valid(target):
		if target.has_node("GOAPAgent"):
			goap_target = target.get_node("GOAPAgent")
			goap_target.is_target = true
			goap_target.chaser = agent
		
		if navigation_agent:
			var target_pos = target.global_position
			await agent.get_tree().physics_frame
			navigation_agent.target_position = target_pos
			print(agent.name, ": Hunting predator at ", target_pos)

func perform(agent: Node, delta: float) -> bool:
	# Check if target is still valid
	if not is_instance_valid(target):
		agent.velocity = Vector2.ZERO
		target = _find_nearest_predator(agent)
		return false
	
	# Periodically recalculate to find nearest predator (every 2 seconds by default)
	if should_recalculate_target(delta):
		var new_target = _recalculate_target(agent)
		if new_target != null and new_target != target:
			print(agent.name, ": Switching to a closer predator")
			# Update the old target
			if is_instance_valid(target) and target.has_node("GOAPAgent"):
				var old_goap = target.get_node("GOAPAgent")
				old_goap.is_target = false
				old_goap.chaser = null
			
			target = new_target
			
			# Update the new target
			if target.has_node("GOAPAgent"):
				goap_target = target.get_node("GOAPAgent")
				goap_target.is_target = true
				goap_target.chaser = agent
			
			if navigation_agent:
				navigation_agent.target_position = target.global_position
	
	# Check if we've arrived near the predator
	var distance_to_predator = agent.global_position.distance_to(target.global_position)
	if distance_to_predator < ARRIVED_THRESHOLD:
		print(agent.name, ": Arrived near predator")
		agent.velocity = Vector2.ZERO
		return true
	
	if not navigation_agent:
		# Fallback: direct movement without navigation
		var direction = agent.global_position.direction_to(target.global_position)
		agent.velocity = direction * agent.move_speed
		return false
	
	# Update navigation target
	navigation_agent.target_position = target.global_position
	
	# Move towards predator
	if not navigation_agent.is_navigation_finished():
		var next_position = navigation_agent.get_next_path_position()
		var direction = agent.global_position.direction_to(next_position)
		agent.velocity = direction * agent.move_speed
	else:
		# Navigation says finished but we're not at target - use direct movement
		var direction = agent.global_position.direction_to(target.global_position)
		agent.velocity = direction * agent.move_speed
	
	return false

func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	agent.velocity = Vector2.ZERO
	
	# Clear navigation target
	if navigation_agent:
		navigation_agent.target_position = agent.global_position

func _find_nearest_predator(agent: Node) -> Node:
	"""Find the nearest predator within scanner range"""
	# Check if we are being chased first
	if agent.has_node("GOAPAgent"):
		var goap_agent = agent.get_node("GOAPAgent")
		if is_instance_valid(goap_agent.chaser):
			return goap_agent.chaser

	if not scanner_component:
		if agent.has_node("ScannerComponent"):
			scanner_component = agent.get_node("ScannerComponent")
		else:
			return null
	
	var nearby_bodies = scanner_component.get_overlapping_bodies()
	var nearest_predator: Node = null
	var nearest_distance: float = INF
	
	var predators_checked = 0
	var predators_unreachable = 0
	
	for body in nearby_bodies:
		if body.is_in_group("predator"):
			predators_checked += 1
			
			# Check if this predator is reachable via navigation
			if not _is_predator_reachable(agent, body):
				predators_unreachable += 1
				continue
			
			var distance = agent.global_position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_predator = body
	
	if predators_checked > 0:
		print(agent.name, ": Scanned ", predators_checked, " predators, ", predators_unreachable, " were unreachable, found: ", nearest_predator != null)
	
	return nearest_predator

func _is_predator_reachable(agent: Node, predator: Node) -> bool:
	"""Check if a predator position is reachable via navigation"""
	if not is_instance_valid(predator):
		return false
	
	if not navigation_agent:
		if agent.has_node("NavigationAgent2D"):
			navigation_agent = agent.get_node("NavigationAgent2D")
		else:
			return true # Assume reachable if no navigation agent
	
	var map_rid = navigation_agent.get_navigation_map()
	if not map_rid.is_valid():
		return true # Navigation not ready, assume reachable
	
	# Get closest navigable point to predator
	var predator_pos = predator.global_position
	var closest_point = NavigationServer2D.map_get_closest_point(map_rid, predator_pos)
	
	# Check if the closest point is reasonably close to the predator
	var distance_to_closest = predator_pos.distance_to(closest_point)
	var max_acceptable_distance = 50.0
	
	if distance_to_closest > max_acceptable_distance:
		return false
	
	# Try to get a path from agent to predator
	var path = NavigationServer2D.map_get_path(
		map_rid,
		agent.global_position,
		closest_point,
		true
	)
	
	# If path is empty or invalid, predator is unreachable
	return path.size() >= 2

## Override from base class - recalculate nearest predator
func _recalculate_target(agent: Node) -> Node:
	return _find_nearest_predator(agent)
