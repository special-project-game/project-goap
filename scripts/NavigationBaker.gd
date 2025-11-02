# NavigationBaker.gd
extends Node
class_name NavigationBaker

## Runtime navigation baking based on tile types
## Call bake_navigation() from your main scene's _ready()

## Bake navigation polygons based on walkable tiles
static func bake_navigation_from_tilemap(tilemap: TileMapDual, main_node, navigation_region: NavigationRegion2D) -> void:
	if not is_instance_valid(tilemap) or not is_instance_valid(main_node) or not is_instance_valid(navigation_region):
		printerr("NavigationBaker: Invalid parameters")
		return
	
	print("NavigationBaker: Starting navigation bake...")
	
	var nav_polygon = NavigationPolygon.new()
	
	# Set agent radius to create margin around obstacles
	# This effectively shrinks the navigation area away from water
	nav_polygon.agent_radius = 4.0
	
	# Get tile size
	var tile_size = tilemap.tile_set.tile_size if tilemap.tile_set else Vector2i(16, 16)
	var half_size = Vector2(tile_size) / 2.0
	
	# Collect all vertices and create polygons manually
	var all_vertices = PackedVector2Array()
	var vertex_index = 0
	
	for y in range(-100, 100):
		for x in range(-100, 100):
			var map_pos = Vector2i(x, y)
			var cell_type = main_node.get_cell_type(map_pos)
			
			# Add non-water tiles as walkable
			if cell_type != TypeDefs.Tile.WATER:
				# Convert map coordinates to world coordinates
				var world_pos = tilemap.map_to_local(map_pos)
				
				# Add 4 vertices for this tile (counter-clockwise)
				# agent_radius will create margin automatically
				all_vertices.append(world_pos + Vector2(-half_size.x, -half_size.y)) # Top-left
				all_vertices.append(world_pos + Vector2(half_size.x, -half_size.y)) # Top-right
				all_vertices.append(world_pos + Vector2(half_size.x, half_size.y)) # Bottom-right
				all_vertices.append(world_pos + Vector2(-half_size.x, half_size.y)) # Bottom-left
				
				# Create polygon indices for this quad
				var polygon_indices = PackedInt32Array([
					vertex_index + 0,
					vertex_index + 1,
					vertex_index + 2,
					vertex_index + 3
				])
				
				# Add the polygon
				nav_polygon.add_polygon(polygon_indices)
				vertex_index += 4
	
	# Set all vertices at once
	nav_polygon.set_vertices(all_vertices)
	
	print("NavigationBaker: Created ", nav_polygon.get_polygon_count(), " navigation polygons with ", all_vertices.size(), " vertices")
	
	# Set the navigation polygon
	navigation_region.navigation_polygon = nav_polygon
	
	print("NavigationBaker: Navigation bake complete!")
	
	# Force navigation update
	await navigation_region.get_tree().physics_frame
	print("NavigationBaker: Navigation ready for use")
