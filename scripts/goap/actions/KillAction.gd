# KillAction.gd
extends GOAPAction
class_name KillAction

# GOAP Action: Kill prey

@onready var scanner_component: Area2D
@onready var hit_box_component: HitBoxComponent
@onready var target_health_component: HealthComponent
@onready var navigation_agent: NavigationAgent2D

const KILL_RANGE : float = 20.0

var current_target_health: float = 0

func _setup_action() -> void:
	action_name = "KillAction"
	cost = 2.0
	
	add_precondition("near_prey", true)
	
	add_effect("has_killed", true)
	add_effect("near_prey", false)
	

func is_valid(_agent: Node, _world_state: Dictionary) -> bool:
	return true

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	
	target = _find_nearest_prey(agent)

	if agent.has_node("ScannerComponent"):
		scanner_component = agent.get_node("ScannerComponent")
	if agent.has_node("HitBoxComponent"):
		hit_box_component = agent.get_node("HitBoxComponent")
	if agent.has_node("NavigationAgent2D"):
		navigation_agent = agent.get_node("NavigationAgent2D")
	
	if target.has_node("HealthComponent"):
		target_health_component = target.get_node("HealthComponent")

func perform(agent: Node, delta: float) -> bool:
	if not is_instance_valid(target):
		return true
		
	var distance_to_target = agent.global_position.distance_to(target.global_position)
	
	if distance_to_target > 5.0:
		var direction = agent.global_position.direction_to(target.global_position)
		agent.velocity = direction * agent.move_speed
		return false
	
	#if agent.global_position.distance_to(target.global_position) > 5:
		#target = _find_nearest_prey(agent)
	if target_health_component:
		current_target_health = target_health_component.health
	
	print("PREDATOR'S TARGET: ", target, "\nTARGET'S HEALTH: ", current_target_health, "\nDISTANCE TO TARGET: ", agent.global_position.distance_to(target.global_position), "\n")
	
	if hit_box_component:
		hit_box_component.attack()
	
	if current_target_health <= 0 and agent.has_node("GOAPAgent"):
		var goap_agent = agent.get_node("GOAPAgent")
		if goap_agent.has_method("add_kill_exp"):
			goap_agent.add_kill_exp(1)
	
		if is_instance_valid(target):
			target.queue_free()
	
		

	return false
		

func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	agent.velocity = Vector2.ZERO

func _find_nearest_prey(agent: Node) -> Node:
	if not scanner_component:
		if agent.has_node("ScannerComponent"):
			scanner_component = agent.get_node("ScannerComponent")
		else:
			return null
	
	var nearby_bodies = scanner_component.get_overlapping_bodies()
	var nearest_prey: Node = null
	var nearest_distance: float = INF
	
	for body in nearby_bodies:
		if body.is_in_group("person"):
			var distance = agent.global_position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_prey = body
	
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
