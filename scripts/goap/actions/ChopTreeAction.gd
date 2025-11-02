# ChopTreeAction.gd
extends GOAPAction
class_name ChopTreeAction

## GOAP Action: Chop down a tree to get wood

@onready var scanner_component: Area2D
@onready var hit_box_component: HitBoxComponent

const CHOP_RANGE: float = 20.0
var chop_timer: float = 0.0
var chops_needed: int = 5
var current_chops: int = 0

func _setup_action() -> void:
	action_name = "ChopTree"
	cost = 2.0
	
	# Preconditions: must be near a tree
	add_precondition("near_tree", true)
	
	# Effects: gain wood
	add_effect("has_wood", true)
	add_effect("near_tree", false)

func is_valid(_agent: Node, _world_state: Dictionary) -> bool:
	# For planning purposes, this action is valid as long as it could theoretically be executed
	# The precondition "near_tree" ensures we're actually near one when executing
	# We don't check if we're currently near a tree here - that's what preconditions are for!
	# Optional: Could check if ANY trees exist in the world at all
	# But for now, assume trees exist (FindTreeAction will fail if they don't)
	return true

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	
	# Get references
	if agent.has_node("ScannerComponent"):
		scanner_component = agent.get_node("ScannerComponent")
	if agent.has_node("Attack/HitBoxComponent"):
		hit_box_component = agent.get_node("Attack/HitBoxComponent")
	
	# Find and set target tree
	target = _find_nearest_tree(agent)
	current_chops = 0
	chop_timer = 0.0
	
	if target:
		print(agent.name, ": Found tree to chop at ", target.global_position)

func perform(agent: Node, delta: float) -> bool:
	if not is_instance_valid(target):
		# Tree was destroyed or disappeared
		return true
	
	# Move towards tree if not in range
	var distance_to_tree = agent.global_position.distance_to(target.global_position)
	
	if distance_to_tree > CHOP_RANGE:
		# Move towards tree
		var direction = agent.global_position.direction_to(target.global_position)
		agent.velocity = direction * agent.move_speed
		return false
	else:
		# Stop and chop
		agent.velocity = Vector2.ZERO
		
		chop_timer += delta
		if chop_timer >= 0.5: # Chop every 0.5 seconds
			chop_timer = 0.0
			current_chops += 1
			
			if hit_box_component:
				hit_box_component.attack()
			
			print(agent.name, ": Chopping tree... (", current_chops, "/", chops_needed, ")")
			
			if current_chops >= chops_needed:
				# Give wood to the agent
				if agent.has_node("GOAPAgent"):
					var goap_agent = agent.get_node("GOAPAgent")
					if goap_agent.has_method("add_wood"):
						goap_agent.add_wood(1)
				
				# Get the tree's tile position before destroying it
				if is_instance_valid(target):
					# Find the objectlayer using group
					var objectlayers = agent.get_tree().get_nodes_in_group("objectlayer")
					if objectlayers.size() > 0:
						var objectlayer = objectlayers[0]
						var tree_map_pos = objectlayer.local_to_map(target.global_position)
						# Erase the cell from the TileMapLayer
						objectlayer.erase_cell(tree_map_pos)
						print(agent.name, ": Erased tree cell at ", tree_map_pos)
					else:
						printerr(agent.name, ": ObjectLayer not found in 'objectlayer' group!")
					
					# Destroy the tree instance
					target.queue_free()
				
				print(agent.name, ": Tree chopped! Got wood.")
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
