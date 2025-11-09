# WanderAction.gd
extends GOAPAction
class_name WanderAction

## GOAP Action: Wander around randomly when idle using navigation

@onready var navigation_agent: NavigationAgent2D

const WANDER_DURATION: float = 10.0
const WANDER_RADIUS: float = 300.0
const ARRIVED_THRESHOLD: float = 20.0

var wander_timer: float = 0.0
var target_position: Vector2 = Vector2.ZERO
var has_target: bool = false

func _setup_action() -> void:
	action_name = "Wander"
	cost = 8.0 # Lower cost than RestAction (10.0), higher than productive actions
	
	# Preconditions: None - can always wander
	# Effects: is_resting = true (to satisfy idle goal)
	add_effect("is_resting", true)

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	
	# Get navigation agent reference
	if agent.has_node("NavigationAgent2D"):
		navigation_agent = agent.get_node("NavigationAgent2D")
	
	wander_timer = 0.0
	has_target = false
	_pick_random_reachable_destination(agent)
	print(agent.name, ": Starting to wander")

func perform(agent: Node, delta: float) -> bool:
	wander_timer += delta
	
	# Pick new destination if we don't have one or reached it
	if not has_target:
		_pick_random_reachable_destination(agent)
	
	# Move towards target using navigation
	if has_target and navigation_agent:
		var distance = agent.global_position.distance_to(target_position)
		
		if distance > ARRIVED_THRESHOLD:
			# Use navigation to move
			if not navigation_agent.is_navigation_finished():
				var next_position = navigation_agent.get_next_path_position()
				var direction = agent.global_position.direction_to(next_position)
				agent.velocity = direction * agent.move_speed
			else:
				# Navigation finished, pick new destination
				agent.velocity = Vector2.ZERO
				has_target = false
		else:
			# Reached destination, pick new one
			agent.velocity = Vector2.ZERO
			has_target = false
	elif has_target:
		# Fallback: direct movement without navigation
		var distance = agent.global_position.distance_to(target_position)
		if distance > ARRIVED_THRESHOLD:
			var direction = agent.global_position.direction_to(target_position)
			agent.velocity = direction * agent.move_speed
		else:
			agent.velocity = Vector2.ZERO
			has_target = false
	
	# Wander for the duration, then complete
	if wander_timer >= WANDER_DURATION:
		return true
	
	return false

func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	agent.velocity = Vector2.ZERO
	
	# Clear navigation target to remove debug visualization
	if navigation_agent:
		navigation_agent.target_position = agent.global_position

func _pick_random_reachable_destination(agent: Node) -> void:
	"""Pick a random reachable point using navigation system"""
	if not navigation_agent:
		# Fallback to old simple random point
		_pick_random_simple_destination(agent)
		return
	
	var map_rid = navigation_agent.get_navigation_map()
	if not map_rid.is_valid():
		# Navigation not ready, use simple random
		_pick_random_simple_destination(agent)
		return
	
	# Try multiple random points and pick the first reachable one
	var max_attempts = 10
	for attempt in range(max_attempts):
		var angle = randf() * TAU
		var distance = randf() * WANDER_RADIUS
		var test_position = agent.global_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Check if this position is reachable
		var path = NavigationServer2D.map_get_path(
			map_rid,
			agent.global_position,
			test_position,
			true
		)
		
		if path.size() >= 2:
			# Valid path found
			var last_point = path[path.size() - 1]
			target_position = last_point
			has_target = true
			
			# Set navigation target
			await agent.get_tree().physics_frame
			navigation_agent.target_position = target_position
			
			print(agent.name, ": Wandering to ", target_position)
			return
	
	# No reachable point found, just stay still
	print(agent.name, ": No reachable wander point found, staying still")
	has_target = false

func _pick_random_simple_destination(agent: Node) -> void:
	"""Fallback: Pick a random point without navigation validation"""
	var angle = randf() * TAU
	var distance = randf() * WANDER_RADIUS
	target_position = agent.global_position + Vector2(cos(angle), sin(angle)) * distance
	has_target = true
