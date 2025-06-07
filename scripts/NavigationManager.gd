# NavigationManager.gd
extends Node

var astar_graph := AStar2D.new()
var point_id_map: Dictionary = {} # Maps Vector2i (map_coords) to int (AStar point ID)

var _tilemap_node: TileMapDual = null
var _main_node_for_cell_type = null # Node that has get_cell_type()
var _is_graph_built := false

const TILE_LAYER_FOR_NAVIGATION = 0 # Adjust if your navigation layer is different

func _on_tile_changed(map_coords: Vector2i) -> void:
	print("Tile changed signal")
	_update_astar_point(map_coords)
	
func _update_astar_point(map_coords:Vector2i) -> void:
	if not is_instance_valid(_tilemap_node) or not is_instance_valid(_main_node_for_cell_type):
		printerr("NavigationManager: TileMap or MainNode not valid.")
		return

	var is_walkable = (_main_node_for_cell_type.get_cell_type(map_coords) != 0)

	if is_walkable:
		if not point_id_map.has(map_coords): # Point doesn't exist in A*
			_add_astar_point(map_coords)  # Add it
		else:
			_update_connections(map_coords) # update the neighbours of this cell, if they became non walkable
	else: # Not walkable
		if point_id_map.has(map_coords):  # Point exists, remove it
			_remove_astar_point(map_coords)

func _add_astar_point(map_coords: Vector2i) -> void:
	#print("NavigationManager: Adding point at ", map_coords)
	if not is_instance_valid(_tilemap_node):
		printerr("NavigationManager: TileMap is not valid!")
		return
	if not _main_node_for_cell_type.get_cell_type(map_coords) != 0:
		# We should not be calling this if is not walkable, extra check
		printerr("Tried to add a non walkable tile, this should not happen")
		return

	if point_id_map.has(map_coords):
		printerr("Tried to add point at ", map_coords, " when it already exists.")
		return

	var point_id = astar_graph.get_available_point_id()
	astar_graph.add_point(point_id, map_coords)
	point_id_map[map_coords] = point_id
	_update_connections(map_coords) # After adding, connect to neighbors

func _remove_astar_point(map_coords: Vector2i) -> void:
	#print("NavigationManager: Removing point at ", map_coords)
	if not point_id_map.has(map_coords):
		# Tried to remove point that does not exist, this should not happen
		printerr("Tried to remove point at ", map_coords, " when it does not exist.")
		return

	var point_id = point_id_map[map_coords]

	# Disconnect all connections to this point *before* removing the point
	for neighbor_map_coords_v2i in _get_neighbors(map_coords):
		if point_id_map.has(neighbor_map_coords_v2i):
			var neighbor_id = point_id_map[neighbor_map_coords_v2i]
			if astar_graph.are_points_connected(point_id, neighbor_id):
				astar_graph.disconnect_points(point_id, neighbor_id)
				astar_graph.disconnect_points(neighbor_id, point_id)

	astar_graph.remove_point(point_id)
	point_id_map.erase(map_coords)

func _update_connections(map_coords: Vector2i) -> void:
	#print("NavigationManager: Updating connections for point at ", map_coords)
	if not is_instance_valid(_tilemap_node):
		printerr("NavigationManager: TileMap is not valid!")
		return
	# Make sure current cell is walkable
	if not _main_node_for_cell_type.get_cell_type(map_coords) != 0:
		printerr("Cannot update neighbours of a non walkable cell")
		return
	if not point_id_map.has(map_coords):
		printerr("Cannot update neighbours of a cell which is not in the graph")
		return
	var current_id = point_id_map[map_coords]
	
	for neighbor_map_coords_v2i in _get_neighbors(map_coords):
		if _main_node_for_cell_type.get_cell_type(neighbor_map_coords_v2i) != 0: # Is walkable
			if point_id_map.has(neighbor_map_coords_v2i):
				var neighbor_id = point_id_map[neighbor_map_coords_v2i]
				if not astar_graph.are_points_connected(current_id, neighbor_id):
					astar_graph.connect_points(current_id, neighbor_id)
					astar_graph.connect_points(neighbor_id, current_id)

		else: # Is unwalkable, disconnect
			if point_id_map.has(neighbor_map_coords_v2i):
				var neighbor_id = point_id_map[neighbor_map_coords_v2i]
				if astar_graph.are_points_connected(current_id, neighbor_id):
					astar_graph.disconnect_points(current_id, neighbor_id)
					astar_graph.disconnect_points(neighbor_id, current_id)

func _get_neighbors(map_coords: Vector2i) -> Array[Vector2i]:
	# Helper function to get the valid neighbors of a cell
	return [
		map_coords + Vector2i.LEFT,
		map_coords + Vector2i.RIGHT,
		map_coords + Vector2i.UP,
		map_coords + Vector2i.DOWN
	]

# Call this from your main scene's _ready() to initialize the graph
func initialize_navigation(tilemap: TileMapDual, main_node):
	if not is_instance_valid(tilemap) or not is_instance_valid(main_node):
		printerr("NavigationManager: Invalid TileMap or MainNode provided for initialization.")
		return

	_tilemap_node = tilemap
	_main_node_for_cell_type = main_node
	
	_main_node_for_cell_type.tile_changed.connect(_on_tile_changed)
	
	build_graph()
	print("NavigationManager: Initial graph built.")

func build_graph():
	if not is_instance_valid(_tilemap_node) or not is_instance_valid(_main_node_for_cell_type):
		printerr("NavigationManager: TileMap or MainNode not set. Cannot build graph.")
		_is_graph_built = false
		return

	astar_graph.clear()
	point_id_map.clear()
	_is_graph_built = false # Mark as not ready until build completes

	#print("NavigationManager: Building A* graph...")
	
	for y in range(-100, 100):
		for x in range(-100, 100):
			var pos = Vector2i(x, y)
			if _main_node_for_cell_type.get_cell_type(pos) != 0: # Type 0 is unwalkable
				var point_id = astar_graph.get_available_point_id()
				astar_graph.add_point(point_id, pos) # AStar2D uses Vector2
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
				astar_graph.connect_points(current_id, neighbor_id)
	
	_is_graph_built = true
	print("NavigationManager: Graph built with ", astar_graph.get_point_count(), " points.")

func is_graph_ready() -> bool:
	return _is_graph_built

func get_nav_path(start_map_pos: Vector2i, target_map_pos: Vector2i) -> PackedVector2Array:
	if not _is_graph_built:
		printerr("NavigationManager: Graph not built yet. Cannot find path.")
		return PackedVector2Array()

	if not point_id_map.has(start_map_pos) or not point_id_map.has(target_map_pos):
		#print("NavigationManager: Start or target position not in A* graph. Start:", start_map_pos, " Target:", target_map_pos)
		return PackedVector2Array()

	var start_id = point_id_map[start_map_pos]
	var target_id = point_id_map[target_map_pos]

	return astar_graph.get_point_path(start_id, target_id)
