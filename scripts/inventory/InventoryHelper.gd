# InventoryHelper.gd
class_name InventoryHelper

## Helper functions for working with the inventory system

const ItemType = preload("res://scripts/inventory/ItemType.gd")
const Item = preload("res://scripts/inventory/Item.gd")
const Inventory = preload("res://scripts/inventory/Inventory.gd")

## Create a new inventory with the specified number of slots
static func create_inventory(slot_count: int = 10) -> Inventory:
	return Inventory.new(slot_count)

## Get a formatted string showing inventory contents
static func get_inventory_summary(inv: Inventory) -> String:
	var result = "Inventory (%d/%d slots):\n" % [inv.get_used_slot_count(), inv.max_slots]
	var items = inv.get_all_items()
	
	if items.is_empty():
		result += "  (Empty)\n"
	else:
		for item_type in items:
			result += "  %s: %d\n" % [ItemType.get_item_name(item_type), items[item_type]]
	
	return result

## Get a formatted string for a single item
static func get_item_display_name(item_type: int, quantity: int) -> String:
	return "%s x%d" % [ItemType.get_item_name(item_type), quantity]

## Transfer items from one inventory to another
static func transfer_items(from_inv: Inventory, to_inv: Inventory, item_type: int, amount: int) -> int:
	var available = from_inv.get_item_count(item_type)
	var to_transfer = min(available, amount)
	
	if to_transfer <= 0:
		return 0
	
	# Try to add to destination
	var overflow = to_inv.add_item(item_type, to_transfer)
	var actually_transferred = to_transfer - overflow
	
	# Remove from source
	if actually_transferred > 0:
		from_inv.remove_item(item_type, actually_transferred)
	
	return actually_transferred
