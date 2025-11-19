extends Node2D
const TypeDefs = preload("res://scripts/TypeDef.gd")

const SAVE_FILE := "user://save.json"

var is_left_mouse_dragging: bool = false
var last_placed_tile_map_pos: Vector2i = Vector2i(-1, -1)
var current_mode: TypeDefs.Mode = TypeDefs.Mode.VIEW

# Selected from toolbar:
var current_tile: TypeDefs.Tile = TypeDefs.Tile.WATER
var current_object: TypeDefs.Objects = TypeDefs.Objects.TREE
var current_entity: TypeDefs.Entity = TypeDefs.Entity.PERSON

var entities = {
	TypeDefs.Entity.PERSON: preload("res://scenes/person.tscn"),
	TypeDefs.Entity.PIG: preload("res://scenes/pig.tscn"),
	TypeDefs.Entity.PREDATOR: preload("res://scenes/predator.tscn"),
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
@onready var toolbar := $CanvasLayer/Control/Toolbar  # IMPORTANT

# Navigation rebake state
var navigation_rebake_timer: Timer = null
var needs_navigation_rebake: bool = false
var enable_auto_rebake: bool = false
const NAVIGATION_REBAKE_DELAY: float = 0.5

signal tile_changed(map_coords: Vector2i)

func place_cell(pos: Vector2i, cell: TypeDefs.Tile):
	for layer in layers:
		layer.erase_cell(pos)
	layers[TypeDefs.Layer.WATER_GRASS].set_cell(pos, 0, atlas_coordinates[TypeDefs.Tile.GRASS][1])
	match cell:
		TypeDefs.Tile.DIRT:
			layers[TypeDefs.Layer.DIRT].set_cell(pos, 0, atlas_coordinates[cell][1])
		TypeDefs.Tile.WATER:
			layers[TypeDefs.Layer.WATER_GRASS].set_cell(pos, 0, atlas_coordinates[cell][1])
			objectlayer.erase_cell(pos)
		TypeDefs.Tile.SAND:
			layers[TypeDefs.Layer.SAND].set_cell(pos, 0, atlas_coordinates[cell][1])

	emit_signal("tile_changed", pos)

func get_cell_type(pos: Vector2i) -> TypeDefs.Tile:
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
	var active_tilemap = layers[TypeDefs.Layer.WATER_GRASS]
	var current_tile_map_pos = active_tilemap.local_to_map(current_mouse_pos)

	# LEFT CLICK PRESS / RELEASE
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_left_mouse_dragging = true

			match current_mode:
				TypeDefs.Mode.PLACE_TILE:
					place_cell(current_tile_map_pos, current_tile)
				TypeDefs.Mode.PLACE_OBJECT:
					place_obj(current_tile_map_pos, current_object)
				TypeDefs.Mode.PLACE_ENTITY:
					summon(current_mouse_pos, current_entity)

			last_placed_tile_map_pos = current_tile_map_pos
		else:
			is_left_mouse_dragging = false
			last_placed_tile_map_pos = Vector2i(-1, -1)

	# DRAGGING
	elif event is InputEventMouseMotion and is_left_mouse_dragging:
		if current_tile_map_pos != last_placed_tile_map_pos:
			match current_mode:
				TypeDefs.Mode.PLACE_TILE:
					place_cell(current_tile_map_pos, current_tile)
				TypeDefs.Mode.PLACE_OBJECT:
					place_obj(current_tile_map_pos, current_object)
			last_placed_tile_map_pos = current_tile_map_pos

	# CLEAR ENTITIES
	if Input.is_action_just_pressed("clear"):
		for node in get_tree().get_nodes_in_group("entities"):
			node.queue_free()

func summon(pos: Vector2, entityType: TypeDefs.Entity):
	var entity = entities[entityType].instantiate()
	entity.baseTileMap = layers[TypeDefs.Layer.WATER_GRASS]
	entity.position = pos
	add_child(entity)

func place_obj(pos: Vector2i, obj: TypeDefs.Objects):
	var obj_pos = objectlayer.local_to_map(get_local_mouse_position())
	if get_cell_type(obj_pos) == TypeDefs.Tile.WATER:
		return

	var existing_cell = objectlayer.get_cell_source_id(obj_pos)
	if existing_cell != -1:
		objectlayer.erase_cell(obj_pos)

	var source_id = 1
	objectlayer.set_cell(obj_pos, source_id, Vector2i.ZERO, obj)

func save_tiles_to_file():
	print("Saving")
	var save_data = {"tiles": {}, "camera": {}, "objects": {}, "entities": []}
	for pos in layers[TypeDefs.Layer.WATER_GRASS].get_used_cells():
		var type = get_cell_type(pos)
		if type == TypeDefs.Tile.WATER:
			continue
		var pos_str = str([pos.x, pos.y])
		save_data["tiles"][pos_str] = type

	for pos in layers[TypeDefs.Layer.DIRT].get_used_cells():
		var type2 = get_cell_type(pos)
		var pos_str2 = str([pos.x, pos.y])
		save_data["tiles"][pos_str2] = type2

	for pos in objectlayer.get_used_cells():
		var tile_id = objectlayer.get_cell_source_id(pos)
		var pos_str3 = str([pos.x, pos.y])
		save_data["objects"][pos_str3] = tile_id

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

	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func _ready():
	cursor.play()

	if toolbar:
		toolbar.mode_selected.connect(_on_toolbar_mode_selected)
		toolbar.item_selected.connect(_on_toolbar_item_selected)

		toolbar._on_tiles_pressed()

	else:
		print("Toolbar NOT found!")

	load_tiles_from_file()
	fill_empty_with_water(100, 100)

	navigation_rebake_timer = Timer.new()
	navigation_rebake_timer.one_shot = true
	navigation_rebake_timer.wait_time = NAVIGATION_REBAKE_DELAY
	navigation_rebake_timer.timeout.connect(_on_navigation_rebake_timer_timeout)
	add_child(navigation_rebake_timer)

	tile_changed.connect(_on_tile_changed)

	if navigation_region:
		await NavigationBaker.bake_navigation_from_tilemap(layers[TypeDefs.Layer.WATER_GRASS], self, navigation_region)
		NavigationServer2D.set_debug_enabled(true)
		enable_auto_rebake = true
	else:
		printerr("NavigationRegion2D not found!")

# Called when toolbar mode button pressed
func _on_toolbar_mode_selected(mode: TypeDefs.Mode) -> void:
	current_mode = mode
	print("Mode from toolbar:", mode)

# Called when toolbar slot clicked
func _on_toolbar_item_selected(id: int) -> void:
	match current_mode:
		TypeDefs.Mode.PLACE_TILE:
			current_tile = id
			print("Selected tile:", id)
		TypeDefs.Mode.PLACE_OBJECT:
			current_object = id
			print("Selected object:", id)
		TypeDefs.Mode.PLACE_ENTITY:
			current_entity = id
			print("Selected entity:", id)

func _on_tile_changed(_map_coords: Vector2i) -> void:
	if not enable_auto_rebake:
		return
	needs_navigation_rebake = true
	if navigation_rebake_timer:
		navigation_rebake_timer.start()

func _on_navigation_rebake_timer_timeout() -> void:
	if needs_navigation_rebake and navigation_region:
		print("Rebaking navigation due to tile changes...")
		needs_navigation_rebake = false
		await NavigationBaker.bake_navigation_from_tilemap(layers[TypeDefs.Layer.WATER_GRASS], self, navigation_region)
		print("Navigation rebake complete!")

func fill_empty_with_water(area_width: int, area_height: int):
	for y in range(-area_height, area_height):
		for x in range(-area_width, area_width):
			var pos = Vector2i(x, y)
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
		var pos2 = str_to_var(pos_str)
		var pos_vector2 = Vector2i(pos2[0], pos2[1])
		var tile_id2 = data["objects"][pos_str]
		objectlayer.set_cell(pos_vector2, tile_id2, Vector2i.ZERO)

	for entity in data["entities"]:
		var type: TypeDefs.Entity = entity["type"]
		summon(Vector2(entity["position"][0], entity["position"][1]), type)

	camera.global_position = arr_to_vec2(data["camera"]["pos"])
	camera.zoom = arr_to_vec2(data["camera"]["zoom"])

func vec2_to_arr(vec: Vector2):
	return [vec.x, vec.y]

func arr_to_vec2(arr: Array):
	assert(arr.size() == 2, "Array size needs to be 2")
	return Vector2(arr[0], arr[1])
