# Pig.gd
extends Entity # Inherit from Entity
class_name Pig

const PIG_SPEED: float = 10
@onready var health_component = $HealthComponent

# Pig-specific properties or components can go here if any
# For example, maybe pigs have a different default wander radius or speed
# @export var pig_specific_property: int = 10

func _on_entity_ready():
	super._on_entity_ready()
	self.move_speed = PIG_SPEED
	print("I'm Pig " + str(self.name) + " oinking and initialized.")
	# You can set entity-specific defaults here if not done in editor
	# move_speed = 3.0 
	# wander_radius = 3

# Override if Pigs have different rules for valid tiles
# For example, maybe pigs can't go on "Fence" tiles
func _is_valid_target_tile(map_pos: Vector2i) -> bool:
	if not super._is_valid_target_tile(map_pos):
		return false
	
	# Example: Pigs avoid tiles with custom data "is_fence"
	# var layer_id = 0 # Assuming custom data is on layer 0
	# var source_id = base_tilemap.get_cell_source_id(layer_id, map_pos)
	# if source_id != -1:
	# 	var atlas_coords = base_tilemap.get_cell_atlas_coords(layer_id, map_pos)
	# 	var tile_data = base_tilemap.tile_set.get_tile_data(source_id, atlas_coords)
	# 	if tile_data and tile_data.get_custom_data("is_fence"):
	# 		# print(name, " cannot cross fence at ", map_pos)
	# 		return false
			
	return true # Pigs can otherwise go anywhere valid by the base Entity class
