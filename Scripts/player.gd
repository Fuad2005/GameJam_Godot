extends CharacterBody2D

@export var speed: float = 200.0
@export var stab_move_penalty: float = 0.5  # 0.5 means they move at 50% speed while stabbing

# --- Dash Configuration Settings ---
@export var dash_speed: float = 600.0      # How fast the player travels during the dash
@export var dash_duration: float = 0.1     # How long the dash lasts (in seconds)
@export var dash_cooldown: float = 0.5     # Time the player must wait before dashing again

@onready var animated_sprite = $AnimatedSprite2D
@onready var dash_sound: AudioStreamPlayer2D = $DashSound
@onready var stab_sound: AudioStreamPlayer2D = $StabSound


# This array acts as our memory buffer for pressed directions
var input_history: Array[Vector2] = []

# Tracks the last direction the player moved so we know which idle to play
var last_facing_direction: Vector2 = Vector2.DOWN # Default to facing down

# --- State Flags ---
var is_dashing: bool = false
var can_dash: bool = true
var is_stabbing: bool = false # Tracks if we are currently attacking

func _physics_process(delta: float) -> void:
	# 1. ALWAYS update our input history buffer so it stays accurate
	_handle_input_buffer()

	# --- Check for Action Triggers ---
	# We allow stabbing to cancel out of a normal walk, but not during a dash
	if not is_dashing:
		if Input.is_action_just_pressed("stab") and not is_stabbing:
			_start_stab()
		elif Input.is_action_just_pressed("dash") and can_dash and not is_stabbing:
			_start_dash()

	# If currently dashing, handle movement and bypass normal controls
	if is_dashing:
		move_and_slide()
		return

	# --- 2. Movement Logic (Normal vs Stabbing) ---
	if not input_history.is_empty():
		var current_direction: Vector2 = input_history.back()
		
		if is_stabbing:
			# FLUID MOVEMENT: Move in the pressed direction, but apply the speed penalty
			velocity = current_direction * (speed * stab_move_penalty)
		else:
			# Normal full-speed movement
			velocity = current_direction * speed
			last_facing_direction = current_direction
			_update_sprite_direction(current_direction)
	else:
		# No buttons are being held down, bring the player to a halt
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		
		if not is_stabbing:
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


# Handles the stab attack logic
func _start_stab() -> void:
	is_stabbing = true
	stab_sound.play()
	
	# Determine attack direction based on what buttons are pressed or where they are facing
	var attack_direction: Vector2 = last_facing_direction
	if not input_history.is_empty():
		attack_direction = input_history.back()
	
	# Play the appropriate stab animation (Movement code won't overwrite this)
	match attack_direction:
		Vector2.RIGHT:
			animated_sprite.play("Stab_Right")
		Vector2.LEFT:
			animated_sprite.play("Stab_Left")
		Vector2.DOWN:
			animated_sprite.play("Stab_Down")
		Vector2.UP:
			animated_sprite.play("Stab_Up")
			
	# Connect to the built-in signal that fires when an animation finishes.
	animated_sprite.animation_finished.connect(_on_stab_animation_finished, CONNECT_ONE_SHOT)


func _on_stab_animation_finished() -> void:
	is_stabbing = false
	
	# Clean transition check: If they are still holding movement keys when the 
	# attack ends, instantly pop back into the walking animation frames
	if not input_history.is_empty():
		_update_sprite_direction(input_history.back())


# This function handles the burst of speed and animation overdrive
func _start_dash() -> void:
	can_dash = false
	is_dashing = true
	
	dash_sound.play()
	animated_sprite.speed_scale = 2.5
	
	var dash_direction: Vector2 = last_facing_direction
	if not input_history.is_empty():
		dash_direction = input_history.back()
	
	velocity = dash_direction * dash_speed
	_update_sprite_direction(dash_direction)
	
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
	animated_sprite.speed_scale = 1.0
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true


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
