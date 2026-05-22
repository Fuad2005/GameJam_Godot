extends CharacterBody2D

@export var speed: float = 60.0

# Time ranges for randomness (in seconds)
@export var min_state_time: float = 0.5
@export var max_state_time: float = 2.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_timer: Timer = $StateTimer

# Define our NPC state options
enum NPCState { IDLE, WALK_LEFT, WALK_RIGHT }
var current_state: NPCState = NPCState.IDLE

func _ready() -> void:
	# Connect the timer's timeout signal to our state changer function
	state_timer.timeout.connect(_on_state_timer_timeout)
	
	# Pick our very first random action to kick off the loop
	_pick_random_state()


func _physics_process(delta: float) -> void:
	# Decide direction and handle sprite flipping based on state
	match current_state:
		NPCState.IDLE:
			velocity.x = 0.0
			# Check your SpriteFrames name! Change "Idle" if you named it differently
			if animated_sprite.sprite_frames.has_animation("idle"):
				animated_sprite.play("idle")
			else:
				animated_sprite.stop() # Fallback: Pause walk animation if no idle exists
				
		NPCState.WALK_LEFT:
			velocity.x = -speed
			animated_sprite.flip_h = true # Flip horizontally because art faces right
			animated_sprite.play("walking_right") # Reuse right-facing walk animation
			
		NPCState.WALK_RIGHT:
			velocity.x = speed
			animated_sprite.flip_h = false # Face normal direction
			animated_sprite.play("walking_right")

	# Move the NPC and handle collisions automatically
	move_and_slide()


func _pick_random_state() -> void:
	# Build a pool of allowed next states based on what we are currently doing
	var allowed_states: Array[NPCState] = []
	
	match current_state:
		NPCState.WALK_LEFT:
			# If we were walking left, we can only stop or go right
			allowed_states = [NPCState.IDLE, NPCState.WALK_RIGHT]
			
		NPCState.WALK_RIGHT:
			# If we were walking right, we can only stop or go left
			allowed_states = [NPCState.IDLE, NPCState.WALK_LEFT]
			
		NPCState.IDLE:
			# If we were standing still, we are free to move in either direction
			allowed_states = [NPCState.WALK_LEFT, NPCState.WALK_RIGHT]
	
	# Pick a random state from our safe, filtered array pool
	var random_index = randi() % allowed_states.size()
	current_state = allowed_states[random_index]
	
	# Choose a completely random duration for how long they perform this state
	var random_duration = randf_range(min_state_time, max_state_time)
	
	# Start the timer with our randomized countdown duration
	state_timer.start(random_duration)


func _on_state_timer_timeout() -> void:
	# When the time runs out, pick a fresh action!
	_pick_random_state()
