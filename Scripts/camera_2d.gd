extends Camera2D

# We export a NodePath so you can click and assign your Player node in the Inspector
@export var target_node: CharacterBody2D

# This flag decides whether the camera is locked onto the player or free
var is_following: bool = true

func _ready() -> void:
	# Register this camera globally so any script can call it!
	Global.game_camera = self

func _process(delta: float) -> void:
	if is_following and target_node:
		# Directly set the camera's destination to the target's position.
		# Godot's built-in "Position Smoothing" handles the smooth glide automatically!
		global_position = target_node.global_position


func shake_camera(intensity: float, duration: float) -> void:
	var timer = 0.0
	while timer < duration:
		# Shift the structural render offset randomly
		Global.game_camera.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		await get_tree().process_frame
		timer += get_process_delta_time()
	
	# Reset it back to zero safely
	Global.game_camera.offset = Vector2.ZERO
