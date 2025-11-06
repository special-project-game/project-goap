# FindPreyAction.gd
extends GOAPAction
class_name FindPreyAction

# GOAP Action: Find prey to kill using NavigationAgent2D
@onready var navigation_agent: NavigationAgent2D
@onready var scanner_component: Area2D

const ARRIVED_THRESHOLD : float = 10.0

func _setup_action() -> void:
	action_name = "FindPrey"
	cost = 1.0
	
	add_effect("near_prey", true)
	#add_precondition("is_resting", true)
	print("predator setup action done")

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	print("PREDATOR ON ENTER DONE")
	
	# Get references
	if agent.has_node("ScannerComponent"):
		scanner_component = agent.get_node("ScannerComponent")
	if agent.has_node("NavigationAgent2D"):
		navigation_agent = agent.get_node("NavigationAgent2D")
	
	target = _find_nearest_prey(agent)
	
	if is_instance_valid(target) and navigation_agent:
		var target_pos = target.global_position
		await agent.get_tree().physics_frame
		navigation_agent.target_position = target_pos
		print(agent.name, ": Navigating to prey at ", target_pos)
		print(agent.name, ": NavigationAgent is_navigation_finished: ", navigation_agent.is_navigation_finished())
		print(agent.name, ": Distance to target: ", navigation_agent.distance_to_target())


func perform(agent: Node, _delta: float) -> bool:
	# Check if target is valid FIRST
	if not is_instance_valid(target):
		print("target invalid")
		# Don't print here - is_valid() will handle the replan
		agent.velocity = Vector2.ZERO
		target = _find_nearest_prey(agent)
		return false
	
	# Check if we've arrived
	var distance_to_prey = agent.global_position.distance_to(target.global_position)
	if distance_to_prey < ARRIVED_THRESHOLD:
		print(agent.name, ": Arrived near prey")
		agent.velocity = Vector2.ZERO
		return true
	
	if not navigation_agent:
		# Fallback: direct movement without navigation
		var direction = agent.global_position.direction_to(target.global_position)
		agent.velocity = direction * agent.move_speed
		return false
	
	# Check if target is still reachable (less frequently - trust is_valid() to catch this)
	# This is a backup check during execution
	
	# Update navigation target
	navigation_agent.target_position = target.global_position
	
	# Move towards prey
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
	
	# Clear navigation target to remove debug visualization
	if navigation_agent:
		navigation_agent.target_position = agent.global_position

func _find_nearest_prey(agent: Node) -> Node:
	if not scanner_component:
		if agent.has_node("ScannerComponent"):
			scanner_component = agent.get_node("ScannerComponent")
		else:
			return null
			
	var nearby_bodies = scanner_component.get_overlapping_bodies()
	print(nearby_bodies)
	var nearest_prey: Node = null
	var nearest_distance: float = INF
	
	var preys_checked = 0
	var preys_unreachable = 0
	
	#var replan_called = false
	#if nearby_bodies.is_empty() and agent.has_node("GOAPAgent"):
		#var goap_agent = agent.get_node("GOAPAgent")
		#if not replan_called:
			#goap_agent.call_deferred("replan")
			#print("replan called")
			#replan_called = true
			#await get_tree().create_timer(5.0).timeout
			#replan_called = false
	
	for body in nearby_bodies:
		if body.is_in_group("person"):
			preys_checked += 1
			# Check if this prey is reachable via navigation
			if not _is_prey_reachable(agent, body):
				preys_unreachable += 1
				continue
			
			var distance = agent.global_position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_prey = body
	
	if preys_checked > 0:
		print(agent.name, ": Scanned ", preys_checked, " preys, ", preys_unreachable, " were unreachable, found: ", nearest_prey != null)

	return nearest_prey

func _is_prey_reachable(agent: Node, prey: Node) -> bool:
	"""Check if a prey position is reachable via navigation"""
	if not is_instance_valid(prey):
		return false
	
	if not navigation_agent:
		if agent.has_node("NavigationAgent2D"):
			navigation_agent = agent.get_node("NavigationAgent2D")
		else:
			# No navigation agent, do a simple distance check
			return agent.global_position.distance_to(prey.global_position) < 500.0
	
	# Use NavigationServer2D to check if path exists
	var map_rid = navigation_agent.get_navigation_map()
	if not map_rid.is_valid():
		# Navigation not ready yet - reject all preys for now
		print(agent.name, ": Navigation map not ready, rejecting all preys")
		return false
	
	var path = NavigationServer2D.map_get_path(
		map_rid,
		agent.global_position,
		prey.global_position,
		true # optimize for navigation
	)
	
	# If path is empty or too short, position is unreachable
	if path.size() < 2:
		print(agent.name, ": Prey at ", prey.global_position, " UNREACHABLE - no path (size: ", path.size(), ")")
		return false
	
	# Check if the path actually gets close to the target
	var last_point = path[path.size() - 1]
	var distance_to_target = last_point.distance_to(prey.global_position)
	
	# Path must end very close to the target (within a few pixels)
	# If the prey is on water, the path will stop at the shore and this check will fail
	var max_acceptable_distance = 5.0 # Very strict - path must end almost exactly at prey
	if distance_to_target >= max_acceptable_distance:
		print(agent.name, ": Prey at ", prey.global_position, " UNREACHABLE - path ends ", distance_to_target, " units away (max: ", max_acceptable_distance, ")")
		return false
	
	return true
