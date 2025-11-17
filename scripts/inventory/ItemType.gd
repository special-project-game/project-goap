# ItemType.gd
class_name ItemType

## Enum defining all item types in the game
enum Type {
	NONE = 0,
	WOOD = 1,
	APPLE = 2,
	STONE = 3,
	BERRY = 4,
	MEAT = 5,
	SWORD = 6,
	# Add more item types as needed
}

## Get a human-readable name for an item type
static func get_item_name(type: Type) -> String:
	match type:
		Type.NONE:
			return "None"
		Type.WOOD:
			return "Wood"
		Type.APPLE:
			return "Apple"
		Type.STONE:
			return "Stone"
		Type.BERRY:
			return "Berry"
		Type.MEAT:
			return "Meat"
		Type.SWORD:
			return "Sword"
		_:
			return "Unknown"

## Check if an item type is food
static func is_food(type: Type) -> bool:
	return type in [Type.APPLE, Type.BERRY, Type.MEAT]

## Get the nutrition value of food items
static func get_food_value(type: Type) -> float:
	match type:
		Type.APPLE:
			return 30.0
		Type.BERRY:
			return 15.0
		Type.MEAT:
			return 50.0
		_:
			return 0.0
