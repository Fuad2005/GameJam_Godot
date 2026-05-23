extends CharacterBody2D


@export var stab_move_penalty: float = 1  # 0.5 means they move at 50% speed while stabbing

# --- Dash Configuration Settings ---

@export var dash_cooldown: float = 0.5

@onready var animated_sprite = $AnimatedSprite2D
@onready var dash_sound: AudioStreamPlayer2D = $DashSound
@onready var stab_sound: AudioStreamPlayer2D = $StabSound
@onready var blade_hitbox: Area2D = $BladeHitbox # Added blade hitbox reference
@onready var ui_manager = get_node_or_null("/root/Game/CanvasLayer/UIManager")  

# This array acts as our memory buffer for pressed directions
var input_history: Array[Vector2] = []

var boss_health: int = 10

# Tracks the last direction the player moved so we know which idle to play
var last_facing_direction: Vector2 = Vector2.DOWN

# --- State Flags ---
var is_dashing: bool = false
var can_dash: bool = true
var is_stabbing: bool = false
var is_dead: bool = false # New flag to block inputs on death


func _process(delta: float) -> void:
	# If player is already dead, completely stop process updates
	if is_dead:
		return
		
	# Check if health dropped to zero or below from an external hit
	if Global.hp <= 0:
		_handle_player_death()
		return

	# 1. Increment the value cleanly over time using delta
	Global.panic += 0.05
	
	# 2. Use our cached reference.
	if ui_manager:
		ui_manager.update_stress()


func _physics_process(delta: float) -> void:
	# Lock physics and movement completely if dead
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if Global.is_talking:
		input_history.clear() # Wipe the buffer so they don't "remember" keys held down
		velocity = Vector2.ZERO # Instantly kill any sliding momentum
		_play_idle_animation(last_facing_direction) # Force the correct static idle frame
		move_and_slide()
		return # Stop execution here so no actions or movements can run
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
			velocity = current_direction * (Global.speed * stab_move_penalty)
		else:
			velocity = current_direction * Global.speed
			last_facing_direction = current_direction
			_update_sprite_direction(current_direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, Global.speed)
		if not is_stabbing:
			_play_idle_animation(last_facing_direction)

	move_and_slide()


func _handle_input_buffer() -> void:
	if Global.is_talking or is_dead:
		return
		
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


# --- Death Sequence (Inside Player CharacterBody2D) ---
func _handle_player_death() -> void:
	is_dead = true
	Global.hp = 0 # Safety floor stop
	velocity = Vector2.ZERO
	input_history.clear()
	
	# Turn off weapon hitboxes so player can't hurt things post-mortem
	if blade_hitbox:
		blade_hitbox.get_node("CollisionShape2D").disabled = true
		
	print("Player has died!")
	
	# Play Death Animation
	if animated_sprite.sprite_frames.has_animation("Death"):
		animated_sprite.play("Death")
		await animated_sprite.animation_finished
	else:
		# Fallback if animation name is lowercase or missing
		animated_sprite.stop()
		await get_tree().create_timer(1.5).timeout 
		
	# --- SHOW LOSE SCREEN MENU AND FREEZE GAME ---
	# Looks for LoseMenu inside CanvasLayer relative to your root scene structure
	var lose_menu = get_node_or_null("/root/Game/CanvasLayer/LoseMenu")
	if lose_menu:
		lose_menu.visible = true
		get_tree().paused = true # Freezes enemies, physics, and projectiles cleanly!
	else:
		print("Error: Could not find LoseMenu at /root/Game/CanvasLayer/LoseMenu")
		


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
	if is_dead: return
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
	
	for i in range(Global.dash_multiplier):
		velocity = dash_direction * Global.dash_speed
		_update_sprite_direction(dash_direction)
		await get_tree().create_timer(Global.dash_duration).timeout
		velocity = Vector2.ZERO  # stop between dashes if needed

	is_dashing = false
	animated_sprite.speed_scale = 1.0
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true


# --- Walking / idle ---
func _update_sprite_direction(dir: Vector2) -> void:
	if is_dead: return
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
	if is_dead: return
	match dir:
		Vector2.RIGHT:
			animated_sprite.play("Idle_Right")
		Vector2.LEFT:
			animated_sprite.play("Idle_Left")
		Vector2.DOWN:
			animated_sprite.play("Idle_Down")
		Vector2.UP:
			animated_sprite.play("Idle_Up")


func _on_hit_check_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	print(area.name)
