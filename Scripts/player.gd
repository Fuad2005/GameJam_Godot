extends CharacterBody2D

@export var speed: float = 300.0

# This array acts as our memory buffer for pressed directions
var input_history: Array[Vector2] = []

func _physics_process(delta: float) -> void:
	# 1. Update our input history buffer
	_handle_input_buffer()

	# 2. Pick the latest direction from the back of the array
	if not input_history.is_empty():
		var current_direction: Vector2 = input_history.back()
		velocity = current_direction * speed
		
		# Optional: You can use this to update your sprite animations
		_update_sprite_direction(current_direction)
	else:
		# No buttons are being held down, bring the player to a halt
		velocity = velocity.move_toward(Vector2.ZERO, speed)

	# 3. Apply physics and movement
	move_and_slide()


func _handle_input_buffer() -> void:
	# We map our actions to their respective 4-direction vectors
	var actions = {
		"move_left": Vector2.LEFT,
		"move_right": Vector2.RIGHT,
		"move_up": Vector2.UP,
		"move_down": Vector2.DOWN
	}
	
	for action in actions:
		var dir: Vector2 = actions[action]
		
		# Just Pressed: Push it to the back of the queue as the newest action
		if Input.is_action_just_pressed(action):
			if not input_history.has(dir):
				input_history.append(dir)
				
		# Just Released: Erase it from the history completely
		if Input.is_action_just_released(action):
			input_history.erase(dir)


# A helper function to manage your 4-way animations later
func _update_sprite_direction(dir: Vector2) -> void:
	match dir:
		Vector2.RIGHT:
			print("Face Right")
		Vector2.LEFT:
			print("Face Left")
		Vector2.DOWN:
			print("Face Down")
		Vector2.UP:
			print("Face Up")
