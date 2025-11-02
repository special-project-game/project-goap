# PersonUIManager.gd
extends CanvasLayer

## Manages clicking on persons and showing their info UI
## Add this to your main scene and add persons to the "person" group

@export var person_info_ui_scene: PackedScene = preload("res://scenes/person_info_ui.tscn")

var person_info_ui: Control
var camera: Camera2D

func _ready():
	# Add to group so PersonClickable can find us
	add_to_group("person_ui_manager")
	
	# Create the UI instance
	person_info_ui = person_info_ui_scene.instantiate()
	add_child(person_info_ui)
	
	# Find camera for proper click detection
	call_deferred("_find_camera")

func _find_camera():
	var cameras = get_tree().get_nodes_in_group("camera")
	if cameras.size() > 0:
		camera = cameras[0]
	else:
		# Try to find any camera
		camera = get_viewport().get_camera_2d()

func show_person_ui(person: CharacterBody2D):
	"""Called by PersonClickable when a person is clicked"""
	if person_info_ui:
		person_info_ui.show_for_person(person)

func _input(event: InputEvent):
	# Fallback click detection if PersonClickable is not used
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)

func _handle_click(screen_pos: Vector2):
	# Convert screen position to world position
	var world_pos = _screen_to_world(screen_pos)
	
	# Find clicked person
	var clicked_person = _find_person_at_position(world_pos)
	
	if clicked_person:
		person_info_ui.show_for_person(clicked_person)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	if camera:
		# Get the canvas transform
		var canvas_transform = get_viewport().get_canvas_transform()
		return canvas_transform.affine_inverse() * screen_pos
	else:
		return screen_pos

func _find_person_at_position(world_pos: Vector2) -> CharacterBody2D:
	# Get all persons in the scene
	var persons = get_tree().get_nodes_in_group("person")
	
	# Check each person
	for person in persons:
		if not person is CharacterBody2D:
			continue
		
		# Check if click is within a certain radius of the person
		var distance = person.global_position.distance_to(world_pos)
		if distance < 30.0: # 30 pixel click radius
			return person
	
	return null
