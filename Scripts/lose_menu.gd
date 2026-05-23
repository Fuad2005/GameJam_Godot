extends Control


const HOME_SCENE_PATH := "res://Scenes/main_menu.tscn"  # Change to your main menu path
 
func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_restart_pressed() -> void:
	# 1. RESET CORE GAMEPLAY GLOBALS
	Global.hp = 3             
	Global.panic = 0.0
	Global.is_talking = false
	Global.enemyHP = 5
	Global.key = false
	Global.coins = 0 

	# 2. UNPAUSE THE ENGINE
	get_tree().paused = false

	# 3. RELOAD THE ACTIVE LEVEL
	var error_code = get_tree().reload_current_scene()
	
	if error_code != OK:
		print("Warning: Failed to reload the game scene!")


func _on_home_pressed() -> void:
	
	Global.hp = 3             
	Global.panic = 0.0
	Global.is_talking = false
	Global.enemyHP = 5
	Global.key = false
	Global.coins = 0 
	# 1. UNPAUSE THE ENGINE FIRST!
	# This ensures the main menu scene will actually process inputs, animations, and audio.
	get_tree().paused = false
	
	# 2. Safe hide
	visible = false
	
	# 3. Change the scene safely
	get_tree().change_scene_to_file(HOME_SCENE_PATH)
