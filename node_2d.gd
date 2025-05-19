extends Node2D

const SAVE_FILE := "user://save.json"
const TILE_WATER = 0
const TILE_DIRT = 1
const TILE_GRASS = 2
const TILE_SAND = 3

const OBJECT_GRASS = 0

@onready var camera = $Camera2D
@onready var tilemap := $BaseLayer
@onready var objectlayer := $ObjectLayer

func _input(_event):
	# Background Tiles
	var tile_pos = tilemap.local_to_map(get_local_mouse_position())
	if Input.is_action_pressed("place_grass"):
		tilemap.set_cell(tile_pos, TILE_GRASS, Vector2i.ZERO)
	elif Input.is_action_pressed("place_dirt"):
		tilemap.set_cell(tile_pos, TILE_DIRT, Vector2i.ZERO)
	elif Input.is_action_pressed("place_sand"):
		tilemap.set_cell(tile_pos, TILE_SAND, Vector2i.ZERO)
	elif Input.is_action_pressed("place_water"):
		tilemap.set_cell(tile_pos, TILE_WATER, Vector2i.ZERO)
		
	# Objects
	var obj_pos = objectlayer.local_to_map(get_local_mouse_position())
	if Input.is_action_pressed("place_grass_object"):	
		# don't allow placing on water
		if not tilemap.get_cell_source_id(tile_pos) == 0:
			objectlayer.set_cell(obj_pos, OBJECT_GRASS, Vector2i.ZERO)

	# Saving
	if Input.is_action_just_pressed("save_game"):
		save_tiles_to_file()
		return

func save_tiles_to_file():
	print("Saving")
	var save_data = {"tiles": {}, "camera": {}, "objects": {}}
	for pos in tilemap.get_used_cells():
		var tile_id = tilemap.get_cell_source_id(pos)
		if tile_id == TILE_WATER: # we don't need to save water tils as they're the fallback
			continue
		var pos_str = str([pos.x, pos.y])
		save_data["tiles"][pos_str] = tile_id
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
			if tilemap.get_cell_source_id(pos) == -1:
				tilemap.set_cell(pos, TILE_WATER, Vector2i.ZERO)

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
		var tile_id = data["tiles"][pos_str]
		tilemap.set_cell(pos_vector, tile_id, Vector2i.ZERO)
		
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
