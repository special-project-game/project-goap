extends Camera2D

@export var speed: float = 500.0
@export var zoom_step: float = 1
@export var min_zoom: float = 0.1
@export var max_zoom: float = 4.0

@export var label: Label

func _process(delta):
	var direction = Vector2.ZERO

	if Input.is_action_pressed("camera_up"):
		direction.y -= 1
	if Input.is_action_pressed("camera_down") and not Input.is_key_pressed(KEY_CTRL):
		direction.y += 1
	if Input.is_action_pressed("camera_left"):
		direction.x -= 1
	if Input.is_action_pressed("camera_right"):
		direction.x += 1

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		global_position += direction * speed * delta

	# Handle zoom input
	if Input.is_action_pressed("camera_zoom_in"):
		zoom *= 1.0 - zoom_step * delta
	elif Input.is_action_pressed("camera_zoom_out"):
		zoom *= 1.0 + zoom_step * delta

	# Clamp zoom
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)

	label.text = "Zoom Level: %.2f" % zoom.x
