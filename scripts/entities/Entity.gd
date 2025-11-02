# Entity.gd
extends CharacterBody2D
class_name Entity

# --- Constants ---
const DEFAULT_SPEED: float = 5.0

# --- Exports ---
@export var move_speed: float = DEFAULT_SPEED
@export var animation_tree: AnimationTree
@export var baseTileMap: TileMapDual

# --- GOAP Control ---
# GOAP actions will set velocity directly, Entity handles animation
var goap_controlled: bool = false

# --- Internal State ---
var last_facing_direction := Vector2.LEFT

# --- Lifecycle Methods ---
func _ready():
	if not is_instance_valid(animation_tree):
		printerr(name, ": AnimationTree is not assigned! Disabling animations.")
	else:
		animation_tree.active = true
	
	_on_entity_ready() # Hook for subclasses

# Hook for subclasses to add their own _ready logic
func _on_entity_ready():
	pass

func _physics_process(delta: float):
	# Handle animations and movement
	_handle_animation()
	move_and_slide()
	_on_entity_physics_process(delta)

func _handle_animation() -> void:
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

# Hook for subclasses to add their own _physics_process logic
func _on_entity_physics_process(_delta: float):
	pass

# Allow subclasses to define what makes a target tile valid for them
# For example, Person might not walk on water
func _is_valid_target_tile(_map_pos: Vector2i) -> bool:
	# Default implementation: any tile is valid
	return true
