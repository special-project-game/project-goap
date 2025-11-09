# Item.gd
extends RefCounted
class_name Item

## Represents a single item stack in the inventory

const ITEM_TYPE_NONE = 0  # ItemType.Type.NONE

var item_type: int = ITEM_TYPE_NONE  # ItemType.Type enum value
var quantity: int = 0

## Maximum stack size for items
const MAX_STACK_SIZE: int = 50

func _init(type: int = ITEM_TYPE_NONE, qty: int = 0):
	item_type = type
	quantity = clamp(qty, 0, MAX_STACK_SIZE)

## Add to this stack, returns overflow amount
func add(amount: int) -> int:
	var total = quantity + amount
	if total <= MAX_STACK_SIZE:
		quantity = total
		return 0
	else:
		quantity = MAX_STACK_SIZE
		return total - MAX_STACK_SIZE

## Remove from this stack, returns actual amount removed
func remove(amount: int) -> int:
	var removed = min(amount, quantity)
	quantity -= removed
	return removed

## Check if this stack is empty
func is_empty() -> bool:
	return quantity <= 0 or item_type == ITEM_TYPE_NONE

## Check if this stack is full
func is_full() -> bool:
	return quantity >= MAX_STACK_SIZE

## Check if this stack can accept more of a specific item type
func can_add(type: int, amount: int = 1) -> bool:
	if is_empty():
		return true
	if item_type == type and quantity + amount <= MAX_STACK_SIZE:
		return true
	return false

## Get remaining space in this stack
func get_remaining_space() -> int:
	if is_empty():
		return MAX_STACK_SIZE
	return MAX_STACK_SIZE - quantity

## Clear this item stack
func clear() -> void:
	item_type = ITEM_TYPE_NONE
	quantity = 0

## Create a copy of this item
func duplicate() -> Item:
	return Item.new(item_type, quantity)

## Get a string representation of this item
func get_display_name() -> String:
	if is_empty():
		return "Empty"
	# Will use ItemType.get_item_name when called from code that has ItemType loaded
	return "Item x%d" % quantity
