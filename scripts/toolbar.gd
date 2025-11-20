extends Control
const TypeDefs = preload("res://scripts/TypeDef.gd")

@onready var mode_buttons: HBoxContainer = $ModeButtons
@onready var item_grid: GridContainer = $ItemGrid
@onready var selected_label: Label = $SelectedLabel

# 5 click sounds
@onready var click_sfx := [
	$ClickSFX1,
	$ClickSFX2,
	$ClickSFX3,
	$ClickSFX4
]

var click_index := 0
var initialized := false

signal mode_selected(mode: TypeDefs.Mode)
signal item_selected(id: int)

const ICON_PATH := "res://icons/"
var selected_slot: Control = null
var original_position: Vector2


func play_click_sfx():
	if not initialized:
		return

	click_sfx[click_index].play()
	click_index = (click_index + 1) % 4


func _ready():
	original_position = position

	_connect_button(mode_buttons.get_node("TilesButton"), _on_tiles_pressed)
	_connect_button(mode_buttons.get_node("ObjectsButton"), _on_objects_pressed)
	_connect_button(mode_buttons.get_node("EntitiesButton"), _on_entities_pressed)

	for slot in item_grid.get_children():
		_setup_slot(slot)

	selected_label.text = ""
	selected_label.modulate.a = 0.0

	_slide_in()
	_clear_all_slots()

	set_process_input(true)

	await get_tree().create_timer(0.3).timeout
	initialized = true


func _clear_all_slots():
	for slot in item_grid.get_children():
		slot.hide()
		slot.set_meta("id", null)
		slot.set_meta("name", null)


func _connect_button(btn: Button, func_ref):
	if not btn.pressed.is_connected(func_ref):
		btn.pressed.connect(func_ref)


func _setup_slot(slot: Control) -> void:
	var icon: TextureRect = slot.get_node("Icon")
	var bg: TextureRect = slot.get_node("Background")

	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	slot.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_slot_clicked(slot)
	)


func _slide_in():
	position.y = original_position.y + 40
	var t := create_tween()
	t.tween_property(self, "position:y", original_position.y, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _update_selected_button(selected: Button):
	for btn in mode_buttons.get_children():
		btn.button_pressed = (btn == selected)
		var t := create_tween()
		if btn == selected:
			t.tween_property(btn, "modulate", Color(1, 1, 1), 0.15)
		else:
			t.tween_property(btn, "modulate", Color(0.8, 0.8, 0.8), 0.15)


func _on_tiles_pressed():
	play_click_sfx()
	_update_selected_button(mode_buttons.get_node("TilesButton"))
	emit_signal("mode_selected", TypeDefs.Mode.PLACE_TILE)
	_populate(TypeDefs.Tile.values(), TypeDefs.TileName)


func _on_objects_pressed():
	play_click_sfx()
	_update_selected_button(mode_buttons.get_node("ObjectsButton"))
	emit_signal("mode_selected", TypeDefs.Mode.PLACE_OBJECT)
	_populate(TypeDefs.Objects.values(), TypeDefs.ObjectName)


func _on_entities_pressed():
	play_click_sfx()
	_update_selected_button(mode_buttons.get_node("EntitiesButton"))
	emit_signal("mode_selected", TypeDefs.Mode.PLACE_ENTITY)
	_populate(TypeDefs.Entity.values(), TypeDefs.EntityName)


func _populate(id_list: Array, name_dict: Dictionary):
	selected_slot = null
	selected_label.text = ""
	selected_label.modulate.a = 0.0

	for i in range(item_grid.get_child_count()):
		var slot: Control = item_grid.get_child(i)

		if i < id_list.size():
			var id = id_list[i]
			var name = name_dict[id]

			slot.show()
			slot.set_meta("id", id)
			slot.set_meta("name", name)

			var icon_node: TextureRect = slot.get_node("Icon")
			icon_node.texture = null

			var icon_path = ICON_PATH + name.to_lower() + ".png"
			if ResourceLoader.exists(icon_path):
				icon_node.texture = load(icon_path)

			var bg: TextureRect = slot.get_node("Background")
			bg.modulate = Color(1, 1, 1, 1)

			slot.modulate.a = 0.0
			create_tween().tween_property(slot, "modulate:a", 1.0, 0.2)
		else:
			slot.hide()
			slot.set_meta("id", null)
			slot.set_meta("name", null)


func _on_slot_clicked(slot: Control):
	play_click_sfx()

	if not slot.has_meta("id") or slot.get_meta("id") == null:
		return

	var id = slot.get_meta("id")
	var name = slot.get_meta("name")
	emit_signal("item_selected", id)

	if selected_slot:
		var prev_bg: TextureRect = selected_slot.get_node("Background")
		prev_bg.modulate = Color(1, 1, 1, 1)

	var bg: TextureRect = slot.get_node("Background")
	bg.modulate = Color(1.4, 1.3, 0.9, 1.0)

	selected_slot = slot

	selected_label.text = str(name)
	selected_label.modulate.a = 0.0

	var t := create_tween()
	t.tween_property(selected_label, "modulate:a", 1.0, 0.20)
	t.tween_interval(2.5)
	t.tween_property(selected_label, "modulate:a", 0.0, 0.25)


func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var idx := -1
		match event.keycode:
			KEY_1: idx = 0
			KEY_2: idx = 1
			KEY_3: idx = 2
			KEY_4: idx = 3
			KEY_5: idx = 4
			KEY_6: idx = 5
			KEY_7: idx = 6
			KEY_8: idx = 7
			KEY_9: idx = 8

		if idx >= 0 and idx < item_grid.get_child_count():
			var slot: Control = item_grid.get_child(idx)
			if slot.visible:
				_on_slot_clicked(slot)
