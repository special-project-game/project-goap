extends Node

@export var entity_node: PackedScene
@export var spawn_count: int = 1
@export var spawn_interval: int = 5
@export var tile_layers: Array[TileMapDual]
@onready var day_night_cycle = $"../DayNightCycle"

var spawned_count: int = 0
var time: float = 0.0
var can_spawn: bool = false

var _valid_spawn_positions: Array[Vector2i] = []
var _is_map_validity_cached: bool = false

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

func _ready():
	day_night_cycle.night_started.connect(_on_night_started)
	day_night_cycle.night_ended.connect(_on_night_ended)
	call_deferred("_cache_valid_spawn_positions")
	#_cache_valid_spawn_positions()
	print("cached")
	print(_valid_spawn_positions.size())
	

func _process(delta):
	time += delta
	
	if time >= spawn_interval and can_spawn:
		if not _is_map_validity_cached:
			_cache_valid_spawn_positions()
		
		if spawned_count <= spawn_count:
			_attempt_spawn()
		time = 0.0

func _on_night_started() -> void:
	can_spawn = true

func _on_night_ended() -> void:
	can_spawn = false
	spawned_count = 0
		


func spawn(pos: Vector2i, ent: PackedScene):
	var entity = ent.instantiate()
	
	if is_instance_valid(tile_layers[TypeDefs.Layer.WATER_GRASS]):
		entity.baseTileMap = tile_layers[TypeDefs.Layer.WATER_GRASS]
	entity.position = pos
	print("-----------------------spawning predator-----------------------")
	owner.add_child(entity)

func _attempt_spawn():
	if _valid_spawn_positions.is_empty():
		print("No valid spawn positions found on the map.")
		return
	
	var random_index = randi_range(0, _valid_spawn_positions.size() - 1)
	var cell_pos: Vector2i = _valid_spawn_positions[random_index]
	var world_pos = tile_layers[0].map_to_local(cell_pos)
	
	spawn(world_pos, entity_node)
	spawned_count += 1
	
	
func _cache_valid_spawn_positions():
	_valid_spawn_positions.clear()
	_is_map_validity_cached = true # Assume cached unless an error occurs

	if tile_layers.is_empty():
		printerr("Spawner: No TileMap layers assigned for caching spawn positions!")
		return

	# Use the first TileMap to get the overall used cells, assuming they all cover the same general area
	# Or iterate through all TileMaps and combine their used cells, then filter.
	var cells_in_use: Array[Vector2i] = []
	for layer_index in tile_layers.size():
		var tilemap: TileMapDual = tile_layers[layer_index]
		print(tilemap)
		if is_instance_valid(tilemap):
			print("tile map valid")
			# get_used_cells() returns a list of all cells that have a tile on them for the given layer
			for cell in tilemap.get_used_cells(): # Assuming layer 0 for tiles within the tilemap
				if not cells_in_use.has(cell): # Avoid duplicates if multiple layers overlap
					cells_in_use.append(cell)
		else:
			printerr("Spawner: TileMap layer at index %d is invalid when caching!" % layer_index)
			_is_map_validity_cached = false # Mark cache as invalid if a layer is missing

	if not _is_map_validity_cached:
		return # Stop if a layer was invalid

	for cell_pos in cells_in_use:
		if get_cell_type(cell_pos) != TypeDefs.Tile.WATER:
			_valid_spawn_positions.append(cell_pos)

	print("Cached %d valid spawn positions." % _valid_spawn_positions.size())

func get_cell_type(pos: Vector2i) -> TypeDefs.Tile:
	if tile_layers.size() <= 0:
		return TypeDefs.Tile.WATER
		
	if not is_instance_valid(tile_layers[TypeDefs.Layer.WATER_GRASS]):
		printerr("mainNode: water_grass_tilemap is not valid in get_cell_type!")
		return TypeDefs.Tile.WATER

	
	var atlas_coords = tile_layers[TypeDefs.Layer.DIRT].get_cell_atlas_coords(pos)
	if atlas_coords != Vector2i(-1, -1):
		return atlas_coordinates_reversed[[TypeDefs.Layer.DIRT, atlas_coords]]
	atlas_coords = tile_layers[TypeDefs.Layer.SAND].get_cell_atlas_coords(pos)
	if atlas_coords != Vector2i(-1, -1):
		return atlas_coordinates_reversed[[TypeDefs.Layer.SAND, atlas_coords]]
	atlas_coords = tile_layers[TypeDefs.Layer.WATER_GRASS].get_cell_atlas_coords(pos)
	if atlas_coords != Vector2i(-1, -1):
		return atlas_coordinates_reversed[[TypeDefs.Layer.WATER_GRASS, atlas_coords]]

	return TypeDefs.Tile.WATER
	
	
