extends Node2D

const SAVE_FILE := "user://save.json"
const TILE_GRASS = 0
const TILE_DIRT = 1

@onready var camera = $Camera2D
@onready var tilemap := $TileMapLayer

func _input(event):
	if Input.is_action_pressed("place_grass"):
		var tile_pos = tilemap.local_to_map(get_local_mouse_position())
		print("placing grass")
		tilemap.set_cell(tile_pos, TILE_GRASS, Vector2i(0,0))
	elif Input.is_action_pressed("place_dirt"):
		var tile_pos = tilemap.local_to_map(get_local_mouse_position())
		tilemap.set_cell(tile_pos, TILE_DIRT, Vector2i(0,0))

	if Input.is_action_just_pressed("save_game"):
		save_tiles_to_file()
		return

func save_tiles_to_file():
	print("Saving")
	var save_data = {"tiles": {}}
	for pos in tilemap.get_used_cells():
		var tile_id = tilemap.get_cell_source_id(pos)
		var pos_str = str([pos.x, pos.y])
		save_data["tiles"][pos_str] = tile_id
		
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
		

func _ready():
	print("Loading")
	load_tiles_from_file()
#
func load_tiles_from_file():
	if not FileAccess.file_exists(SAVE_FILE):
		print("File not found")
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	print(data)
#
	
	for pos_str in data["tiles"].keys():
		var pos = str_to_var(pos_str)
		var pos_vector = Vector2i(pos[0], pos[1])
		var tile_id = data["tiles"][pos_str]
		tilemap.set_cell(pos_vector, tile_id, Vector2i(0,0))


#func _process(_delta):
	#if Input.is_action_just_pressed("place_grass"):
		#place_tile("grass")
	#elif Input.is_action_just_pressed("place_dirt"):
		#place_tile("dirt")
		#
	## Move the water background with the camera
	#var water = get_node("WaterBackground")
	#water.global_position = camera.global_position
#
#
#func place_tile(type: String):
	#var mouse_pos = get_global_mouse_position()
#
	## Snap to 32x32 grid
	#var snapped_pos = Vector2(
		#floor(mouse_pos.x / TILE_SIZE) * TILE_SIZE,
		#floor(mouse_pos.y / TILE_SIZE) * TILE_SIZE
	#)
#
	#var color = get_tile_color(type)
	#var sprite = Sprite2D.new()
	#sprite.texture = make_colored_tile(color)
	#sprite.centered = false
	#sprite.position = snapped_pos
	#add_child(sprite)
#
#
#func _ready():
	#draw_water_background()
	#print("loading filea")
	#var file = FileAccess.open(TILE_FILE, FileAccess.READ)
	#var json = JSON.parse_string(file.get_as_text())
	#
	#var tiles = json["tiles"]
	#
	#for y in range(tiles.size()):
		#for x in range(tiles[y].size()):
			#var type = tiles[y][x]
			#var color = get_tile_color(type)
			#
			#var sprite = Sprite2D.new()
			#sprite.texture = make_colored_tile(color)
			#sprite.centered = false
			#sprite.position = Vector2(x, y) * TILE_SIZE
			#add_child(sprite)
#
#func get_tile_color(tile_type: String) -> Color:
	#match tile_type:
		#"grass":
			#return Color(0, 1, 0) # green
		#"dirt":
			#return Color(0.4, 0.2, 0) # brownad
		#_:
			#return Color(1, 0, 1) # magenta for unknown
#
#func make_colored_tile(color: Color) -> ImageTexture:
	#var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	#image.fill(color)
	#
	#var texture = ImageTexture.create_from_image(image)
	#return texture
#
#
#func draw_water_background():
	#var screen_size = get_viewport_rect().size
	#var water_texture = make_colored_tile(Color(0.0, 0.3, 0.8)) # bluish water
#
	#var water = Sprite2D.new()
	#water.texture = water_texture
	#water.scale = screen_size / TILE_SIZE
	#water.z_index = -1 # Render behind tiles
	#water.name = "WaterBackground"
	#add_child(water)
