# PersonGOAPAgent.gd
extends GOAPAgent
class_name PersonGOAPAgent

## GOAP Agent specialized for Person entities
## Manages stats like hunger, experience, level, and inventory

# Preload inventory system classes
const ItemType = preload("res://scripts/inventory/ItemType.gd")
const Item = preload("res://scripts/inventory/Item.gd")
const Inventory = preload("res://scripts/inventory/Inventory.gd")

# Stats
var hunger: float = 0.0
var max_hunger: float = 100.0
var hunger_rate: float = 1.0 # Hunger per second

# Inventory system
var inventory: Inventory

# Legacy compatibility (deprecated - use inventory instead)
var wood_count: int = 0:
	get:
		return inventory.get_item_count(ItemType.Type.WOOD) if inventory else 0
var food_count: int = 0:
	get:
		return inventory.get_item_count(ItemType.Type.APPLE) if inventory else 0

var experience: int = 0
var level: int = 1

# Health component reference
var health_component: HealthComponent

func _ready():
	# Initialize inventory system
	inventory = Inventory.new(10)  # 10 slots
	
	super._ready()
	
	# Disable entity's autonomous movement when GOAP is active
	if entity and "goap_controlled" in entity:
		entity.goap_controlled = true
		print(entity.name, ": GOAP control enabled, autonomous movement disabled")

func _initialize_world_state() -> void:
	# Get health component
	if entity and entity.has_node("HealthComponent"):
		health_component = entity.get_node("HealthComponent")
	
	# Initialize world state
	world_state["is_hungry"] = false
	world_state["near_tree"] = false
	world_state["near_food"] = false
	world_state["has_wood"] = false
	world_state["has_food"] = false
	world_state["is_resting"] = false
	world_state["hunger"] = hunger
	world_state["wood_count"] = inventory.get_item_count(ItemType.Type.WOOD)
	world_state["food_count"] = inventory.get_item_count(ItemType.Type.APPLE)
	world_state["level"] = level

func _process(delta: float):
	# Update hunger
	hunger = min(hunger + hunger_rate * delta, max_hunger)

	# if hunger maxed out, lose health
	if hunger >= max_hunger and health_component:
		health_component.health = max(0.0, health_component.health - 0.5 * delta) # Lose 0.5 health per second when starving
	
	super._process(delta)

func _update_world_state() -> void:
	# Update hunger state
	world_state["hunger"] = hunger
	world_state["is_hungry"] = hunger >= 70.0
	
	# Update wood/resources from inventory
	world_state["wood_count"] = inventory.get_item_count(ItemType.Type.WOOD)
	# Reset has_wood after each update cycle so LevelUpGoal keeps cycling
	# This makes wood gathering a continuous activity
	world_state["has_wood"] = false
	
	print(entity.name, ": _update_world_state called - has_wood reset to false")
	
	# Update food inventory
	world_state["food_count"] = inventory.get_item_count(ItemType.Type.APPLE)
	world_state["has_food"] = inventory.get_item_count(ItemType.Type.APPLE) > 0
	
	# Reset temporary states
	world_state["is_resting"] = false
	world_state["near_tree"] = false
	world_state["near_food"] = false
	
	# Update level
	world_state["level"] = level
	
	# Check experience for level up
	if experience >= _get_experience_for_level(level + 1):
		_level_up()

func add_wood(amount: int = 1) -> void:
	var overflow = inventory.add_item(ItemType.Type.WOOD, amount)
	var added = amount - overflow
	if added > 0:
		experience += added * 10 # 10 exp per wood
		print(entity.name, ": Got ", added, " wood! Total: ", inventory.get_item_count(ItemType.Type.WOOD), " | Exp: ", experience)
	if overflow > 0:
		print(entity.name, ": Inventory full! Couldn't add ", overflow, " wood")

func consume_wood(amount: int) -> void:
	var removed = inventory.remove_item(ItemType.Type.WOOD, amount)
	if removed < amount:
		print(entity.name, ": Warning - tried to consume ", amount, " wood but only had ", removed)

func add_food(amount: int = 1) -> void:
	var overflow = inventory.add_item(ItemType.Type.APPLE, amount)
	var added = amount - overflow
	if added > 0:
		print(entity.name, ": Got ", added, " food! Total: ", inventory.get_item_count(ItemType.Type.APPLE))
	if overflow > 0:
		print(entity.name, ": Inventory full! Couldn't add ", overflow, " food")

func consume_food(amount: int = 1) -> void:
	var removed = inventory.remove_item(ItemType.Type.APPLE, amount)
	if removed > 0:
		# Restore hunger
		hunger = max(0.0, hunger - 50.0 * removed)
		print(entity.name, ": Ate ", removed, " food! Hunger reduced to ", hunger)

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
		"wood_count": inventory.get_item_count(ItemType.Type.WOOD),
		"food_count": inventory.get_item_count(ItemType.Type.APPLE),
		"health": health_component.health if health_component else 0.0,
		"max_health": health_component.MAX_HEALTH if health_component else 0.0
	}
