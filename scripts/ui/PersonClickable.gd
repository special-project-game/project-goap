# PersonClickable.gd
extends Area2D

## Makes a person clickable - add as child of Person node

signal person_clicked(person: CharacterBody2D)

@export var click_radius: float = 30.0

var person: CharacterBody2D

func _ready():
	# Get parent person
	person = get_parent() as CharacterBody2D
	
	# Set up collision shape
	var shape = CircleShape2D.new()
	shape.radius = click_radius
	
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	
	# Connect to input
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			person_clicked.emit(person)
			# Find PersonUIManager and show UI
			var ui_manager = get_tree().get_first_node_in_group("person_ui_manager")
			if ui_manager and ui_manager.has_method("show_person_ui"):
				ui_manager.show_person_ui(person)
