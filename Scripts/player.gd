extends CharacterBody2D

@export var stab_move_penalty: float = 1.0  # 0.5 means move at 50% speed while stabbing
@export var dash_cooldown: float = 0.5

@onready var animated_sprite = $AnimatedSprite2D
@onready var dash_sound: AudioStreamPlayer2D = $DashSound
@onready var stab_sound: AudioStreamPlayer2D = $StabSound
@onready var blade_hitbox: Area2D = $BladeHitbox 
@onready var step_sound: AudioStreamPlayer2D = $StepSound
@onready var ui_manager = get_node_or_null("/root/Game/CanvasLayer/UIManager")  

var input_history: Array[Vector2] = []
var boss_health: int = 10
var last_facing_direction: Vector2 = Vector2.DOWN

# --- State Flags ---
var is_dashing: bool = false
var is_in_panic: bool = false
var can_dash: bool = true
var is_stabbing: bool = false
var is_dead: bool = false 


func _process(delta: float) -> void:
	if is_dead: return
		
	if Global.hp <= 0:
		_handle_player_death()
		return

	Global.panic += Global.panic_change
	
	if not is_in_panic and Global.panic > 0.1:
		Global.panic_change = -0.05
	elif not is_in_panic and Global.panic <= 0:
		Global.panic = 0
	
	if ui_manager:
		ui_manager.update_stress()


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if Global.is_talking:
		# Reset combat states safely so you don't break when dialogue starts
		if is_stabbing:
			is_stabbing = false
			if blade_hitbox and blade_hitbox.has_node("CollisionShape2D"):
				blade_hitbox.get_node("CollisionShape2D").disabled = true
		if is_dashing:
			is_dashing = false
			animated_sprite.speed_scale = 1.0

		input_history.clear() 
		velocity = Vector2.ZERO 
		_play_idle_animation(last_facing_direction) 
		move_and_slide()
		return 

	_handle_input_buffer()

	# --- 1. HANDLE ATTACK & DASH INPUTS ---
	if not is_dashing:
		if Input.is_action_just_pressed("stab") and not is_stabbing:
			_start_stab()
		elif Input.is_action_just_pressed("dash") and can_dash and not is_stabbing:
			_start_dash()

	if is_dashing:
		move_and_slide()
		return

# --- 2. HANDLE MOVEMENT & RUNNING/IDLE ANIMATIONS ---
	if not input_history.is_empty():
		var current_direction: Vector2 = input_history.back()
		last_facing_direction = current_direction
		
		if is_stabbing:
			# Move with penalty, but DO NOT change the animation (let the stab finish!)
			velocity = current_direction * (Global.speed * stab_move_penalty)
			# Stop steps if they are stabbing mid-walk (optional flavor adjustment)
			if step_sound.playing:
				step_sound.stop()
		else:
			# Normal movement and normal walking animations
			velocity = current_direction * Global.speed
			_update_sprite_direction(current_direction)
			
			# --- PLAY FOOTSTEPS HERE ---
			# Play the sound loop only if it's not already playing
			if not step_sound.playing:
				step_sound.play()
	else:
		# Decelerate to a stop
		velocity = velocity.move_toward(Vector2.ZERO, Global.speed)
		if not is_stabbing:
			_play_idle_animation(last_facing_direction)
		
		# --- STOP FOOTSTEPS WHEN IDLE ---
		if step_sound.playing:
			step_sound.stop()

	move_and_slide()


func _handle_input_buffer() -> void:
	if Global.is_talking or is_dead: return
		
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


# --- Death Sequence ---
func _handle_player_death() -> void:
	is_dead = true
	Global.hp = 0 
	velocity = Vector2.ZERO
	input_history.clear()
	
	if blade_hitbox:
		blade_hitbox.get_node("CollisionShape2D").disabled = true
		
	print("Player has died!")
	
	if animated_sprite.sprite_frames.has_animation("Death"):
		animated_sprite.play("Death")
		await animated_sprite.animation_finished
	else:
		animated_sprite.stop()
		await get_tree().create_timer(1.5).timeout 
		
	var lose_menu = get_node_or_null("/root/Game/CanvasLayer/LoseMenu")
	if lose_menu:
		lose_menu.visible = true
		get_tree().paused = true 


# --- Stab Logic ---
func _start_stab() -> void:
	is_stabbing = true
	stab_sound.play()
	
	if blade_hitbox and blade_hitbox.has_node("CollisionShape2D"):
		blade_hitbox.get_node("CollisionShape2D").disabled = false

	var attack_direction: Vector2 = last_facing_direction
	if not input_history.is_empty():
		attack_direction = input_history.back()
	
	match attack_direction:
		Vector2.RIGHT: animated_sprite.play("Stab_Right")
		Vector2.LEFT:  animated_sprite.play("Stab_Left")
		Vector2.DOWN:  animated_sprite.play("Stab_Down")
		Vector2.UP:    animated_sprite.play("Stab_Up")
	
	if animated_sprite.animation_finished.is_connected(_on_stab_animation_finished):
		animated_sprite.animation_finished.disconnect(_on_stab_animation_finished)
	animated_sprite.animation_finished.connect(_on_stab_animation_finished, CONNECT_ONE_SHOT)


func _on_stab_animation_finished() -> void:
	if is_dead: return
	is_stabbing = false
	
	if blade_hitbox and blade_hitbox.has_node("CollisionShape2D"):
		blade_hitbox.get_node("CollisionShape2D").disabled = true

	# Check immediately if we are holding a direction when the stab ends
	if not input_history.is_empty():
		_update_sprite_direction(input_history.back())
	else:
		_play_idle_animation(last_facing_direction)


# --- Dash Logic ---
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
		velocity = Vector2.ZERO  

	is_dashing = false
	animated_sprite.speed_scale = 1.0
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true


# --- Animation Mapping ---
func _update_sprite_direction(dir: Vector2) -> void:
	if is_dead or is_stabbing: return # Don't overwrite stabs with walking frames!
	match dir:
		Vector2.RIGHT: animated_sprite.play("Walking_Right")
		Vector2.LEFT:  animated_sprite.play("Walking_Left")
		Vector2.DOWN:  animated_sprite.play("Walking_Down")
		Vector2.UP:    animated_sprite.play("Walking_Up")

func _play_idle_animation(dir: Vector2) -> void:
	if is_dead or is_stabbing: return
	match dir:
		Vector2.RIGHT: animated_sprite.play("Idle_Right")
		Vector2.LEFT:  animated_sprite.play("Idle_Left")
		Vector2.DOWN:  animated_sprite.play("Idle_Down")
		Vector2.UP:    animated_sprite.play("Idle_Up")


func _on_hit_check_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area and is_instance_valid(area):
		if area.name == "PanicZone":
			is_in_panic = true
			Global.panic_change = 0.05


func _on_hit_check_area_shape_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area and is_instance_valid(area):
		if area.name == "PanicZone":
			is_in_panic = false
	else:
		is_in_panic = false


func _on_mom_dad_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Dialogic.start("mom-dad")
