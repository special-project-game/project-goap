# FindAppleTreeAction.gd
extends GOAPAction

## GOAP Action: Navigate to the nearest tree that has apples available

var scanner_component: Area2D
var navigation_agent: NavigationAgent2D

const ARRIVED_THRESHOLD: float = 10.0

func _setup_action() -> void:
	action_name = "FindAppleTree"
	cost = 1.0
	
	# No preconditions - can always look for a tree with apples
	
	# Effects: now near a tree that has apples
	add_effect("near_apple_tree", true)

func is_valid(agent: Node, world_state: Dictionary) -> bool:
	# Check if we have a target set
	var has_target = target != null
	
	# If we have a target reference, check if it's still valid and has apples
	if has_target:
		if not is_instance_valid(target):
			print(agent.name, ": FindAppleTreeAction.is_valid() - Tree target destroyed/freed, returning FALSE")
			target = null
			return false
		
		# Check if tree still has apples
		if "has_apple" in target and not target.has_apple:
			print(agent.name, ": FindAppleTreeAction.is_valid() - Tree has no apples, searching for new tree")
			target = null
			return _find_nearest_tree_with_apple(agent) != null
		
		# Target is valid, check if reachable
		if not _is_tree_reachable(agent, target):
			print(agent.name, ": FindAppleTreeAction.is_valid() - Tree target unreachable, returning FALSE")
			target = null
			return false
		
		# Target is valid and reachable and has apple
		return true
	
	# No target - check if there are any reachable trees with apples available
	print(agent.name, ": FindAppleTreeAction.is_valid() - No target, searching for trees with apples")
	var reachable_tree = _find_nearest_tree_with_apple(agent)
	if reachable_tree == null:
		print(agent.name, ": FindAppleTreeAction.is_valid() - No reachable trees with apples found, returning FALSE")
		return false
	return true

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	
	# Get references
	if agent.has_node("ScannerComponent"):
		scanner_component = agent.get_node("ScannerComponent")
	if agent.has_node("NavigationAgent2D"):
		navigation_agent = agent.get_node("NavigationAgent2D")
	
	# Find target tree with apple
	target = _find_nearest_tree_with_apple(agent)
	
	if is_instance_valid(target) and navigation_agent:
		# Cache the position before await in case tree gets freed
		var target_pos = target.global_position
		await agent.get_tree().physics_frame
		navigation_agent.target_position = target_pos
		print(agent.name, ": Navigating to tree with apple at ", target_pos)

func perform(agent: Node, _delta: float) -> bool:
	# Check if target is valid FIRST
	if not is_instance_valid(target):
		agent.velocity = Vector2.ZERO
		return false
	
	# Check if target still has apple
	if "has_apple" in target and not target.has_apple:
		print(agent.name, ": Target tree lost its apple during navigation")
		agent.velocity = Vector2.ZERO
		return false
	
	# Check if we've arrived
	var distance_to_tree = agent.global_position.distance_to(target.global_position)
	if distance_to_tree < ARRIVED_THRESHOLD:
		print(agent.name, ": Arrived near tree with apple")
		agent.velocity = Vector2.ZERO
		return true
	
	if not navigation_agent:
		# Fallback: direct movement without navigation
		var direction = agent.global_position.direction_to(target.global_position)
		agent.velocity = direction * agent.move_speed
		return false
	
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

func _find_nearest_tree_with_apple(agent: Node) -> Node:
	# Always get fresh reference to scanner
	var scanner: Area2D = null
	if agent.has_node("ScannerComponent"):
		scanner = agent.get_node("ScannerComponent")
	else:
		print(agent.name, ": FindAppleTreeAction - No ScannerComponent found on agent")
		return null
	
	var nearby_bodies = scanner.get_overlapping_bodies()
	var nearest_tree: Node = null
	var nearest_distance: float = INF
	var trees_checked := 0
	var trees_without_apples := 0
	var trees_unreachable := 0
	
	for body in nearby_bodies:
		if body.is_in_group("trees"):
			trees_checked += 1
			
			# Check if tree has apples
			if "has_apple" in body:
				if not body.has_apple:
					trees_without_apples += 1
					continue
			
			# Check if tree is reachable
			if not _is_tree_reachable(agent, body):
				trees_unreachable += 1
				continue
			
			var distance = agent.global_position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_tree = body
	
	if trees_checked > 0:
		print(agent.name, ": Scanned ", trees_checked, " trees, ", trees_without_apples, " had no apples, ", trees_unreachable, " were unreachable, found: ", nearest_tree != null)
	else:
		print(agent.name, ": FindAppleTreeAction - No trees found in scanner range, bodies detected: ", nearby_bodies.size())
	
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
	
	# Path must end very close to the target (within a few pixels)
	var max_acceptable_distance = 5.0
	if distance_to_target >= max_acceptable_distance:
		return false
	
	return true
