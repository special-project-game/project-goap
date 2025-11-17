# PredatorGOAPAgent.gd
extends GOAPAgent
class_name PredatorGOAPAgent

@onready var label: Label
## GOAP Agent specialized for Predator entities
## Manages stats like hunger, experience, and level

# Stats
var hunger: float = 0.0
var max_hunger: float = 100.0
@export var hunger_rate: float = 1.0 # Hunger per second
@export var heal_rate: float = 1.0

var food_count: int = 0
var experience: int = 0
var level: int = 1

# Health component reference
var health_component: HealthComponent



func _ready():
	super._ready()
	
	# Disable entity's autonomous movement when GOAP is active
	if entity and "goap_controlled" in entity:
		entity.goap_controlled = true
		print(entity.name, ": GOAP control enabled, autonomous movement disabled")
	
	#if owner.has_node("Label"):
		#label = owner.get_node("Label")
	#
	#if not current_action == null:
		#var text = "%s, %.2f, %.2f" % [current_action.action_name, health_component.health, hunger]
		#label.set_visible(true)
		#label.set_text(text)
	#else:
		#label.set_visible(false)

func _initialize_world_state() -> void:
	# Get health component
	if entity and entity.has_node("HealthComponent"):
		health_component = entity.get_node("HealthComponent")
	
	# Initialize world state
	world_state["is_hungry"] = false
	world_state["near_tree"] = false
	world_state["near_prey"] = false
	world_state["near_food"] = false
	world_state["has_food"] = false
	world_state["has_killed"] = false
	world_state["is_resting"] = false
	world_state["prey_available"] = false
	world_state["hunger"] = hunger
	world_state["food_count"] = food_count
	world_state["level"] = level

func _process(delta: float):
	## Update label
	#if not current_action == null:
		#var text = "%s, %.2f, %.2f" % [current_action.action_name, health_component.health, hunger]
		#label.set_visible(true)
		#label.set_text(text)
	#else:
		#label.set_visible(false)
		
	# Update hunger
	hunger = min(hunger + hunger_rate * delta, max_hunger)

	# if hunger maxed out, lose health
	if hunger >= max_hunger and health_component:
		health_component.health = max(0.0, health_component.health - 0.5 * delta) # Lose 0.5 health per second when starving
	if health_component.health <= 0:
		get_parent().queue_free()
	
	if hunger <= 30.0 and health_component.health < health_component.MAX_HEALTH:
		health_component.health = min(health_component.health + heal_rate * delta, health_component.MAX_HEALTH)
		hunger = min(hunger + hunger_rate * delta, max_hunger)

	super._process(delta)

func _update_world_state() -> void:
	# Update hunger state
	world_state["hunger"] = hunger
	world_state["is_hungry"] = hunger >= 70.0
	
	# Update food inventory
	world_state["food_count"] = food_count
	world_state["has_food"] = food_count > 0
	
	# Update kill staste
	world_state["has_killed"] = false
	
	# Reset temporary states
	world_state["is_resting"] = false
	world_state["near_tree"] = false
	world_state["near_food"] = false
	world_state["near_prey"] = false
	#world_state["prey_available"] = false
	
	# Update level
	world_state["level"] = level
	
	# Check experience for level up
	if experience >= _get_experience_for_level(level + 1):
		_level_up()

func add_kill_exp(amount: int = 1) -> void:
	experience += amount * 10
	

func add_food(amount: int = 1) -> void:
	food_count += amount
	print(entity.name, ": Got ", amount, " food! Total: ", food_count)

func consume_food(amount: int = 1) -> void:
	food_count = max(0, food_count - amount)
	# Restore hunger
	hunger = max(0.0, hunger - 50.0)
	print(entity.name, ": Ate food! Hunger reduced to ", hunger)

func _level_up() -> void:
	level += 1
	print(entity.name, " LEVELED UP to level ", level, "!")
	
	# Increase max health
	if health_component:
		health_component.MAX_HEALTH += 5.0
		health_component.health = health_component.MAX_HEALTH
		print(entity.name, ": Max health increased to ", health_component.MAX_HEALTH)

func _get_experience_for_level(target_level: int) -> int:
	# Simple formula: level * 100
	return target_level * 100

## Get current stats as a dictionary
func get_stats() -> Dictionary:
	return {
		"level": level,
		"experience": experience,
		"hunger": hunger,
		"food_count": food_count,
		"health": health_component.health if health_component else 0,
		"max_health": health_component.MAX_HEALTH if health_component else 0
	}
