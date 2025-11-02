# NavigationHelper.gd
extends Node

## Helper for setting up navigation with tile-based obstacles
## Use this to configure NavigationAgent2D to avoid water tiles

## Check if a position is walkable (not water)
static func is_position_walkable(world_pos: Vector2, tilemap: TileMapDual, main_node) -> bool:
	if not is_instance_valid(tilemap) or not is_instance_valid(main_node):
		return true # Assume walkable if can't check
	
	var map_pos = tilemap.local_to_map(world_pos)
	var cell_type = main_node.get_cell_type(map_pos)
	
	# WATER = 0 is not walkable
	return cell_type != TypeDefs.Tile.WATER

## Get a valid path that avoids water
static func get_walkable_path(from: Vector2, to: Vector2, tilemap: TileMapDual, main_node) -> PackedVector2Array:
	# Simple implementation - could be improved with A*
	# For now, rely on NavigationAgent2D with proper avoidance
	return PackedVector2Array([to])

## Setup NavigationAgent2D for a character
static func setup_navigation_agent(nav_agent: NavigationAgent2D) -> void:
	if not nav_agent:
		return
	
	# Configure navigation parameters
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	nav_agent.avoidance_enabled = true
	nav_agent.radius = 8.0
