extends Control

const LOADING_SCREEN = preload("res://scenes/loading_screen.tscn")

@onready var click_sfx: AudioStreamPlayer = $ClickSFX
@onready var music_player: AudioStreamPlayer = $MusicPlayer


func _ready():
	if music_player.stream is AudioStream:
		music_player.stream.loop = true

	music_player.finished.connect(_on_music_finished)

	music_player.volume_db = -50
	music_player.play()

	var t := create_tween()
	t.tween_property(music_player, "volume_db", -10, 2.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_start_button_pressed():
	click_sfx.play()

	var t := create_tween()
	t.tween_property(music_player, "volume_db", -50, 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	t.finished.connect(func():
		get_tree().change_scene_to_packed(LOADING_SCREEN)
	)

func _on_options_button_pressed():
	$ClickSFX.play()

	var blur = $BlurOverlay
	var menu = $OptionsMenu

	# Play swoosh opening sound
	$SwooshOpen.play()

	blur.show()
	menu.show()

	blur.modulate.a = 0.0
	menu.modulate.a = 0.0

	var t := create_tween()
	t.tween_property(blur, "modulate:a", 1.0, 0.25)
	t.parallel().tween_property(menu, "modulate:a", 1.0, 0.25)


func _on_exit_button_pressed():
	click_sfx.play()
	get_tree().quit()

func _on_music_finished():
	music_player.play()
