# Inventory.gd
extends RefCounted
class_name Inventory

## Manages a collection of item slots with a maximum capacity

const ITEM_TYPE_NONE = 0  # ItemType.Type.NONE

signal inventory_changed
signal item_added(item_type: int, amount: int)
signal item_removed(item_type: int, amount: int)

var slots: Array = []  # Array of Item objects
var max_slots: int = 10

func _init(slot_count: int = 10):
	max_slots = slot_count
	_initialize_slots()

func _initialize_slots() -> void:
	slots.clear()
	for i in range(max_slots):
		# Create Item instance without type checking
		var item = load("res://scripts/inventory/Item.gd").new()
		slots.append(item)

## Add an item to the inventory, returns amount that couldn't be added
func add_item(item_type: int, amount: int) -> int:
	if item_type == ITEM_TYPE_NONE or amount <= 0:
		return amount
	
	var remaining = amount
	
	# First, try to add to existing stacks of the same type
	for slot in slots:
		if not slot.is_empty() and slot.item_type == item_type and not slot.is_full():
			var overflow = slot.add(remaining)
			remaining = overflow
			if remaining <= 0:
				break
	
	# If there's still items remaining, try to fill empty slots
	if remaining > 0:
		for slot in slots:
			if slot.is_empty():
				slot.item_type = item_type
				var overflow = slot.add(remaining)
				remaining = overflow
				if remaining <= 0:
					break
	
	var added = amount - remaining
	if added > 0:
		item_added.emit(item_type, added)
		inventory_changed.emit()
	
	return remaining

## Remove an item from the inventory, returns amount actually removed
func remove_item(item_type: int, amount: int) -> int:
	if item_type == ITEM_TYPE_NONE or amount <= 0:
		return 0
	
	var remaining = amount
	
	# Remove from stacks with this item type
	for slot in slots:
		if slot.item_type == item_type and not slot.is_empty():
			var removed_from_slot = slot.remove(remaining)
			remaining -= removed_from_slot
			
			# Clear the slot if it's now empty
			if slot.is_empty():
				slot.clear()
			
			if remaining <= 0:
				break
	
	var removed = amount - remaining
	if removed > 0:
		item_removed.emit(item_type, removed)
		inventory_changed.emit()
	
	return removed

## Get the total count of a specific item type
func get_item_count(item_type: int) -> int:
	var count = 0
	for slot in slots:
		if slot.item_type == item_type:
			count += slot.quantity
	return count

## Check if the inventory has at least a certain amount of an item
func has_item(item_type: int, amount: int = 1) -> bool:
	return get_item_count(item_type) >= amount

## Check if the inventory has space for an item
func has_space_for(item_type: int, amount: int = 1) -> bool:
	var remaining = amount
	
	# Check existing stacks
	for slot in slots:
		if slot.item_type == item_type and not slot.is_full():
			remaining -= slot.get_remaining_space()
			if remaining <= 0:
				return true
	
	# Check empty slots
	for slot in slots:
		if slot.is_empty():
			remaining -= Item.MAX_STACK_SIZE
			if remaining <= 0:
				return true
	
	return remaining <= 0

## Get the number of empty slots
func get_empty_slot_count() -> int:
	var count = 0
	for slot in slots:
		if slot.is_empty():
			count += 1
	return count

## Get the number of occupied slots
func get_used_slot_count() -> int:
	return max_slots - get_empty_slot_count()

## Check if the inventory is full
func is_full() -> bool:
	return get_empty_slot_count() == 0 and _all_slots_full()

func _all_slots_full() -> bool:
	for slot in slots:
		if not slot.is_full():
			return false
	return true

## Check if the inventory is empty
func is_empty() -> bool:
	for slot in slots:
		if not slot.is_empty():
			return false
	return true

## Clear all items from the inventory
func clear() -> void:
	for slot in slots:
		slot.clear()
	inventory_changed.emit()

## Get a specific slot by index
func get_slot(index: int):
	if index >= 0 and index < max_slots:
		return slots[index]
	return null

## Get all items as a dictionary with item types and quantities
func get_all_items() -> Dictionary:
	var items = {}
	for slot in slots:
		if not slot.is_empty():
			if items.has(slot.item_type):
				items[slot.item_type] += slot.quantity
			else:
				items[slot.item_type] = slot.quantity
	return items

## Get a string representation of the inventory
func get_summary() -> String:
	var result = "Inventory (%d/%d slots):\n" % [get_used_slot_count(), max_slots]
	var items = get_all_items()
	# Note: Need to load ItemType to get names
	# For now, just show type numbers
	for item_type in items:
		result += "  Type %d: %d\n" % [item_type, items[item_type]]
	return result
