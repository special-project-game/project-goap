extends CharacterBody2D
class_name Person

const SPEED : float = 5.0
const WAYPOINT_THRESHOLD_SQ: float = 25.0 # (5 pixels)^2
const WANDER_RADIUS: int = 5
const MAX_PATHFINDING_ATTEMPTS: int = 10
const PAUSE_AT_DESTINATION_DURATION: float = 3.0 # Seconds to pause

@export var move_speed : float = SPEED
@export var animation_tree : AnimationTree
@onready var root = get_parent()
@onready var health_component = $HealthComponent
@onready var attack = $Attack
@onready var baseTileMap: TileMapDual = get_parent().get_node("Water_Grass") # Still needed for local_to_map etc.

var direction : Vector2 = Vector2.ZERO
var wander_time : float = 0.0 # For fallback random movement
var thinking : bool = false # True while actively requesting/waiting for path
var last_facing_direction := Vector2.LEFT

var current_path : PackedVector2Array = []
var path_index : int = 0
var _tile_size_half: Vector2

# New state variables for pausing
var is_pausing_at_destination: bool = false
var pause_timer: float = 0.0

func _ready():
	animation_tree.active = true

	if not is_instance_valid(baseTileMap):
		printerr("Character: BaseTileMap is not properly assigned or configured! Disabling movement.")
		set_physics_process(false)
		return
		
	_tile_size_half = baseTileMap.tile_set.tile_size / 2.0

	# Ensure NavigationManager is ready (it should be if initialized in Main scene)
	if not NavigationManager.is_graph_ready():
		printerr("Character: NavigationManager graph is not ready. Waiting or fallback might be needed.")
		# Optionally, you could implement a short wait or retry here,
		# but it's better if Main scene guarantees initialization first.
	
	call_deferred("_request_new_path")

	# Debug prints
	print("I'm " + str(self.name) + " initialized.")
	# print("Health: " + str(health_component.health))
	# print("Attack " + str(attack.attack_damage))

func _request_new_path():
	thinking = true
	is_pausing_at_destination = false # Exiting pause state if we were in it
	current_path.clear()
	path_index = 0

	if not NavigationManager.is_graph_ready():
		printerr("Character ", name, ": Navigation graph not ready, falling back.")
		return

	var start_map_pos: Vector2i = baseTileMap.local_to_map(self.position)
	
	var attempts = 0
	while attempts < MAX_PATHFINDING_ATTEMPTS:
		# Choose a random target tile within WANDER_RADIUS that is different from start
		var x_rand = randi_range(start_map_pos.x - WANDER_RADIUS, start_map_pos.x + WANDER_RADIUS)
		var y_rand = randi_range(start_map_pos.y - WANDER_RADIUS, start_map_pos.y + WANDER_RADIUS)
		var target_map_pos = Vector2i(x_rand, y_rand)
		if root.get_cell_type(target_map_pos) == TypeDefs.Tile.WATER:
			# can't walk on water
			continue

		if target_map_pos != start_map_pos: # Ensure target is not the current tile
			var new_path = NavigationManager.get_nav_path(start_map_pos, target_map_pos)
			
			if not new_path.is_empty() and new_path.size() > 1: # Path needs at least start and one step
				current_path = new_path
				path_index = 0
				thinking = false
				#print("Character ", name, ": Found A* path from ", start_map_pos, " to ", target_map_pos, ": ", current_path.size(), " steps.")
				return
		attempts += 1

func _physics_process(delta):
	var current_move_speed = SPEED
	var target_velocity = Vector2.ZERO

	if not is_instance_valid(baseTileMap): # Safety check
		velocity = Vector2.ZERO
		return

	if is_pausing_at_destination:
		current_move_speed = 0.0
		pause_timer -= delta
		if pause_timer <= 0:
			is_pausing_at_destination = false
			call_deferred("_request_new_path") # Time to find a new path
	elif thinking:
		current_move_speed = 0.0 # Stop while requesting/waiting for path
	elif not current_path.is_empty():
		if path_index < current_path.size():
			var next_waypoint_map_coords_v2: Vector2 = current_path[path_index]
			var target_world_pos: Vector2 = baseTileMap.map_to_local(Vector2i(next_waypoint_map_coords_v2)) + _tile_size_half

			var current_direction_to_waypoint = (target_world_pos - self.position).normalized()
			target_velocity = current_direction_to_waypoint * current_move_speed
			
			if self.position.distance_squared_to(target_world_pos) < WAYPOINT_THRESHOLD_SQ:
				path_index += 1
				if path_index >= current_path.size():
					# Reached destination
					current_path.clear()
					is_pausing_at_destination = true
					pause_timer = PAUSE_AT_DESTINATION_DURATION
					#print("Character ", name, ": Reached destination. Pausing for ", PAUSE_AT_DESTINATION_DURATION, "s.")
		else: # Should not happen if logic is correct
			current_path.clear()
			is_pausing_at_destination = true # Safety: if path index out of bounds, pause and retry
			pause_timer = PAUSE_AT_DESTINATION_DURATION 
			# call_deferred("_request_new_path") # Or request immediately
	else: # No A* path, not thinking, not pausing (e.g., fallback wander or needs new path)
		if wander_time > 0:
			target_velocity = direction * current_move_speed
			wander_time -= delta
		else:
			# Fallback wander time expired, or initial state before first path
			call_deferred("_request_new_path")

	velocity = target_velocity
	
	var is_idle = velocity.length_squared() < 0.01 # Check if velocity is near zero
	
	if not is_idle:
		last_facing_direction = velocity.normalized()
		animation_tree.get("parameters/playback").travel("Walk")
		animation_tree.set("parameters/Walk/blend_position", last_facing_direction)
		move_and_slide()
	else:
		animation_tree.get("parameters/playback").travel("Idle")
		
	animation_tree.set("parameters/Idle/blend_position", last_facing_direction)
