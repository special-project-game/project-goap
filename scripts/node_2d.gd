extends Node2D

const SAVE_FILE := "user://save.json"

enum TileLayer {WATER_GRASS, DIRT}
enum TileType {WATER, DIRT, GRASS, SAND}
enum ObjectType {GRASS}

const atlas_coordinates = {
	TileType.WATER: [TileLayer.WATER_GRASS, Vector2i(0,3)],
	TileType.GRASS: [TileLayer.WATER_GRASS, Vector2i(2,1)],
	TileType.DIRT: [TileLayer.DIRT, Vector2i(2,1)]
}

const atlas_coordinates_reversed = {
	[TileLayer.WATER_GRASS, Vector2i(0,3)]: TileType.WATER,
	[TileLayer.WATER_GRASS, Vector2i(2,1)]: TileType.GRASS,
	[TileLayer.DIRT, Vector2i(2,1)]: TileType.DIRT
}

@onready var camera = $Camera2D
@onready var tilemap_water_grass := $Water_Grass
@onready var tilemap_dirt := $Dirt
@onready var objectlayer := $ObjectLayer

func place_cell(pos: Vector2i, cell: TileType):
	# when placing cells on one tilemaplayer, we also need to remove it from higher layers, to make sure it will be visible
	match cell:
		TileType.DIRT:
			tilemap_dirt.set_cell(pos, 0, atlas_coordinates[cell][1])
			tilemap_water_grass.erase_cell(pos)
		TileType.GRASS, TileType.WATER:
			tilemap_water_grass.set_cell(pos, 0, atlas_coordinates[cell][1])
			tilemap_dirt.erase_cell(pos)
	
func get_cell_type(pos: Vector2i) -> TileType:
	var atlas_coords = tilemap_water_grass.get_cell_atlas_coords(pos)
	if atlas_coords != Vector2i(-1,-1):
		return atlas_coordinates_reversed[[TileLayer.WATER_GRASS, atlas_coords]]
	atlas_coords = tilemap_dirt.get_cell_atlas_coords(pos)
	if atlas_coords != Vector2i(-1,-1):
		return atlas_coordinates_reversed[[TileLayer.DIRT, atlas_coords]]
	return TileType.WATER
	
	
func _input(_event):
	# Background Tiles
	var tile_pos = tilemap_water_grass.local_to_map(get_local_mouse_position())
	if Input.is_action_pressed("place_grass"):
		place_cell(tile_pos, TileType.GRASS)
	elif Input.is_action_pressed("place_dirt"):
		place_cell(tile_pos, TileType.DIRT)
	elif Input.is_action_pressed("place_sand"):
		place_cell(tile_pos, TileType.SAND)
	elif Input.is_action_pressed("place_water"):
		place_cell(tile_pos, TileType.WATER)
		
	# Objects
	var obj_pos = objectlayer.local_to_map(get_local_mouse_position())
	if Input.is_action_pressed("place_grass_object"):	
		# don't allow placing on water
		if not get_cell_type(obj_pos) == TileType.WATER:
			objectlayer.set_cell(obj_pos, ObjectType.GRASS, Vector2i.ZERO)

	# Saving
	if Input.is_action_just_pressed("save_game"):
		save_tiles_to_file()
		return

func save_tiles_to_file():
	print("Saving")
	var save_data = {"tiles": {}, "camera": {}, "objects": {}}
	for pos in tilemap_water_grass.get_used_cells():
		var type = get_cell_type(pos)
		if type == TileType.WATER: # we don't need to save water tils as they're the fallback
			continue
		var pos_str = str([pos.x, pos.y])
		save_data["tiles"][pos_str] = type
	for pos in tilemap_dirt.get_used_cells():
		var type = get_cell_type(pos)
		var pos_str = str([pos.x, pos.y])
		save_data["tiles"][pos_str] = type
	for pos in objectlayer.get_used_cells():
		var tile_id = objectlayer.get_cell_source_id(pos)
		var pos_str = str([pos.x, pos.y])
		save_data["objects"][pos_str] = tile_id
		
	save_data["camera"]["pos"] = vec2_to_arr(camera.global_position)
	save_data["camera"]["zoom"] = vec2_to_arr(camera.zoom)
		
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func _ready():
	print("Loading")
	load_tiles_from_file()
	fill_empty_with_water(100, 100)

func fill_empty_with_water(area_width: int, area_height: int):
	for y in range(-area_height, area_height):
		for x in range(-area_width, area_width):
			var pos = Vector2i(x, y)
			# Only fill if no ground tile exists at this position
			if get_cell_type(pos) == TileType.WATER:
				place_cell(pos, TileType.WATER)
				
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
