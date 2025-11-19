# AttackPredatorAction.gd
extends GOAPAction
class_name AttackPredatorAction

## GOAP Action: Attack a predator with sword (higher damage than normal)
## Similar to KillAction but for Person agents attacking Predators

@onready var scanner_component: Area2D
@onready var hit_box_component: HitBoxComponent
@onready var attack_component: Attack
@onready var target_health_component: HealthComponent
@onready var navigation_agent: NavigationAgent2D
@onready var goap_target: GOAPAgent

const ATTACK_RANGE: float = 20.0
const SWORD_DAMAGE_MULTIPLIER: float = 2.0 # Sword does 2x normal damage

var original_attack_damage: float = 0.0

func _setup_action() -> void:
	action_name = "AttackPredator"
	cost = 2.0
	
	# Preconditions: Must be near predator and have a sword
	add_precondition("near_predator", true)
	add_precondition("has_sword", true)
	
	# Effects: Predator is defeated, we're no longer near it
	add_effect("has_killed_predator", true)
	add_effect("near_predator", false)
	add_effect("is_safe", true)

func is_valid(agent: Node, world_state: Dictionary) -> bool:
	# Action is only valid if we have a sword
	return world_state.get("has_sword", false)

func on_enter(agent: Node) -> void:
	super.on_enter(agent)
	
	target = _find_nearest_predator(agent)
	
	# Get component references
	if agent.has_node("ScannerComponent"):
		scanner_component = agent.get_node("ScannerComponent")
	if agent.has_node("HitBoxComponent"):
		hit_box_component = agent.get_node("HitBoxComponent")
	if agent.has_node("Attack"):
		attack_component = agent.get_node("Attack")
		# Boost attack damage with sword
		original_attack_damage = attack_component.attack_damage
		attack_component.attack_damage *= SWORD_DAMAGE_MULTIPLIER
		print(agent.name, ": Sword equipped! Attack damage boosted to ", attack_component.attack_damage)
	if agent.has_node("NavigationAgent2D"):
		navigation_agent = agent.get_node("NavigationAgent2D")
	
	if is_instance_valid(target):
		if target.has_node("HealthComponent"):
			target_health_component = target.get_node("HealthComponent")
		
		if target.has_node("GOAPAgent"):
			goap_target = target.get_node("GOAPAgent")
			goap_target.is_target = true
			goap_target.chaser = agent
		
		print(agent.name, ": Engaging predator ", target.name, " in combat!")

func perform(agent: Node, delta: float) -> bool:
	# Check if target is still valid
	if not is_instance_valid(target):
		print(agent.name, ": Target predator is no longer valid")
		return true
	
	# Check if target is dead
	if target_health_component and target_health_component.health <= 0:
		print(agent.name, ": Predator defeated!")
		# Award experience for killing predator
		if agent.has_node("GOAPAgent"):
			var person_agent = agent.get_node("GOAPAgent")
			if person_agent is PersonGOAPAgent:
				person_agent.experience += 50 # Big reward for killing predator
				print(agent.name, ": Gained 50 exp! Total: ", person_agent.experience)
		return true
	
	var distance_to_target = agent.global_position.distance_to(target.global_position)
	var is_target_in_attack_range: bool = false
	
	# Check if target is in attack range
	if hit_box_component:
		var overlapping_areas = hit_box_component.get_overlapping_areas()
		for area in overlapping_areas:
			if area.owner == target:
				is_target_in_attack_range = true
				break
	else:
		if distance_to_target <= ATTACK_RANGE:
			is_target_in_attack_range = true
	
	# If not in attack range, move closer
	if not is_target_in_attack_range:
		if navigation_agent:
			navigation_agent.target_position = target.global_position
			
			if not navigation_agent.is_navigation_finished():
				var next_position = navigation_agent.get_next_path_position()
				var direction = agent.global_position.direction_to(next_position)
				agent.velocity = direction * agent.move_speed
			else:
				var direction = agent.global_position.direction_to(target.global_position)
				agent.velocity = direction * agent.move_speed
		else:
			var direction = agent.global_position.direction_to(target.global_position)
			agent.velocity = direction * agent.move_speed
		
		return false
	
	# In attack range - attack!
	agent.velocity = Vector2.ZERO
	if attack_component and is_instance_valid(target):
		attack_component.attack(target)
	
	return false

func on_exit(agent: Node) -> void:
	super.on_exit(agent)
	agent.velocity = Vector2.ZERO
	
	# Restore original attack damage
	if attack_component and original_attack_damage > 0:
		attack_component.attack_damage = original_attack_damage
		print(agent.name, ": Sword unequipped, attack damage restored to ", attack_component.attack_damage)
	
	# Clear target status
	if goap_target and is_instance_valid(goap_target):
		goap_target.is_target = false
		goap_target.chaser = null
	
	# Clear navigation
	if navigation_agent:
		navigation_agent.target_position = agent.global_position

func _find_nearest_predator(agent: Node) -> Node:
	"""Find the nearest predator within scanner range"""
	# Check if we are being chased first
	if agent.has_node("GOAPAgent"):
		var goap_agent = agent.get_node("GOAPAgent")
		if is_instance_valid(goap_agent.chaser):
			return goap_agent.chaser

	if not scanner_component:
		if agent.has_node("ScannerComponent"):
			scanner_component = agent.get_node("ScannerComponent")
		else:
			return null
	
	var nearby_bodies = scanner_component.get_overlapping_bodies()
	var nearest_predator: Node = null
	var nearest_distance: float = INF
	
	for body in nearby_bodies:
		if body.is_in_group("predator"):
			var distance = agent.global_position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_predator = body
	
	return nearest_predator
