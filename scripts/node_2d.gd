extends Node2D

const SAVE_FILE := "user://save.json"

var is_left_mouse_dragging: bool = false
var last_placed_tile_map_pos: Vector2i = Vector2i(-1, -1)
var current_mode = TypeDefs.Mode.VIEW

var entities = {
		TypeDefs.Entity.PERSON: preload("res://scenes/person.tscn"),
		TypeDefs.Entity.PIG: preload("res://scenes/pig.tscn"),
	}

const atlas_coordinates = {
	TypeDefs.Tile.WATER: [TypeDefs.Layer.WATER_GRASS, Vector2i(0, 3)],
	TypeDefs.Tile.GRASS: [TypeDefs.Layer.WATER_GRASS, Vector2i(2, 1)],
	TypeDefs.Tile.DIRT: [TypeDefs.Layer.DIRT, Vector2i(2, 1)],
	TypeDefs.Tile.SAND: [TypeDefs.Layer.SAND, Vector2i(2, 1)],
}

const atlas_coordinates_reversed = {
	[TypeDefs.Layer.WATER_GRASS, Vector2i(0, 3)]: TypeDefs.Tile.WATER,
	[TypeDefs.Layer.WATER_GRASS, Vector2i(2, 1)]: TypeDefs.Tile.GRASS,
	[TypeDefs.Layer.DIRT, Vector2i(2, 1)]: TypeDefs.Tile.DIRT,
	[TypeDefs.Layer.SAND, Vector2i(2, 1)]: TypeDefs.Tile.SAND,
}

@onready var cursor := $Cursor
@onready var camera := $Camera2D
@onready var layers := [$Water_Grass, $Dirt, $Sand]
@onready var objectlayer := $ObjectLayer
@onready var navigation_region := $NavigationRegion2D

signal tile_changed(map_coords: Vector2i) # Signal emitted when a tile changes

func place_cell(pos: Vector2i, cell: TypeDefs.Tile):
	# when placing cells on one tilemaplayer, we also need to remove it from higher layers, to make sure it will be visible
	for layer in layers:
		layer.erase_cell(pos)
	layers[TypeDefs.Layer.WATER_GRASS].set_cell(pos, 0, atlas_coordinates[TypeDefs.Tile.GRASS][1]) # also set grass to make it look correct
	match cell:
		TypeDefs.Tile.DIRT:
			layers[TypeDefs.Layer.DIRT].set_cell(pos, 0, atlas_coordinates[cell][1])
		TypeDefs.Tile.WATER:
			layers[TypeDefs.Layer.WATER_GRASS].set_cell(pos, 0, atlas_coordinates[cell][1])
			# for water, also remove object layer
			objectlayer.erase_cell(pos)
		TypeDefs.Tile.SAND:
			layers[TypeDefs.Layer.SAND].set_cell(pos, 0, atlas_coordinates[cell][1])
			
	emit_signal("tile_changed", pos)
	
func get_cell_type(pos: Vector2i) -> TypeDefs.Tile:
	if not is_instance_valid(layers[TypeDefs.Layer.WATER_GRASS]):
		printerr("mainNode: water_grass_tilemap is not valid in get_cell_type!")
		return TypeDefs.Tile.WATER

	
	var atlas_coords = layers[TypeDefs.Layer.DIRT].get_cell_atlas_coords(pos)
	if atlas_coords != Vector2i(-1, -1):
		return atlas_coordinates_reversed[[TypeDefs.Layer.DIRT, atlas_coords]]
	atlas_coords = layers[TypeDefs.Layer.SAND].get_cell_atlas_coords(pos)
	if atlas_coords != Vector2i(-1, -1):
		return atlas_coordinates_reversed[[TypeDefs.Layer.SAND, atlas_coords]]
	atlas_coords = layers[TypeDefs.Layer.WATER_GRASS].get_cell_atlas_coords(pos)
	if atlas_coords != Vector2i(-1, -1):
		return atlas_coordinates_reversed[[TypeDefs.Layer.WATER_GRASS, atlas_coords]]

	return TypeDefs.Tile.WATER
	
	
func place_mouse():
	var mouse_world_pos: Vector2 = get_global_mouse_position()
	mouse_world_pos -= Vector2(8, 8)
	cursor.position = mouse_world_pos.snapped(Vector2i(16, 16))
	cursor.position += Vector2(8, 8)
		
func _input(_event):
	place_mouse()

