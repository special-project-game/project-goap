extends State

@export var hit_box_component : HitBoxComponent
@onready var find_tree = $"../FindTree"

var target : Node2D

func Enter():
	if find_tree.target:
		target = find_tree.target

func Update(delta):
	pass

func Physics_Update(delta):
	if find_tree.target:
		target = find_tree.target
	if !target:
		Transitioned.emit(self, "wander")

	var current_agent_position = owner.global_position
	var tree_position = find_tree.target_position
	var distance_to_tree = current_agent_position.distance_to(tree_position)
	
	if distance_to_tree > 10:
		Transitioned.emit(self, "findtree")
	
	owner.velocity = Vector2.ZERO
	hit_box_component.attack()
	
