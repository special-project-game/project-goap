# RunAwayAction.gd
extends GOAPAction
class_name RunAwayAction

@onready var navigation_agent : NavigationAgent2D

var goap_agent: GOAPAgent
var chaser: Node
const SAFETY_THRESHOLD: float = 50.0
const FLEE_DISTANCE_MULTIPLIER: float = 2.0

func _setup_action() -> void:
	action_name = "RunAway"
	cost = 1.0
	
	add_precondition("is_safe", false)
	add_precondition("has_sword", false)
	
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
	
	if current_position.distance_to(chaser_position) >= SAFETY_THRESHOLD:
		return true
		
	#var direction = current_position - chaser_position
	#direction = direction.normalized()
	#agent.velocity = direction * agent.move_speed
	
	var direction_from_chaser = (current_position - chaser_position).normalized()
	var potential_flee_target_position = current_position + direction_from_chaser * (SAFETY_THRESHOLD * FLEE_DISTANCE_MULTIPLIER)
	
	var map_rid = navigation_agent.get_navigation_map()
	if not map_rid.is_valid():
		print(agent.name, ": Navigation map not ready for flee target validation.")
		# Fallback to simple movement if navigation isn't ready
		var direction_to_flee = (current_position - chaser_position).normalized()
		agent.velocity = direction_to_flee * agent.move_speed
		return false
	
	# Get a path to the potential flee target
	var path = NavigationServer2D.map_get_path(
		map_rid,
		current_position,
		potential_flee_target_position,
		true # optimize for navigation
	)
	
	var actual_flee_target_position = potential_flee_target_position # Default to potential
	
	# Check if the path is valid and gets close enough to the target
	var max_acceptable_distance = 50.0
	if path.size() < 2:
		# Path is invalid or too short. Find the closest reachable point if possible.
		print(agent.name, ": Potential flee target UNREACHABLE - no valid path. Attempting to get alternative path...")
		actual_flee_target_position = NavigationServer2D.map_get_closest_point(map_rid, potential_flee_target_position)
	else:
		var last_point = path[path.size() - 1]
		var distance_to_target = last_point.distance_to(potential_flee_target_position)
		
		if distance_to_target >= max_acceptable_distance:
			print(agent.name, ": Potential flee target UNREACHABLE - path ends ", distance_to_target, " units away (max: ", max_acceptable_distance, "). Aiming for last path point.")
			# If the path doesn't reach the exact target, aim for the last reachable point on the path
			actual_flee_target_position = last_point
		else:
			# The potential target is reachable! Use it.
			actual_flee_target_position = potential_flee_target_position

	navigation_agent.set_target_position(actual_flee_target_position)
	
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var direction_to_next_point = (next_path_position - current_position).normalized()
	agent.velocity = direction_to_next_point * agent.move_speed

	return false
	
	
func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	agent.velocity = Vector2.ZERO
	goap_agent.is_target = false
	goap_agent.chaser = null
	agent.move_speed = agent.DEFAULT_SPEED
	
