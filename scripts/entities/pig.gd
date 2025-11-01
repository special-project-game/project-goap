# Pig.gd
extends Entity
class_name Pig

const PIG_SPEED: float = 10
@onready var health_component = $HealthComponent

func _on_entity_ready():
	super._on_entity_ready()
	self.move_speed = PIG_SPEED
	print("I'm Pig " + str(self.name) + " oinking and initialized.")

func _is_valid_target_tile(map_pos: Vector2i) -> bool:
	if not super._is_valid_target_tile(map_pos):
		return false
			
	return true
