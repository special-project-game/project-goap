# Entity.gd
extends CharacterBody2D
class_name Entity

# --- Constants (can be overridden by subclasses if needed, or made exports) ---
const DEFAULT_SPEED: float = 5.0
const WAYPOINT_THRESHOLD_SQ: float = 25.0 # (5 pixels)^2
const DEFAULT_WANDER_RADIUS: int = 5
const MAX_PATHFINDING_ATTEMPTS: int = 10
const PAUSE_AT_DESTINATION_DURATION: float = 3.0 # Seconds to pause

# --- Exports (to be configured per entity instance) ---
@export var move_speed: float = DEFAULT_SPEED
@export var wander_radius: int = DEFAULT_WANDER_RADIUS
@export var animation_tree: AnimationTree
@export var baseTileMap: TileMapDual

# --- Internal State ---
var direction: Vector2 = Vector2.ZERO
var wander_time: float = 0.0 # For fallback random movement (less used with current pathing)
var thinking: bool = false # True while actively requesting/waiting for path
var last_facing_direction := Vector2.LEFT

var current_path: PackedVector2Array = []
var path_index: int = 0
var _tile_size_half: Vector2

var is_pausing_at_destination: bool = false
var pause_timer: float = 0.0

# --- Lifecycle Methods ---
func _ready():
	if not is_instance_valid(animation_tree):
		printerr(name, ": AnimationTree is not assigned! Disabling animations.")
	else:
		animation_tree.active = true
#
	#if not is_instance_valid(base_tilemap):
		#printerr(name, ": BaseTileMap is not properly assigned! Disabling movement.")
		#set_physics_process(false)
		#return
		
	_tile_size_half = Vector2i(16,16)/2

	if not NavigationManager.is_graph_ready():
		printerr(name, ": NavigationManager graph is not ready. Pathfinding might fail initially.")
	
	call_deferred("_request_new_path")
	_on_entity_ready() # Hook for subclasses

# Hook for subclasses to add their own _ready logic
func _on_entity_ready():
	pass

func _physics_process(delta: float):
	var current_target_velocity = Vector2.ZERO # Renamed to avoid conflict with inherited 'velocity'
#
	#if not is_instance_valid(base_tilemap): # Safety check
		#velocity = Vector2.ZERO
		#move_and_slide()
		#return

	if is_pausing_at_destination:
		# Velocity is zero while pausing
		pause_timer -= delta
		if pause_timer <= 0:
			is_pausing_at_destination = false
			call_deferred("_request_new_path") # Time to find a new path
	elif thinking:
		pass # Velocity is zero while thinking
	elif not current_path.is_empty():
		if path_index < current_path.size():
			var next_waypoint_map_coords_v2: Vector2 = current_path[path_index]
			var target_world_pos: Vector2 = baseTileMap.map_to_local(Vector2i(next_waypoint_map_coords_v2)) + _tile_size_half

			var current_direction_to_waypoint = (target_world_pos - self.position).normalized()
			current_target_velocity = current_direction_to_waypoint * move_speed
			
			if self.position.distance_squared_to(target_world_pos) < WAYPOINT_THRESHOLD_SQ:
				path_index += 1
				if path_index >= current_path.size():
					_on_reached_destination() # Call hook
		else: # Should not happen if logic is correct
			_on_reached_destination() # Treat as reached destination
	else: # No A* path, not thinking, not pausing
		if wander_time > 0: # Fallback random wander (currently less used)
			current_target_velocity = direction * move_speed
			wander_time -= delta
		else:
			call_deferred("_request_new_path")

	velocity = current_target_velocity # Set the final velocity for CharacterBody2D
	
	# Animation control
	if is_instance_valid(animation_tree):
		var is_idle = velocity.length_squared() < 0.01 # Check if velocity is near zero
		if not is_idle:
			last_facing_direction = velocity.normalized()
			animation_tree.get("parameters/playback").travel("Walk")
			animation_tree.set("parameters/Walk/blend_position", last_facing_direction)
		else:
			animation_tree.get("parameters/playback").travel("Idle")
		animation_tree.set("parameters/Idle/blend_position", last_facing_direction)
	
	move_and_slide()
	_on_entity_physics_process(delta) # Hook for subclasses

# Hook for subclasses to add their own _physics_process logic
func _on_entity_physics_process(delta: float):
	pass

# --- Pathfinding ---
func _request_new_path():
	thinking = true
	is_pausing_at_destination = false
	current_path.clear()
	path_index = 0

	if not NavigationManager.is_graph_ready():
		printerr(name, ": Navigation graph not ready for path request.")
		thinking = false # Allow retry or fallback
		return

	var start_map_pos: Vector2i = baseTileMap.local_to_map(self.position)
	
	var attempts = 0
	while attempts < MAX_PATHFINDING_ATTEMPTS:
		var x_rand = randi_range(start_map_pos.x - wander_radius, start_map_pos.x + wander_radius)
		var y_rand = randi_range(start_map_pos.y - wander_radius, start_map_pos.y + wander_radius)
		var target_map_pos = Vector2i(x_rand, y_rand)

		# Hook for subclasses to validate target tile
		if not _is_valid_target_tile(target_map_pos):
			attempts += 1 # Count as an attempt, but don't pathfind to invalid tile
			continue

		if target_map_pos != start_map_pos: # Ensure target is not the current tile
			var new_path = NavigationManager.get_nav_path(start_map_pos, target_map_pos)
			
			if not new_path.is_empty() and new_path.size() > 1: # Path needs at least start and one step
				current_path = new_path
				path_index = 0
				thinking = false
				#print(name, ": Found A* path from ", start_map_pos, " to ", target_map_pos, ": ", current_path.size(), " steps.")
				return
		attempts += 1
	
	# Failed to find a path after attempts
	printerr(name, ": Failed to find a valid path after ", MAX_PATHFINDING_ATTEMPTS, " attempts. Will retry.")
	# destroy this entity as its stuck.
	self.queue_free()

	thinking = false # Allow retry or fallback (e.g. could set wander_time here)
	# Consider a small delay before retrying to avoid spamming if stuck
	get_tree().create_timer(1.0).timeout.connect(func(): call_deferred("_request_new_path") )


# --- Hooks for Subclasses (Protected-like methods) ---

# Called when the entity reaches its path destination
func _on_reached_destination():
	#print(name, ": Reached destination.")
	current_path.clear()
	is_pausing_at_destination = true
	pause_timer = PAUSE_AT_DESTINATION_DURATION

# Allow subclasses to define what makes a target tile valid for them
# For example, Person might not walk on water, Pig might not care or have other rules.
func _is_valid_target_tile(map_pos: Vector2i) -> bool:
	# Default implementation: any tile is valid as long as it's on the map
	# You'll likely want to check if it's within map bounds if your wander_radius is large
	# and NavigationManager doesn't already handle out-of-bounds requests gracefully.
	# For now, we assume NavigationManager handles invalid coords.
	return true 
