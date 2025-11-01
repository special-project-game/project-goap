# PersonInfoUI.gd
extends Control

## Interactive UI that appears when clicking on a person
## Shows health, hunger, inventory, and current task

@export var person: CharacterBody2D
@export var goap_agent: PersonGOAPAgent

# UI References
@onready var health_bar: ProgressBar = $Panel/VBoxContainer/StatsContainer/HealthBar
@onready var health_label: Label = $Panel/VBoxContainer/StatsContainer/HealthBar/HealthLabel
@onready var hunger_bar: ProgressBar = $Panel/VBoxContainer/StatsContainer/HungerBar
@onready var hunger_label: Label = $Panel/VBoxContainer/StatsContainer/HungerBar/HungerLabel
@onready var level_label: Label = $Panel/VBoxContainer/HeaderContainer/LevelLabel
@onready var exp_label: Label = $Panel/VBoxContainer/HeaderContainer/ExpLabel
@onready var inventory_label: Label = $Panel/VBoxContainer/InventoryContainer/InventoryLabel
@onready var task_label: Label = $Panel/VBoxContainer/TaskContainer/TaskLabel
@onready var plan_label: Label = $Panel/VBoxContainer/PlanContainer/PlanLabel
@onready var close_button: Button = $Panel/VBoxContainer/HeaderContainer/CloseButton

var update_timer: float = 0.0
var update_interval: float = 0.1

func _ready():
	# Hide by default
	hide()
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Position at top-right corner
	position = Vector2(get_viewport_rect().size.x - size.x - 20, 20)

func _process(delta: float):
	if not visible:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_ui()

func show_for_person(target_person: CharacterBody2D):
	person = target_person
	
	# Find GOAP agent
	if person.has_node("GOAPAgent"):
		goap_agent = person.get_node("GOAPAgent")
	else:
		push_error("Person has no GOAPAgent!")
		return
	
	_update_ui()
	show()

func _update_ui():
	if not person or not is_instance_valid(person) or not goap_agent or not is_instance_valid(goap_agent):
		hide()
		return
	
	_update_health()
	_update_hunger()
	_update_level_exp()
	_update_inventory()
	_update_task()
	_update_plan()

func _update_health():
	if not person.has_node("HealthComponent"):
		health_bar.visible = false
		return
	
	var health_component = person.get_node("HealthComponent")
	var current_health = health_component.health
	var max_health = health_component.MAX_HEALTH
	
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "Health: %.0f/%.0f" % [current_health, max_health]
	
	# Color based on health percentage
	var health_percent = current_health / max_health
	if health_percent > 0.6:
		health_bar.modulate = Color.GREEN
	elif health_percent > 0.3:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED

func _update_hunger():
	var hunger = goap_agent.hunger
	var max_hunger = goap_agent.max_hunger
	
	hunger_bar.max_value = max_hunger
	hunger_bar.value = hunger
	hunger_label.text = "Hunger: %.0f/%.0f" % [hunger, max_hunger]
	
	# Color based on hunger
	var hunger_percent = hunger / max_hunger
	if hunger_percent < 0.3:
		hunger_bar.modulate = Color.GREEN
	elif hunger_percent < 0.7:
		hunger_bar.modulate = Color.YELLOW
	else:
		hunger_bar.modulate = Color.RED

func _update_level_exp():
	var level = goap_agent.level
	var exp = goap_agent.experience
	var next_level_exp = (level + 1) * 100
	
	level_label.text = "Level %d" % level
	exp_label.text = "Exp: %d/%d" % [exp, next_level_exp]

func _update_inventory():
	var wood = goap_agent.wood_count
	var food = goap_agent.food_count
	
	var inventory_text = "Inventory:\n"
	inventory_text += "  Wood: %d\n" % wood
	inventory_text += "  Food: %d" % food
	
	inventory_label.text = inventory_text

func _update_task():
	var task_text = "Current Task:\n"
	
	if goap_agent.current_goal:
		task_text += "  Goal: %s\n" % goap_agent.current_goal.goal_name
	else:
		task_text += "  Goal: None\n"
	
	if goap_agent.current_action:
		task_text += "  Action: %s" % goap_agent.current_action.action_name
	else:
		task_text += "  Action: Idle"
	
	task_label.text = task_text

func _update_plan():
	var plan_text = "Action Plan:\n"
	
	if goap_agent.current_plan.is_empty():
		plan_text += "  No active plan"
	else:
		for i in range(goap_agent.current_plan.size()):
			var action = goap_agent.current_plan[i]
			if i == goap_agent.current_action_index:
				plan_text += "  ▶ %s\n" % action.action_name
			else:
				plan_text += "    %s\n" % action.action_name
	
	plan_label.text = plan_text

func _on_close_pressed():
	hide()
