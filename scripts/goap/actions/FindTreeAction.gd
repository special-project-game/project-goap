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
	# Check if we have a target set
	var has_target = target != null
	
	# If we have a target reference, check if it's still valid
	if has_target:
		if not is_instance_valid(target):
			print(agent.name, ": FindTreeAction.is_valid() - Tree target destroyed/freed, returning FALSE")
			target = null
			return false
		
		# Target is valid, check if reachable
		if not _is_tree_reachable(agent, target):
			print(agent.name, ": FindTreeAction.is_valid() - Tree target unreachable, returning FALSE")
			target = null
			return false
		
		# Target is valid and reachable
		return true
	
	# No target - check if there are any reachable trees available
	print(agent.name, ": FindTreeAction.is_valid() - No target, searching for reachable trees")
	var reachable_tree = _find_nearest_tree(agent)
	if reachable_tree == null:
		print(agent.name, ": FindTreeAction.is_valid() - No reachable trees found, returning FALSE")
		return false
	return true

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
		print(agent.name, ": NavigationAgent is_navigation_finished: ", navigation_agent.is_navigation_finished())
		print(agent.name, ": Distance to target: ", navigation_agent.distance_to_target())

func perform(agent: Node, _delta: float) -> bool:
	# Check if target is valid FIRST
	if not is_instance_valid(target):
		# Don't print here - is_valid() will handle the replan
		agent.velocity = Vector2.ZERO
		return false
	
	# Check if we've arrived
	var distance_to_tree = agent.global_position.distance_to(target.global_position)
	if distance_to_tree < ARRIVED_THRESHOLD:
		print(agent.name, ": Arrived near tree")
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
	
	# Move towards tree
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

func _find_nearest_tree(agent: Node) -> Node:
	if not scanner_component:
		if agent.has_node("ScannerComponent"):
			scanner_component = agent.get_node("ScannerComponent")
		else:
			return null
	
	var nearby_bodies = scanner_component.get_overlapping_bodies()
	var nearest_tree: Node = null
	var nearest_distance: float = INF
	
	var trees_checked = 0
	var trees_unreachable = 0
	
	for body in nearby_bodies:
		if body.is_in_group("trees"):
			trees_checked += 1
			# Check if this tree is reachable via navigation
			if not _is_tree_reachable(agent, body):
				trees_unreachable += 1
				continue
			
			var distance = agent.global_position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_tree = body
	
	if trees_checked > 0:
		print(agent.name, ": Scanned ", trees_checked, " trees, ", trees_unreachable, " were unreachable, found: ", nearest_tree != null)
	
	return nearest_tree

func _is_tree_reachable(agent: Node, tree: Node) -> bool:
	"""Check if a tree position is reachable via navigation"""
	if not is_instance_valid(tree):
		return false
	
	if not navigation_agent:
		if agent.has_node("NavigationAgent2D"):
			navigation_agent = agent.get_node("NavigationAgent2D")
		else:
			# No navigation agent, do a simple distance check
			return agent.global_position.distance_to(tree.global_position) < 500.0
	
	# Use NavigationServer2D to check if path exists
	var map_rid = navigation_agent.get_navigation_map()
	if not map_rid.is_valid():
		# Navigation not ready yet - reject all trees for now
		return false
	
	var path = NavigationServer2D.map_get_path(
		map_rid,
		agent.global_position,
		tree.global_position,
		true # optimize for navigation
	)
	
	# If path is empty or too short, position is unreachable
	if path.size() < 2:
		return false
	
	# Check if the path actually gets close to the target
	var last_point = path[path.size() - 1]
	var distance_to_target = last_point.distance_to(tree.global_position)
	
	# If the last point of the path is too far from target, it's unreachable
	if distance_to_target >= ARRIVED_THRESHOLD * 2.0:
		return false
	
	return true
