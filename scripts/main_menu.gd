extends Control

const LOADING_SCREEN = preload("res://scenes/loading_screen.tscn")


func _on_start_button_pressed():
	#var loading_screen = LOADING_SCREEN.instantiate()
	#loading_screen.next_scene = "res://scenes/main.tscn"
	get_tree().change_scene_to_packed(LOADING_SCREEN)


func _on_options_button_pressed():
	pass # Replace with function body.


func _on_exit_button_pressed():
	get_tree().quit()
