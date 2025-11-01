# WanderAction.gd
extends GOAPAction
class_name WanderAction

## GOAP Action: Wander around randomly when idle

const WANDER_DURATION: float = 5.0
var wander_timer: float = 0.0
var target_position: Vector2 = Vector2.ZERO
var has_target: bool = false

func _setup_action() -> void:
	action_name = "Wander"
	cost = 8.0 # Lower cost than RestAction (10.0), higher than productive actions
	
	# Preconditions: None - can always wander
	# Effects: is_resting = true (to satisfy idle goal)
	add_effect("is_resting", true)

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	wander_timer = 0.0
	has_target = false
	_pick_random_destination(agent)
	print(agent.name, ": Starting to wander")

func perform(agent: Node, delta: float) -> bool:
	wander_timer += delta
	
	# Pick new destination if we don't have one or reached it
	if not has_target:
		_pick_random_destination(agent)
	
	# Move towards target
	if has_target:
		var distance = agent.global_position.distance_to(target_position)
		
		if distance > 5.0: # Still moving
			var direction = agent.global_position.direction_to(target_position)
			agent.velocity = direction * agent.move_speed
		else:
			# Reached destination, pick new one
			agent.velocity = Vector2.ZERO
			has_target = false
	
	# Wander for the duration, then complete
	if wander_timer >= WANDER_DURATION:
		return true
	
	return false

func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	agent.velocity = Vector2.ZERO

func _pick_random_destination(agent: Node) -> void:
	# Pick a random point within wander radius
	var wander_radius = 100.0 # pixels
	var angle = randf() * TAU
	var distance = randf() * wander_radius
	
	target_position = agent.global_position + Vector2(cos(angle), sin(angle)) * distance
	has_target = true
