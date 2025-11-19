# PersonGOAPAgent.gd
extends GOAPAgent
class_name PersonGOAPAgent

## GOAP Agent specialized for Person entities
## Manages stats like hunger, experience, level, and inventory

# Preload inventory system classes
const ItemType = preload("res://scripts/inventory/ItemType.gd")
const Item = preload("res://scripts/inventory/Item.gd")
const Inventory = preload("res://scripts/inventory/Inventory.gd")

@onready var label: Label

# Stats
var hunger: float = 100.0        # START FULL (100 → 0)
var max_hunger: float = 100.0
@export var hunger_rate: float = 1.0  # Hunger decrease per second
@export var heal_rate: float = 1.0

# Inventory system
var inventory: Inventory

var experience: int = 0
var level: int = 1

@export var is_target: bool = false
@export var chaser: Node = null

# Health component reference
var health_component: HealthComponent

func _ready():
	# Initialize inventory system
	inventory = Inventory.new(10)  # 10 slots
	
	super._ready()

	# Disable movement if controlled by GOAP
	if entity and "goap_controlled" in entity:
		entity.goap_controlled = true
		print(entity.name, ": GOAP control enabled.")

	if owner.has_node("Label"):
		label = owner.get_node("Label")

	# Show current info on debug label
	if not current_action == null:
		var text := "%s, %.2f, %.2f" % [current_action.action_name, health_component.health, hunger]
		label.visible = true
		label.text = text
	else:
		label.visible = false


func _initialize_world_state() -> void:
	if entity and entity.has_node("HealthComponent"):
		health_component = entity.get_node("HealthComponent")

	world_state["is_hungry"] = false
	world_state["near_tree"] = false
	world_state["near_food"] = false
	world_state["has_wood"] = false
	world_state["has_food"] = false
	world_state["has_target"] = false
	world_state["is_resting"] = false
	world_state["is_safe"] = true

	world_state["hunger"] = hunger
	world_state["wood_count"] = inventory.get_item_count(ItemType.Type.WOOD)
	world_state["food_count"] = inventory.get_item_count(ItemType.Type.APPLE)
	world_state["level"] = level


func _process(delta: float):
	# Debug label
	if not current_action == null:
		var text := "%s, %.2f, %.2f" % [current_action.action_name, health_component.health, hunger]
		label.visible = true
		label.text = text
	else:
		label.visible = false
		
	# Hunger decreases over time
	hunger = max(hunger - hunger_rate * delta, 0.0)

	# Starvation (when hunger hits 0)
	if hunger <= 0.0 and health_component:
		health_component.health = max(0.0, health_component.health - 0.5 * delta)

	# Auto-heal ONLY when well-fed (example: above 70)
	if hunger >= 70.0 and health_component and health_component.health < health_component.MAX_HEALTH:
		health_component.health = min(
			health_component.health + heal_rate * delta,
			health_component.MAX_HEALTH
		)

	# If health hits 0, remove person
	if health_component.health <= 0:
		owner.queue_free()

	# If this person is targeted, world is unsafe
	if is_target:
		world_state["is_safe"] = false
	
	super._process(delta)


func _update_world_state() -> void:
	world_state["hunger"] = hunger
	world_state["is_hungry"] = hunger <= 30.0  # LOW hunger = hungry state

	# Inventory states
	world_state["wood_count"] = inventory.get_item_count(ItemType.Type.WOOD)
	world_state["has_wood"] = false   # Reset to allow continuous gathering

	world_state["food_count"] = inventory.get_item_count(ItemType.Type.APPLE)
	world_state["has_food"] = inventory.get_item_count(ItemType.Type.APPLE) > 0

	world_state["is_resting"] = false
	world_state["near_tree"] = false
	world_state["near_food"] = false

	# Level update
	world_state["level"] = level

	if experience >= _get_experience_for_level(level + 1):
		_level_up()


func add_wood(amount: int = 1) -> void:
	var overflow = inventory.add_item(ItemType.Type.WOOD, amount)
	var added = amount - overflow
	if added > 0:
		experience += added * 10
		print(entity.name, ": Got ", added, " wood! Total: ", inventory.get_item_count(ItemType.Type.WOOD))
	if overflow > 0:
		print(entity.name, ": Inventory full! Lost ", overflow, " wood")


func consume_wood(amount: int) -> void:
	var removed = inventory.remove_item(ItemType.Type.WOOD, amount)
	if removed < amount:
		print(entity.name, ": Tried to consume too much wood, only had ", removed)


func add_food(amount: int = 1) -> void:
	var overflow = inventory.add_item(ItemType.Type.APPLE, amount)
	var added = amount - overflow
	if added > 0:
		print(entity.name, ": Got ", added, " food! Total: ", inventory.get_item_count(ItemType.Type.APPLE))
	if overflow > 0:
		print(entity.name, ": Inventory full! Lost ", overflow, " food")


func consume_food(amount: int = 1) -> void:
	var removed = inventory.remove_item(ItemType.Type.APPLE, amount)
	if removed > 0:
		hunger = min(max_hunger, hunger + ItemType.get_food_value(ItemType.Type.APPLE) * removed)
		print(entity.name, ": Ate ", removed, " food! Hunger = ", hunger)


func _level_up() -> void:
	level += 1
	print(entity.name, " leveled up to ", level)

	if health_component:
		health_component.MAX_HEALTH += 5.0
		health_component.health = health_component.MAX_HEALTH
		print(entity.name, ": Max HP increased to ", health_component.MAX_HEALTH)


func _get_experience_for_level(target_level: int) -> int:
	return target_level * 100


func get_stats() -> Dictionary:
	return {
		"level": level,
		"experience": experience,
		"hunger": hunger,
		"wood_count": inventory.get_item_count(ItemType.Type.WOOD),
		"food_count": inventory.get_item_count(ItemType.Type.APPLE),
		"health": health_component.health if health_component else 0.0,
		"max_health": health_component.MAX_HEALTH if health_component else 0.0
	}
