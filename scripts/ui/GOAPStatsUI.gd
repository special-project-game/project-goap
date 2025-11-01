# GOAPStatsUI.gd
extends CanvasLayer

## UI to display GOAP agent stats for debugging and monitoring

@export var goap_agent: PersonGOAPAgent

@onready var label = $Panel/VBoxContainer/StatsLabel
@onready var plan_label = $Panel/VBoxContainer/PlanLabel
@onready var world_state_label = $Panel/VBoxContainer/WorldStateLabel

func _ready():
	if not goap_agent:
		# Try to find a goap agent in the scene
		var agents = get_tree().get_nodes_in_group("goap_agent")
		if not agents.is_empty():
			goap_agent = agents[0]

func _process(delta):
	if not goap_agent or not is_instance_valid(goap_agent):
		return
	
	_update_stats_display()
	_update_plan_display()
	_update_world_state_display()

func _update_stats_display():
	var stats = goap_agent.get_stats()
	var text = ""
	text += "=== STATS ===\n"
	text += "Level: %d\n" % stats.level
	text += "Experience: %d / %d\n" % [stats.experience, (stats.level + 1) * 100]
	text += "Health: %.1f / %.1f\n" % [stats.health, stats.max_health]
	text += "Hunger: %.1f / 100\n" % stats.hunger
	text += "Wood: %d\n" % stats.wood_count
	
	label.text = text

func _update_plan_display():
	var text = ""
	text += "=== CURRENT PLAN ===\n"
	
	if goap_agent.current_goal:
		text += "Goal: %s\n" % goap_agent.current_goal.goal_name
	else:
		text += "Goal: None\n"
	
	if goap_agent.current_action:
		text += "Action: %s\n" % goap_agent.current_action.action_name
	else:
		text += "Action: None\n"
	
	if not goap_agent.current_plan.is_empty():
		text += "Plan Steps:\n"
		for i in range(goap_agent.current_plan.size()):
			var action = goap_agent.current_plan[i]
			if i == goap_agent.current_action_index:
				text += "  -> %s (current)\n" % action.action_name
			else:
				text += "     %s\n" % action.action_name
	
	plan_label.text = text

func _update_world_state_display():
	var text = ""
	text += "=== WORLD STATE ===\n"
	
	for key in goap_agent.world_state:
		text += "%s: %s\n" % [key, str(goap_agent.world_state[key])]
	
	world_state_label.text = text
