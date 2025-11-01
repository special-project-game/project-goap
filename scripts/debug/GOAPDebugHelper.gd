# GOAPDebugHelper.gd
extends Node

## Add this to your main scene to debug GOAP issues
## Press F1 to toggle debug info

@export var show_scanner_ranges: bool = true
@export var show_tree_detection: bool = true
@export var print_debug_info: bool = true

var debug_enabled: bool = true

func _ready():
	# Run initial diagnostics
	call_deferred("run_diagnostics")

func _input(event):
	if event.is_action_pressed("ui_home"): # F1 key
		debug_enabled = !debug_enabled
		print("GOAP Debug: ", "ENABLED" if debug_enabled else "DISABLED")

func run_diagnostics():
	print("\n========== GOAP DIAGNOSTICS ==========")
	
	# Check for persons
	var persons = get_tree().get_nodes_in_group("person")
	print("Found ", persons.size(), " persons in 'person' group")
	
	for person in persons:
		print("\n--- Person: ", person.name, " ---")
		
		# Check GOAP Agent
		if person.has_node("GOAPAgent"):
			var goap = person.get_node("GOAPAgent")
			print("  ✓ Has GOAPAgent (", goap.get_script().resource_path.get_file(), ")")
			print("    Actions: ", goap.available_actions.size())
			print("    Goals: ", goap.available_goals.size())
		else:
			print("  ✗ Missing GOAPAgent!")
		
		# Check Scanner
		if person.has_node("ScannerComponent"):
			var scanner = person.get_node("ScannerComponent")
			print("  ✓ Has ScannerComponent")
			if scanner.get_child_count() > 0:
				var shape = scanner.get_child(0)
				if shape is CollisionShape2D and shape.shape is CircleShape2D:
					print("    Radius: ", shape.shape.radius, " pixels")
				else:
					print("    ⚠ CollisionShape2D might not be set up correctly")
			else:
				print("    ✗ No CollisionShape2D child!")
		else:
			print("  ✗ Missing ScannerComponent!")
		
		# Check other components
		if person.has_node("HealthComponent"):
			print("  ✓ Has HealthComponent")
		if person.has_node("NavigationAgent2D"):
			print("  ✓ Has NavigationAgent2D")
		if person.has_node("Attack/HitBoxComponent"):
			print("  ✓ Has Attack/HitBoxComponent")
	
	# Check for trees
	var trees = get_tree().get_nodes_in_group("trees")
	print("\n--- Trees ---")
	print("Found ", trees.size(), " objects in 'trees' group")
	if trees.size() > 0:
		print("First tree: ", trees[0].name, " at ", trees[0].global_position)
	else:
		print("⚠ NO TREES FOUND! Add trees to 'trees' group")
	
	# Check for old "tree" group
	var old_trees = get_tree().get_nodes_in_group("tree")
	if old_trees.size() > 0:
		print("⚠ Found ", old_trees.size(), " objects in old 'tree' group (should be 'trees')")
	
	# Check for food
	var food = get_tree().get_nodes_in_group("food")
	var berries = get_tree().get_nodes_in_group("berry_bush")
	print("\n--- Food Sources ---")
	print("Found ", food.size(), " in 'food' group")
	print("Found ", berries.size(), " in 'berry_bush' group")
	
	if food.size() == 0 and berries.size() == 0:
		print("⚠ No food sources found (hunger goal will fail)")
	
	print("\n=======================================\n")

func _process(delta):
	if debug_enabled:
		queue_redraw()

func _draw():
	if not debug_enabled:
		return
	
	# Draw scanner ranges
	if show_scanner_ranges:
		var persons = get_tree().get_nodes_in_group("person")
		for person in persons:
			if person.has_node("ScannerComponent"):
				var scanner = person.get_node("ScannerComponent")
				if scanner.get_child_count() > 0:
					var shape = scanner.get_child(0)
					if shape is CollisionShape2D and shape.shape is CircleShape2D:
						var radius = shape.shape.radius
						var pos = person.global_position - global_position
						draw_circle(pos, radius, Color(0, 1, 1, 0.1))
						draw_arc(pos, radius, 0, TAU, 32, Color.CYAN, 2.0)
	
	# Draw tree positions
	if show_tree_detection:
		var trees = get_tree().get_nodes_in_group("trees")
		for tree in trees:
			var pos = tree.global_position - global_position
			draw_circle(pos, 10, Color(0, 1, 0, 0.3))
			draw_arc(pos, 10, 0, TAU, 16, Color.GREEN, 2.0)

func _on_person_plan_failed(person: Node):
	if print_debug_info:
		print("\n!!! PLAN FAILED for ", person.name, " !!!")
		
		if person.has_node("ScannerComponent"):
			var scanner = person.get_node("ScannerComponent")
			var bodies = scanner.get_overlapping_bodies()
			print("Scanner sees ", bodies.size(), " bodies:")
			for body in bodies:
				print("  - ", body.name, " (groups: ", body.get_groups(), ")")
		
		if person.has_node("GOAPAgent"):
			var goap = person.get_node("GOAPAgent")
			print("Current goal: ", goap.current_goal.goal_name if goap.current_goal else "None")
			print("World state:")
			for key in goap.world_state:
				print("  ", key, " = ", goap.world_state[key])