func _unhandled_input(event):
	# Saving
	if Input.is_action_just_pressed("save_game"):
		save_tiles_to_file()
		get_viewport().set_input_as_handled()
		return

	var current_mouse_pos = get_local_mouse_position()
	# Assuming 'layers' is a dictionary of TileMap nodes and WATER_GRASS is a valid key
	# Ensure this TileMap node exists and is correctly referenced.
	var active_tilemap = layers[TypeDefs.Layer.WATER_GRASS] # Get the relevant TileMap
	var current_tile_map_pos = active_tilemap.local_to_map(current_mouse_pos)

	# Handle Mouse Button Press/Release
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			is_left_mouse_dragging = true
			match current_mode:
				TypeDefs.Mode.PLACE_TILE:
					var tile_to_place = $CanvasLayer/OptionButton.get_selected_id()
					place_cell(current_tile_map_pos, tile_to_place)
					last_placed_tile_map_pos = current_tile_map_pos # Record placement
				TypeDefs.Mode.PLACE_OBJECT:
					var object_to_place = $CanvasLayer/OptionButton.get_selected_id()
					place_obj(current_tile_map_pos, object_to_place)
					last_placed_tile_map_pos = current_tile_map_pos # Record placement
				TypeDefs.Mode.PLACE_ENTITY:
					var entity_to_place = $CanvasLayer/OptionButton.get_selected_id()
					summon(current_mouse_pos, entity_to_place)
					last_placed_tile_map_pos = current_tile_map_pos # Record placement
		else: # Mouse button released
			is_left_mouse_dragging = false
			last_placed_tile_map_pos = Vector2i(-1, -1) # Reset last placed position

	# Handle Mouse Motion (Dragging)
	elif event is InputEventMouseMotion and is_left_mouse_dragging:
		if current_mode == TypeDefs.Mode.PLACE_TILE:
			# Check if the mouse has moved to a new tile cell
			if current_tile_map_pos != last_placed_tile_map_pos:
				var tile_to_place = $CanvasLayer/OptionButton.get_selected_id()
				place_cell(current_tile_map_pos, tile_to_place)
				last_placed_tile_map_pos = current_tile_map_pos # Update last placed position
		elif current_mode == TypeDefs.Mode.PLACE_OBJECT:
			if current_tile_map_pos != last_placed_tile_map_pos:
				var object_to_place = $CanvasLayer/OptionButton.get_selected_id()
				place_obj(current_tile_map_pos, object_to_place)
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if current_mode == TypeDefs.Mode.PLACE_TILE:
			var tile_pos = layers[TypeDefs.Layer.WATER_GRASS].local_to_map(get_local_mouse_position())
			var tile_to_place = $CanvasLayer/OptionButton.get_selected_id()
			place_cell(tile_pos, tile_to_place)
		elif current_mode == TypeDefs.Mode.PLACE_OBJECT:
			var object_pos = objectlayer.local_to_map(get_local_mouse_position())
			var object_to_place = $CanvasLayer/OptionButton.get_selected_id()
			print("object:", object_to_place)
			place_obj(object_pos, object_to_place)
	
	if Input.is_action_just_pressed("clear"):
		var entities = get_tree().get_nodes_in_group("entities")
		for i in entities:
			i.queue_free()

func summon(pos: Vector2, entityType: TypeDefs.Entity):
	var entity = entities[entityType].instantiate()
	entity.baseTileMap = layers[TypeDefs.Layer.WATER_GRASS]
	entity.position = pos
	self.add_child(entity)

func place_obj(pos: Vector2i, obj: TypeDefs.Objects):
	var obj_pos = objectlayer.local_to_map(get_local_mouse_position())
	var source_id = 1 # for the TileSet, I used scenes collection instead, 1 is the ID for the collection
	# obj should be the ID of the 'scene' inside the collection
	if not get_cell_type(obj_pos) == TypeDefs.Tile.WATER:
			objectlayer.set_cell(obj_pos, source_id, Vector2i.ZERO, obj)

