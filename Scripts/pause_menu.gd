extends Control
 
const HOME_SCENE_PATH := "res://Scenes/main_menu.tscn"  # Change to your main menu path
 
func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
 
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()
 
func toggle_pause() -> void:
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused
 
func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false
 
func _on_home_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(HOME_SCENE_PATH)
