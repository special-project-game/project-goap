extends Control

const ItemType = preload("res://scripts/inventory/ItemType.gd")

@export var person: CharacterBody2D
@export var goap_agent: PersonGOAPAgent

@onready var name_label: Label = $PanelContainer/VBoxContainer/HeaderContainer/NameLevelLabel
@onready var exp_label: Label = $PanelContainer/VBoxContainer/ExpLabel
@onready var close_button: Button = $PanelContainer/VBoxContainer/HeaderContainer/CloseButton
@onready var health_bar: ProgressBar = $PanelContainer/VBoxContainer/StatsContainer/HealthBar
@onready var health_value_label: Label = $PanelContainer/VBoxContainer/StatsContainer/HealthRow/HealthValueLabel
@onready var hunger_bar: ProgressBar = $PanelContainer/VBoxContainer/StatsContainer/HungerBar
@onready var hunger_value_label: Label = $PanelContainer/VBoxContainer/StatsContainer/HungerRow/HungerValueLabel
@onready var inventory_label: Label = $PanelContainer/VBoxContainer/InventoryContainer/InventoryLabel
@onready var task_label: Label = $PanelContainer/VBoxContainer/TaskContainer/TaskLabel
@onready var plan_label: Label = $PanelContainer/VBoxContainer/PlanContainer/PlanLabel
@onready var swoosh_open: AudioStreamPlayer = $SwooshOpenSFX
@onready var swoosh_close: AudioStreamPlayer = $SwooshCloseSFX

var update_timer := 0.0
var update_interval := 0.1

var fade_tween: Tween
var health_tween: Tween
var hunger_tween: Tween


func _ready() -> void:
	# Start hidden and invisible
	self.modulate.a = 0.0
	hide()

	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	position = Vector2(get_viewport_rect().size.x - size.x - 20, 20)

func _process(delta: float) -> void:
	if not visible:
		return

	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_ui()

#Show UI with fade in
func show_for_person(target_person: CharacterBody2D) -> void:
	person = target_person

	if person.has_node("GOAPAgent"):
		goap_agent = person.get_node("GOAPAgent")
	else:
		push_error("Selected person has no GOAPAgent!")
		return

	_update_ui()
	_fade_in()

#Fade-in function
func _fade_in() -> void:
	if swoosh_open:
		swoosh_open.play()
	show()

	if fade_tween:
		fade_tween.kill()

	fade_tween = create_tween()

	self.modulate.a = 0.0
	self.position.x += 40

	fade_tween.tween_property(self, "modulate:a", 1.0, 0.25)\
		.set_trans(Tween.TRANS_SINE)
	fade_tween.parallel().tween_property(self, "position:x", self.position.x - 40, 0.25)\
		.set_trans(Tween.TRANS_SINE)

#Fade out after close button
func _on_close_pressed() -> void:
	_fade_out()

# NEW: fade-out function
func _fade_out() -> void:
	if swoosh_close:
		swoosh_close.play()
		
	if fade_tween:
		fade_tween.kill()

	fade_tween = create_tween()

	fade_tween.tween_property(self, "modulate:a", 0.0, 0.25)\
		.set_trans(Tween.TRANS_SINE)
	fade_tween.parallel().tween_property(self, "position:x", self.position.x + 40, 0.25)\
		.set_trans(Tween.TRANS_SINE)

	fade_tween.finished.connect(func():
		hide()
	)

func _update_ui() -> void:
	if not person or not is_instance_valid(person) or not goap_agent or not is_instance_valid(goap_agent):
		_fade_out()
		return

	_update_name_level_exp()
	_update_health()
	_update_hunger()
	_update_inventory()
	_update_task()
	_update_plan()

func _update_name_level_exp() -> void:
	var level := goap_agent.level
	var exp := goap_agent.experience
	var next_level_exp := (level + 1) * 100

	name_label.text = "Person (Level %d)" % level
	exp_label.text = "Exp: %d / %d" % [exp, next_level_exp]

func _update_health() -> void:
	if not person.has_node("HealthComponent"):
		health_bar.visible = false
		health_value_label.visible = false
		return

	var hc = person.get_node("HealthComponent")
	var current = hc.health
	var max = hc.MAX_HEALTH

	# Update text instantly
	health_value_label.text = "%d / %d" % [current, max]
	health_bar.max_value = max

	# Animate only if needed
	if health_tween:
		health_tween.kill()

	health_tween = create_tween()
	health_tween.tween_property(health_bar, "value", current, 0.25).set_trans(Tween.TRANS_SINE)

	# Update bar color
	var pct := float(current) / float(max)
	if pct > 0.6:
		health_bar.modulate = Color.GREEN
	elif pct > 0.3:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED

func _update_hunger() -> void:
	var current := goap_agent.hunger
	var max := goap_agent.max_hunger

	# Update text instantly
	hunger_value_label.text = "%d / %d" % [current, max]
	hunger_bar.max_value = max

	# Animate smooth bar movement
	if hunger_tween:
		hunger_tween.kill()

	hunger_tween = create_tween()
	hunger_tween.tween_property(hunger_bar, "value", current, 0.25).set_trans(Tween.TRANS_SINE)

	# Color indicators
	var pct := float(current) / float(max)
	if pct < 0.3:
		hunger_bar.modulate = Color.DARK_RED
	elif pct < 0.7:
		hunger_bar.modulate = Color.ORANGE_RED
	else:
		hunger_bar.modulate = Color.YELLOW

func _update_inventory() -> void:
	if not goap_agent.inventory:
		inventory_label.text = "(No Inventory)"
		return

	var used = goap_agent.inventory.get_used_slot_count()
	var max_slots = goap_agent.inventory.max_slots

	var text := "Inventory (%d / %d slots):\n" % [used, max_slots]
	var items = goap_agent.inventory.get_all_items()

	if items.is_empty():
		text += "  (Empty)"
	else:
		for item_type in items.keys():
			var name = ItemType.get_item_name(item_type)
			var count = items[item_type]
			text += "  %s: %d\n" % [name, count]

	inventory_label.text = text

func _update_task() -> void:
	var text := "Current Task:\n"

	if goap_agent.current_goal:
		text += "  Goal: %s\n" % goap_agent.current_goal.goal_name
	else:
		text += "  Goal: None\n"

	if goap_agent.current_action:
		text += "  Action: %s" % goap_agent.current_action.action_name
	else:
		text += "  Action: Idle"

	task_label.text = text

func _update_plan() -> void:
	var text := "Action Plan:\n"

	var plan := goap_agent.current_plan
	var index := goap_agent.current_action_index

	if plan.is_empty():
		text += "  No active plan"
	else:
		# Show 2 actions: current & the next one
		for i in range(index, min(index + 2, plan.size())):
			var action = plan[i]

			if i == index:
				text += "  ▶ %s\n" % action.action_name  # highlight active
			else:
				text += "    %s\n" % action.action_name  # next action

	# If fewer than 2 actions exist, no problem — it shows what it can
	plan_label.text = text
