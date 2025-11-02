# GOAPDebugger.gd
extends Node2D

## Visual debugger for GOAP entities - draws info above their heads

@export var show_current_action: bool = true
@export var show_current_goal: bool = true
@export var show_stats: bool = true
@export var font_size: int = 12

var goap_agents: Array = []

func _ready():
	# Find all GOAP agents in the scene
	_refresh_agents()
	
	# Refresh periodically
	var timer = Timer.new()
	timer.timeout.connect(_refresh_agents)
	timer.wait_time = 2.0
	timer.autostart = true
	add_child(timer)

func _refresh_agents():
	goap_agents.clear()
	var all_nodes = get_tree().get_nodes_in_group("goap_agent")
	for node in all_nodes:
		if node is GOAPAgent:
			goap_agents.append(node)
	
	# Also search manually
	_find_goap_agents_recursive(get_tree().root)

func _find_goap_agents_recursive(node: Node):
	if node is GOAPAgent and node not in goap_agents:
		goap_agents.append(node)
	
	for child in node.get_children():
		_find_goap_agents_recursive(child)

func _process(delta):
	queue_redraw()

func _draw():
	for agent in goap_agents:
		if not is_instance_valid(agent) or not agent.entity:
			continue
		
		var entity = agent.entity
		if not is_instance_valid(entity):
			continue
		
		var pos = entity.global_position - global_position
		var y_offset = -40.0
		
		# Draw current goal
		if show_current_goal and agent.current_goal:
			var goal_text = "Goal: " + agent.current_goal.goal_name
			_draw_text(pos + Vector2(0, y_offset), goal_text, Color.YELLOW)
			y_offset -= 15
		
		# Draw current action
		if show_current_action and agent.current_action:
			var action_text = "Action: " + agent.current_action.action_name
			_draw_text(pos + Vector2(0, y_offset), action_text, Color.CYAN)
			y_offset -= 15
		
		# Draw stats (for PersonGOAPAgent)
		if show_stats and agent is PersonGOAPAgent:
			var stats_text = "Lvl:%d HP:%.0f/%.0f H:%.0f W:%d" % [
				agent.level,
				agent.health_component.health if agent.health_component else 0,
				agent.health_component.MAX_HEALTH if agent.health_component else 0,
				agent.hunger,
				agent.wood_count
			]
			_draw_text(pos + Vector2(0, y_offset), stats_text, Color.GREEN)

func _draw_text(pos: Vector2, text: String, color: Color):
	# Calculate text width for centering (approximate)
	var char_width = font_size * 0.6
	var text_width = text.length() * char_width
	var centered_pos = pos - Vector2(text_width / 2, 0)
	
	# Draw shadow
	draw_string(ThemeDB.fallback_font, centered_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
	# Draw text
	draw_string(ThemeDB.fallback_font, centered_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
