#Predator.gd
extends Entity
class_name Predator

# Predator-specific components and properties
@onready var health_component = $HealthComponent
@onready var attack_component = $Attack
@onready var root = get_parent()


func _on_entity_ready():
	super._on_entity_ready()
	print("Predator " + self.name + " initialized.")
