# Status.gd
extends Control

var entity: Entity = owner

var health_component: HealthComponent
var goap_agent: GOAPAgent
@onready var label = $PanelContainer/VBoxContainer/Label
@onready var health_bar = $PanelContainer/VBoxContainer/HealthBar
@onready var hunger_bar = $PanelContainer/VBoxContainer/HungerBar
@onready var panel_container = $PanelContainer
@onready var v_box_container = $PanelContainer/VBoxContainer


var update_timer: float = 0.0
var update_interval: float = 10.0

var show_on_change_timer: float = 0.0
var auto_hide_duration: float = 3.0

var is_hovering: bool = false
var current_health_cached: float = -1.0
var current_action_cached: GOAPAction = null



func _ready():
	v_box_container.visible = false
	entity = owner
	if not is_instance_valid(entity):
		printerr("Entity is invalid")
		return

	if entity.has_node("GOAPAgent"):
		goap_agent = entity.get_node("GOAPAgent")
	
	if entity.has_node("HealthComponent"):
		health_component = entity.get_node("HealthComponent")
		current_health_cached = health_component.health
	
	_update_status()
		


func _process(delta):
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_check_for_changes()
	
	if show_on_change_timer > 0 and not is_hovering:
		show_on_change_timer -= delta
		if show_on_change_timer <= 0:
			v_box_container.visible = false

	if v_box_container.visible:
		_update_status()

func _update_status():
	_update_health()
	_update_hunger()
	_update_task()

func _check_for_changes():
	var new_health = health_component.health
	var new_action = goap_agent.current_action
	var changed = false
	
	if current_health_cached != new_health:
		current_health_cached = new_health
		changed = true
	
	if current_action_cached != new_action:
		current_action_cached = new_action
		changed = true
	
	if changed:
		v_box_container.visible = true
		show_on_change_timer = auto_hide_duration

func _update_health():
	var max_health = health_component.MAX_HEALTH
	var current_health = health_component.health
	
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	var health_percent = current_health / max_health
	var fill_stylebox = health_bar.get_theme_stylebox("fill")
	
	if fill_stylebox is StyleBoxFlat:
		if health_percent <= 0.3:
			fill_stylebox.bg_color = Color(0.62, 0.081, 0.09, 1.0)
		elif health_percent <= 0.5:
			fill_stylebox.bg_color = Color(0.96, 0.688, 0.0, 1.0)
		else:
			fill_stylebox.bg_color = Color(0.197, 0.92, 0.101, 1.0)
	

func _update_hunger():
	var max_hunger = goap_agent.max_hunger
	var current_hunger = goap_agent.hunger
	
	hunger_bar.max_value = max_hunger
	hunger_bar.value = current_hunger

func _update_task():
	var current_action = goap_agent.current_action
	if not current_action == null:
		var text = current_action.action_name
		label.set_visible(true)
		label.set_text(text)
	else:
		label.set_visible(false)


func _on_panel_container_mouse_entered():
	is_hovering = true
	v_box_container.visible = true


func _on_panel_container_mouse_exited():
	is_hovering = false
	v_box_container.visible = false
