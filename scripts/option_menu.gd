extends Control

const SETTINGS_FILE := "user://settings.cfg"

@onready var music_slider: HSlider = $Panel/VBoxContainer/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SFXRow/SFXSlider
@onready var close_button: Button = $CloseButton

func _ready():
	visible = false
	modulate.a = 0.0

	load_settings()

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	close_button.pressed.connect(_on_close_pressed)


func _on_music_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
	save_settings()

func _on_sfx_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)
	save_settings()

func open_menu():
	show()
	self.modulate.a = 0.0

	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.25)

func _on_close_pressed():
	var blur = get_parent().get_node("BlurOverlay")
	var menu = self

	# Play swoosh closing sound
	get_parent().get_node("SwooshClose").play()

	var t := create_tween()
	t.tween_property(menu, "modulate:a", 0.0, 0.25)
	t.parallel().tween_property(blur, "modulate:a", 0.0, 0.25)

	t.finished.connect(func():
		menu.hide()
		blur.hide()
	)


func save_settings():
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_slider.value)
	cfg.set_value("audio", "sfx", sfx_slider.value)
	cfg.save(SETTINGS_FILE)

func load_settings():
	var cfg := ConfigFile.new()

	if cfg.load(SETTINGS_FILE) != OK:
		return

	if cfg.has_section_key("audio", "music"):
		music_slider.value = cfg.get_value("audio", "music")
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_slider.value)

	if cfg.has_section_key("audio", "sfx"):
		sfx_slider.value = cfg.get_value("audio", "sfx")
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_slider.value)