func save_tiles_to_file():
	print("Saving")
	var save_data = {"tiles": {}, "camera": {}, "objects": {}, "entities": []}
	for pos in layers[TypeDefs.Layer.WATER_GRASS].get_used_cells():
		var type = get_cell_type(pos)
		if type == TypeDefs.Tile.WATER: # we don't need to save water tils as they're the fallback
			continue
		var pos_str = str([pos.x, pos.y])
		save_data["tiles"][pos_str] = type
	for pos in layers[TypeDefs.Layer.DIRT].get_used_cells():
		var type = get_cell_type(pos)
		var pos_str = str([pos.x, pos.y])
		save_data["tiles"][pos_str] = type
	for pos in objectlayer.get_used_cells():
		var tile_id = objectlayer.get_cell_source_id(pos)
		var pos_str = str([pos.x, pos.y])
		save_data["objects"][pos_str] = tile_id
	# save persons
	for child in get_children():
		if child is Person:
			save_data["entities"].append({
				"type": TypeDefs.Entity.PERSON,
				"position": [child.position.x, child.position.y],
				"health": child.get_node("HealthComponent").health
			})
		elif child is Pig:
			save_data["entities"].append({
				"type": TypeDefs.Entity.PIG,
				"position": [child.position.x, child.position.y],
				"health": child.get_node("HealthComponent").health
			})
			
					
	save_data["camera"]["pos"] = vec2_to_arr(camera.global_position)
	save_data["camera"]["zoom"] = vec2_to_arr(camera.zoom)
		
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func _ready():
	cursor.play()
	load_tiles_from_file()
	fill_empty_with_water(100, 100)
	
	# Bake navigation based on walkable tiles (excludes water)
	if navigation_region:
		await NavigationBaker.bake_navigation_from_tilemap(layers[TypeDefs.Layer.WATER_GRASS], self, navigation_region)
		# Enable debug visualization (optional - comment out if you don't want to see it)
		NavigationServer2D.set_debug_enabled(true)
	else:
		printerr("NavigationRegion2D not found!")

func fill_empty_with_water(area_width: int, area_height: int):
	for y in range(-area_height, area_height):
		for x in range(-area_width, area_width):
			var pos = Vector2i(x, y)
			# Only fill if no ground tile exists at this position
			if get_cell_type(pos) == TypeDefs.Tile.WATER:
				place_cell(pos, TypeDefs.Tile.WATER)
				
func load_tiles_from_file():
	if not FileAccess.file_exists(SAVE_FILE):
		print("File not found")
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	for pos_str in data["tiles"].keys():
		var pos = str_to_var(pos_str)
		var pos_vector = Vector2i(pos[0], pos[1])
		var tile_id = int(data["tiles"][pos_str])
		
		place_cell(pos_vector, tile_id)
		
		
	for pos_str in data["objects"].keys():
		var pos = str_to_var(pos_str)
		var pos_vector = Vector2i(pos[0], pos[1])
		var tile_id = data["objects"][pos_str]
		objectlayer.set_cell(pos_vector, tile_id, Vector2i.ZERO)
		
	# load entities
	for entity in data["entities"]:
		var type = entity["type"] as TypeDefs.Entity
		summon(Vector2(entity["position"][0], entity["position"][1]), type)

	camera.global_position = arr_to_vec2(data["camera"]["pos"])
	camera.zoom = arr_to_vec2(data["camera"]["zoom"])
	
func vec2_to_arr(vec: Vector2):
	return [vec.x, vec.y]
	
func arr_to_vec2(arr: Array):
	assert(arr.size() == 2, "Array size needs to be 2")
	return Vector2(arr[0], arr[1])
	
static func reverse_dictionary(dict: Dictionary) -> Dictionary:
	var reversed_dict = {}
	for key in dict:
		var value = dict[key]
		# Basic check for duplicate values (optional for this specific problem)
		if reversed_dict.has(value):
			push_warning("Duplicate value found when reversing dictionary: %s" % value)
			# Decide how to handle: overwrite (default), make an array, or error
		reversed_dict[value] = key
	return reversed_dict


func _on_mode_option_button_item_selected(index: int) -> void:
	current_mode = index
	if index == TypeDefs.Mode.VIEW:
		$CanvasLayer/OptionButton.set_visible(false)
	else:
		make_place_cell_selection(index)
		$CanvasLayer/OptionButton.set_visible(true)
		

func make_place_cell_selection(mode: TypeDefs.Mode):
	print("mode is ", mode)
	$CanvasLayer/OptionButton.clear()
	match mode:
		TypeDefs.Mode.PLACE_TILE:
			for tiletype in TypeDefs.Tile.values():
				$CanvasLayer/OptionButton.add_item(TypeDefs.TileName[tiletype], tiletype)
			$CanvasLayer/OptionButton.select(TypeDefs.Tile.WATER)
		TypeDefs.Mode.PLACE_OBJECT:
			for objtype in TypeDefs.Objects.values():
				$CanvasLayer/OptionButton.add_item(TypeDefs.ObjectName[objtype], objtype)
			$CanvasLayer/OptionButton.select(TypeDefs.Objects.TREE)
		TypeDefs.Mode.PLACE_ENTITY:
			for entitytype in TypeDefs.Entity.values():
				$CanvasLayer/OptionButton.add_item(TypeDefs.EntityName[entitytype], entitytype)
			$CanvasLayer/OptionButton.select(TypeDefs.Entity.PERSON)
