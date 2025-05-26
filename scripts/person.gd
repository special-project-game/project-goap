extends CharacterBody2D
class_name Person

const SPEED : float = 20.0
const WAYPOINT_THRESHOLD_SQ: float = 25.0
const WANDER_RADIUS: int = 5
const MAX_PATHFINDING_ATTEMPTS: int = 10

@export var move_speed : float = SPEED
@export var animation_tree : AnimationTree
@onready var health_component = $HealthComponent
@onready var attack = $Attack
@onready var mainNode := get_parent()
@onready var baseTileMap: TileMapDual = get_parent().get_node("Water_Grass")

var direction : Vector2 = Vector2.ZERO
var wander_time : float = 0.0
var thinking : bool = false
var last_facing_direction := Vector2.LEFT

var astar := AStar2D.new()
var point_id_map: Dictionary = {}
var current_path : PackedVector2Array = []
var path_index : int = 0
var _tile_size_half: Vector2

func _ready():
	animation_tree.active = true

	_tile_size_half = baseTileMap.tile_set.tile_size / 2.0

	call_deferred("randomize_wander")

	print("I'm " + str(self.name) + " initialized.")
	print("Health: " + str(health_component.health))
	print("Attack " + str(attack.attack_damage))

func _build_astar_graph():
	if not is_instance_valid(baseTileMap):
		printerr("Character: Cannot build A* graph, baseTileMap is not valid.")
		return

	astar.clear() 
	point_id_map.clear() 

	var used_cells = baseTileMap.get_used_cells()

	for y in range(-100, 100):
		for x in range(-100, 100):
			var pos = Vector2i(x,y)
			if mainNode.get_cell_type(pos) != 0: 
				var point_id = astar.get_available_point_id()
				astar.add_point(point_id, pos)
				point_id_map[pos] = point_id

	for cell_map_coords_v2i in point_id_map.keys():
		var current_id = point_id_map[cell_map_coords_v2i]
		var neighbors = [
			cell_map_coords_v2i + Vector2i.LEFT,
			cell_map_coords_v2i + Vector2i.RIGHT,
			cell_map_coords_v2i + Vector2i.UP,
			cell_map_coords_v2i + Vector2i.DOWN
		]
		for neighbor_map_coords_v2i in neighbors:
			if point_id_map.has(neighbor_map_coords_v2i):
				var neighbor_id = point_id_map[neighbor_map_coords_v2i]
				astar.connect_points(current_id, neighbor_id)


func randomize_wander():
	thinking = true
	current_path.clear()
	path_index = 0

	_build_astar_graph()

	if astar.get_point_count() == 0:
		printerr("Character: A* graph is empty after build. No navigation possible.")
		_set_fallback_wander("A* graph empty.")
		return

	var start_map_pos: Vector2i = baseTileMap.local_to_map(self.position)

	if not point_id_map.has(start_map_pos):
		printerr("Character at ", self.position, " (map: ", start_map_pos, ") is on a non-navigable tile or outside built A* graph.")
		_set_fallback_wander("Start position not in A* graph after rebuild.")
		return

	var start_id = point_id_map[start_map_pos]
	var target_map_pos: Vector2i
	var target_id: int = -1
	
	var attempts = 0
	while attempts < MAX_PATHFINDING_ATTEMPTS:
		var x_rand = randi_range(start_map_pos.x - WANDER_RADIUS, start_map_pos.x + WANDER_RADIUS)
		var y_rand = randi_range(start_map_pos.y - WANDER_RADIUS, start_map_pos.y + WANDER_RADIUS)
		target_map_pos = Vector2i(x_rand, y_rand)

		if point_id_map.has(target_map_pos) and target_map_pos != start_map_pos:
			target_id = point_id_map[target_map_pos]
			var new_path: PackedVector2Array = astar.get_point_path(start_id, target_id)
			
			if not new_path.is_empty() and new_path.size() > 1:
				current_path = new_path
				path_index = 0
				thinking = false
				print("Found A* path from ", start_map_pos, " to ", target_map_pos, ": ", current_path.size(), " steps.")
				return
		attempts += 1
	
	_set_fallback_wander("Could not find A* path after " + str(MAX_PATHFINDING_ATTEMPTS) + " attempts from " + str(start_map_pos))

func _set_fallback_wander(reason: String):
	print("Fallback wander: ", reason)
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT
	wander_time = randf_range(1.0, 3.0)
	thinking = false
	current_path.clear()

func _physics_process(delta):
	var current_move_speed = SPEED
	var target_velocity = Vector2.ZERO

	if not is_instance_valid(baseTileMap): 
		velocity = Vector2.ZERO
		return

	if thinking:
		current_move_speed = 0.0
	elif not current_path.is_empty():
		if path_index < current_path.size():
			var next_waypoint_map_coords_v2: Vector2 = current_path[path_index]
			var target_world_pos: Vector2 = baseTileMap.map_to_local(Vector2i(next_waypoint_map_coords_v2)) + _tile_size_half

			var current_direction_to_waypoint = (target_world_pos - self.position).normalized()
			target_velocity = current_direction_to_waypoint * current_move_speed
			
			if self.position.distance_squared_to(target_world_pos) < WAYPOINT_THRESHOLD_SQ:
				path_index += 1
				if path_index >= current_path.size():
					current_path.clear()
					call_deferred("randomize_wander")
		else:
			current_path.clear()
			call_deferred("randomize_wander")
	else: 
		if wander_time > 0:
			target_velocity = direction * current_move_speed
			wander_time -= delta
		else:
			call_deferred("randomize_wander") 

	velocity = target_velocity
	
	var is_idle = velocity.length_squared() < 0.01
	
	if not is_idle:
		last_facing_direction = velocity.normalized()
		animation_tree.get("parameters/playback").travel("Walk")
		animation_tree.set("parameters/Walk/blend_position", last_facing_direction)
		move_and_slide()
	else:
		animation_tree.get("parameters/playback").travel("Idle")
		
	animation_tree.set("parameters/Idle/blend_position", last_facing_direction)
