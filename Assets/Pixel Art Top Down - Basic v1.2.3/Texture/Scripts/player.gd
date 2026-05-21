extends CharacterBody2D

@export var speed: float = 200.0

@onready var animated_sprite = $AnimatedSprite2D

# This array acts as our memory buffer for pressed directions
var input_history: Array[Vector2] = []

# Tracks the last direction the player moved so we know which idle to play
var last_facing_direction: Vector2 = Vector2.DOWN # Default to facing down

func _physics_process(delta: float) -> void:
	# 1. Update our input history buffer
	_handle_input_buffer()

	# 2. Pick the latest direction from the back of the array
	if not input_history.is_empty():
		var current_direction: Vector2 = input_history.back()
		velocity = current_direction * speed
		
		# Update our memory of where the player is looking
		last_facing_direction = current_direction
		
		_update_sprite_direction(current_direction)
	else:
		# No buttons are being held down, bring the player to a halt
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		
		# 4. Play the directional idle animation when stopped
		_play_idle_animation(last_facing_direction)

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


# Handles playing your 4-way walking animations
func _update_sprite_direction(dir: Vector2) -> void:
	match dir:
		Vector2.RIGHT:
			animated_sprite.play("Walking_Right")
		Vector2.LEFT:
			animated_sprite.play("Walking_Left")
		Vector2.DOWN:
			animated_sprite.play("Walking_Down")
		Vector2.UP:
			animated_sprite.play("Walking_Up")


# New helper function to match the idle frame to your last known direction
func _play_idle_animation(dir: Vector2) -> void:
	match dir:
		Vector2.RIGHT:
			animated_sprite.play("Idle_Right")
		Vector2.LEFT:
			animated_sprite.play("Idle_Left")
		Vector2.DOWN:
			animated_sprite.play("Idle_Down")
		Vector2.UP:
			animated_sprite.play("Idle_Up")
