extends CharacterBody2D

@export var speed: float = 200.0
@export var stab_move_penalty: float = 0.5  # 0.5 means they move at 50% speed while stabbing

# --- Dash Configuration Settings ---
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.1
@export var dash_cooldown: float = 0.5

@onready var animated_sprite = $AnimatedSprite2D
@onready var dash_sound: AudioStreamPlayer2D = $DashSound
@onready var stab_sound: AudioStreamPlayer2D = $StabSound
@onready var blade_hitbox: Area2D = $BladeHitbox  # Added blade hitbox reference

# This array acts as our memory buffer for pressed directions
var input_history: Array[Vector2] = []

# Tracks the last direction the player moved so we know which idle to play
var last_facing_direction: Vector2 = Vector2.DOWN

# --- State Flags ---
var is_dashing: bool = false
var can_dash: bool = true
var is_stabbing: bool = false

func _physics_process(delta: float) -> void:
	_handle_input_buffer()

	if not is_dashing:
		if Input.is_action_just_pressed("stab") and not is_stabbing:
			_start_stab()
		elif Input.is_action_just_pressed("dash") and can_dash and not is_stabbing:
			_start_dash()

	if is_dashing:
		move_and_slide()
		return

	if not input_history.is_empty():
		var current_direction: Vector2 = input_history.back()
		
		if is_stabbing:
			velocity = current_direction * (speed * stab_move_penalty)
		else:
			velocity = current_direction * speed
			last_facing_direction = current_direction
			_update_sprite_direction(current_direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		if not is_stabbing:
			_play_idle_animation(last_facing_direction)

	move_and_slide()


func _handle_input_buffer() -> void:
	var actions = {
		"move_left": Vector2.LEFT,
		"move_right": Vector2.RIGHT,
		"move_up": Vector2.UP,
		"move_down": Vector2.DOWN
	}
	
	for action in actions:
		var dir: Vector2 = actions[action]
		if Input.is_action_just_pressed(action):
			if not input_history.has(dir):
				input_history.append(dir)
		if Input.is_action_just_released(action):
			input_history.erase(dir)


# --- Stab logic ---
func _start_stab() -> void:
	is_stabbing = true
	stab_sound.play()
	
	blade_hitbox.get_node("CollisionShape2D").disabled = false

	var attack_direction: Vector2 = last_facing_direction
	if not input_history.is_empty():
		attack_direction = input_history.back()
	
	match attack_direction:
		Vector2.RIGHT:
			animated_sprite.play("Stab_Right")
		Vector2.LEFT:
			animated_sprite.play("Stab_Left")
		Vector2.DOWN:
			animated_sprite.play("Stab_Down")
		Vector2.UP:
			animated_sprite.play("Stab_Up")
	
	if animated_sprite.animation_finished.is_connected(_on_stab_animation_finished):
		animated_sprite.animation_finished.disconnect(_on_stab_animation_finished)
	animated_sprite.animation_finished.connect(_on_stab_animation_finished, CONNECT_ONE_SHOT)


func _on_stab_animation_finished() -> void:
	is_stabbing = false
	blade_hitbox.get_node("CollisionShape2D").disabled = true

	if not input_history.is_empty():
		_update_sprite_direction(input_history.back())


# --- Dash ---
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


# --- Walking / idle ---
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


# --- Blade hitbox signal ---
func _on_BladeHitbox_body_entered(body):
	if body.is_in_group("Chests"):
		body.hit_by_blade()
