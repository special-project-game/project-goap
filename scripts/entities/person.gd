# Person.gd
extends Entity
class_name Person

# Person-specific components and properties
@onready var health_component = $HealthComponent
@onready var attack_component = $Attack
@onready var root = get_parent()

func _on_entity_ready():
	super._on_entity_ready()
	print("I'm Person " + str(self.name) + " initialized.")
	# print("Health: " + str(health_component.health))
	# print("Attack " + str(attack_component.attack_damage))

# Override to implement Person-specific tile validation
func _is_valid_target_tile(map_pos: Vector2i) -> bool:
	if not super._is_valid_target_tile(map_pos): # Check base class validation first
		return false

	if baseTileMap is TileMapDual: # Or whatever your TileMapDual class is called
		if root.get_cell_type(map_pos) == TypeDefs.Tile.WATER:
			# print(name, " cannot walk on water at ", map_pos)
			return false
	else:
		printerr("Wrong tilemap type")
	
	return true
