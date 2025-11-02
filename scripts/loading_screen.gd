extends Control

var next_scene : String = "res://scenes/main.tscn"
@onready var progress_bar = $ProgressBar
var last_progress : float = 0.0


func _ready():
	ResourceLoader.load_threaded_request(next_scene, "")


func _process(delta):
	var progress = []
	var load_status = ResourceLoader.load_threaded_get_status(next_scene, progress)
	var progress_number = progress[0] * 100.0
	
	if progress_number > last_progress:
		last_progress = progress_number
	
	progress_bar.value = lerp(progress_bar.value, last_progress, delta * 2)
	
	if load_status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
		progress_bar.value = 100.0
		var packed_next_scene = ResourceLoader.load_threaded_get(next_scene)
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_packed(packed_next_scene)
