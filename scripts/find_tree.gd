extends State


# test code for FindTree Action, will be moved to FindTree State
@onready var navigation_agent_2d = $"../../NavigationAgent2D"
@onready var scanner_component = $"../../ScannerComponent"
@onready var person = $"../.."

var nearby_trees : Array = []
var target : Node2D = null
var target_position : Vector2

func scan_trees():
	var tree_distances : Array
	var self_position = person.global_position
	nearby_trees = scanner_component.get_overlapping_bodies()
	for tree in nearby_trees:
		var tree_position = tree.global_position
		tree_distances.append([tree, tree_position.distance_to(self_position)])
	tree_distances.sort_custom(func(a, b): return a[1] < b[1])
	
	if tree_distances.size() > 0:
		var closest_tree = tree_distances[0]
		target = closest_tree[0]
		target_position = target.global_position
		#print("closest tree: " + str(closest_tree))

func setup_target():
	await get_tree().physics_frame
	scan_trees()
	
	if is_instance_valid(target):
		navigation_agent_2d.target_position = target.global_position
		print(target)
		print(navigation_agent_2d.target_position)

func Enter():
	call_deferred("setup_target")

func Update(delta):
	pass

func Physics_Update(delta):
	if is_instance_valid(target):
		navigation_agent_2d.target_position = target.global_position
	else:
		Transitioned.emit(self, "wander")
		return

	if navigation_agent_2d.is_navigation_finished():
		Transitioned.emit(self, "choptree")
		return

	var current_agent_position = person.global_position
	var next_path_position = navigation_agent_2d.get_next_path_position()
	
	person.velocity = current_agent_position.direction_to(next_path_position) * person.move_speed
