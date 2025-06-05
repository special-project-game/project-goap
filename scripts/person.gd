# Person.gd
extends Entity # Inherit from Entity
class_name Person

# Person-specific components and properties
@onready var health_component = $HealthComponent
@onready var attack_component = $Attack # Renamed for clarity
@onready var root = get_parent()

# If you have TypeDefs.Tile.WATER defined globally (e.g., in an Autoload)
# If not, you'll need a way to access this definition.
# For example, if TypeDefs is an Autoload script:
# const TypeDefs = preload("res://scripts/global/type_defs.gd") 

func _on_entity_ready(): # Override the hook from Entity
	super._on_entity_ready() # Good practice to call super if it might do something
	print("I'm Person " + str(self.name) + " initialized.")
	# print("Health: " + str(health_component.health))
	# print("Attack " + str(attack_component.attack_damage))

# Override to implement Person-specific tile validation
func _is_valid_target_tile(map_pos: Vector2i) -> bool:
	if not super._is_valid_target_tile(map_pos): # Check base class validation first
		return false

	# Assuming TypeDefs is accessible, e.g., an Autoload
	# And base_tilemap is a TileMapDual or has a similar method
	if baseTileMap is TileMapDual: # Or whatever your TileMapDual class is called
		if root.get_cell_type(map_pos) == TypeDefs.Tile.WATER: # Adjust if TypeDefs is not global
			# print(name, " cannot walk on water at ", map_pos)
			return false
	else:
		printerr("Wrong tilemap type")
	
	return true
