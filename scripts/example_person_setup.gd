# example_person_setup.gd
# This script demonstrates how to set up a Person entity with GOAP in code
# Alternatively, you can do this through the Godot editor

extends Node2D

func _ready():
	# This is an example of how to add GOAP to a Person entity
	# In practice, you should do this in the editor by adding nodes to the person.tscn
	
	var person = get_node("Person") # Adjust path as needed
	if not person:
		print("No person found!")
		return
	
	# Check if GOAPAgent already exists
	if person.has_node("GOAPAgent"):
		print("Person already has GOAP setup!")
		return
	
	# Create the GOAP agent
	var goap_agent = PersonGOAPAgent.new()
	goap_agent.name = "GOAPAgent"
	goap_agent.entity = person
	goap_agent.update_interval = 0.5
	person.add_child(goap_agent)
	
	# Add Actions
	var find_tree_action = FindTreeAction.new()
	find_tree_action.name = "FindTreeAction"
	goap_agent.add_child(find_tree_action)
	
	var chop_tree_action = ChopTreeAction.new()
	chop_tree_action.name = "ChopTreeAction"
	goap_agent.add_child(chop_tree_action)
	
	var find_food_action = FindFoodAction.new()
	find_food_action.name = "FindFoodAction"
	goap_agent.add_child(find_food_action)
	
	var eat_food_action = EatFoodAction.new()
	eat_food_action.name = "EatFoodAction"
	goap_agent.add_child(eat_food_action)
	
	var rest_action = RestAction.new()
	rest_action.name = "RestAction"
	goap_agent.add_child(rest_action)
	
	# Add Goals
	var hunger_goal = SatisfyHungerGoal.new()
	hunger_goal.name = "SatisfyHungerGoal"
	goap_agent.add_child(hunger_goal)
	
	var levelup_goal = LevelUpGoal.new()
	levelup_goal.name = "LevelUpGoal"
	goap_agent.add_child(levelup_goal)
	
	var idle_goal = IdleGoal.new()
	idle_goal.name = "IdleGoal"
	goap_agent.add_child(idle_goal)
	
	# Connect signals for debugging
	goap_agent.plan_found.connect(_on_plan_found)
	goap_agent.plan_failed.connect(_on_plan_failed)
	goap_agent.goal_completed.connect(_on_goal_completed)
	
	print("GOAP system successfully added to ", person.name)

func _on_plan_found(plan: Array):
	print("New plan with ", plan.size(), " actions")

func _on_plan_failed():
	print("Failed to create a plan!")

func _on_goal_completed(goal: GOAPGoal):
	print("Goal completed: ", goal.goal_name)
