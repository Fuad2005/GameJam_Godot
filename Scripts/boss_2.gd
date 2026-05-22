extends CharacterBody2D

# --- Exported variables ---
@export var speed: float = 60.0
@export var hp: int = 7

@export var single_attack_damage: int = 1
@export var triple_attack_damage: int = 2

@export var min_state_time: float = 0.5
@export var max_state_time: float = 2.0

@export var single_attack_cooldown: float = 4.0
@export var triple_attack_cooldown: float = 7.0

@export var attack_range: float = 200.0
@export var first_attack_delay: float = 1.0
@export var second_attack_delay: float = 2.0
@export var consecutive_hits: int = 3
@export var consecutive_delay: float = 0.5

# --- Nodes ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_timer: Timer = $StateTimer

# --- States ---
enum NPCState { IDLE, WALK_LEFT, WALK_RIGHT, WALK_UP, WALK_DOWN }
var current_state: NPCState = NPCState.IDLE

# New Mode Layouts
enum BossMode { STANDING, FIGHT }
var current_mode: BossMode = BossMode.STANDING

# Attack / cooldown / tracking variables
var talked_to: bool = false
var is_fighting: bool = false
var can_attack: bool = true
var is_in_cooldown: bool = false
var player: Node2D = null
var arena_center: Vector2 = Vector2(-3076, -1492)

func _ready() -> void:
	state_timer.timeout.connect(_on_state_timer_timeout)
	_pick_random_walk_state()
	
	# Fallback safe lookups for the player object
	player = get_parent().get_node_or_null("Player")
	if not player:
		player = get_tree().get_root().get_node_or_null("Root/Player")

func _physics_process(delta: float) -> void:
	if hp <= 0:
		velocity = Vector2.ZERO
		return

	# 1. Dialogue Lock
	if Global.is_talking:
		velocity = Vector2.ZERO
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		else:
			animated_sprite.stop()
		move_and_slide()
		return

	# 2. Prevent attacking or normal patrolling until fight mode is active
	if current_mode == BossMode.STANDING:
		velocity = Vector2.ZERO
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		else:
			animated_sprite.stop()
		move_and_slide()
		return

	# 3. Patrol / walking behavior (Runs only when current_mode == BossMode.FIGHT)
	if current_state != null:
		match current_state:
			NPCState.IDLE:
				velocity = Vector2.ZERO
				if animated_sprite.sprite_frames.has_animation("idle"):
					animated_sprite.play("idle")
				else:
					animated_sprite.stop()
			NPCState.WALK_LEFT:
				velocity = Vector2(-speed, 0)
				animated_sprite.flip_h = true
				if animated_sprite.sprite_frames.has_animation("right"):
					animated_sprite.play("right")
			NPCState.WALK_RIGHT:
				velocity = Vector2(speed, 0)
				animated_sprite.flip_h = false
				if animated_sprite.sprite_frames.has_animation("right"):
					animated_sprite.play("right")
			NPCState.WALK_UP:
				velocity = Vector2(0, -speed)
				if animated_sprite.sprite_frames.has_animation("up"):
					animated_sprite.play("up")
			NPCState.WALK_DOWN:
				velocity = Vector2(0, speed)
				if animated_sprite.sprite_frames.has_animation("down"):
					animated_sprite.play("down")
	move_and_slide()

	# 4. Check if we can attack (Runs only in fight mode)
	if player != null and can_attack and not is_in_cooldown:
		var dist = global_position.distance_to(player.global_position)
		if dist <= attack_range:
			can_attack = false
			if randi() % 2 == 0:
				_start_single_attack()
			else:
				_start_triple_attack()

# --- Patrol logic ---
func _pick_random_walk_state() -> void:
	var allowed_states: Array[NPCState] = []

	match current_state:
		NPCState.IDLE:
			allowed_states = [NPCState.WALK_LEFT, NPCState.WALK_RIGHT, NPCState.WALK_UP, NPCState.WALK_DOWN]
		NPCState.WALK_LEFT:
			allowed_states = [NPCState.IDLE, NPCState.WALK_RIGHT, NPCState.WALK_UP, NPCState.WALK_DOWN]
		NPCState.WALK_RIGHT:
			allowed_states = [NPCState.IDLE, NPCState.WALK_LEFT, NPCState.WALK_UP, NPCState.WALK_DOWN]
		NPCState.WALK_UP:
			allowed_states = [NPCState.IDLE, NPCState.WALK_LEFT, NPCState.WALK_RIGHT, NPCState.WALK_DOWN]
		NPCState.WALK_DOWN:
			allowed_states = [NPCState.IDLE, NPCState.WALK_LEFT, NPCState.WALK_RIGHT, NPCState.WALK_UP]

	current_state = allowed_states[randi() % allowed_states.size()]
	state_timer.start(randf_range(min_state_time, max_state_time))

func _on_state_timer_timeout() -> void:
	# Only cycle state selections if actively fighting
	if current_mode == BossMode.FIGHT and hp > 0 and not Global.is_talking:
		_pick_random_walk_state()
	else:
		state_timer.start(randf_range(min_state_time, max_state_time))

# --- Attacks ---
func _start_single_attack() -> void:
	await get_tree().create_timer(first_attack_delay).timeout
	if hp <= 0 or Global.is_talking: return
	animated_sprite.play("attack")
	await animated_sprite.animation_finished
	_apply_damage(single_attack_damage)
	_start_cooldown(single_attack_cooldown)

func _start_triple_attack() -> void:
	await get_tree().create_timer(second_attack_delay).timeout
	for i in range(consecutive_hits):
		if hp <= 0 or Global.is_talking: return
		animated_sprite.play("attack")
		await animated_sprite.animation_finished
		_apply_damage(triple_attack_damage)
		await get_tree().create_timer(consecutive_delay).timeout
	_start_cooldown(triple_attack_cooldown)

func _start_cooldown(time: float) -> void:
	is_in_cooldown = true
	can_attack = true
	var t = get_tree().create_timer(time)
	t.timeout.connect(func() -> void: is_in_cooldown = false)

# --- Damage application ---
func _apply_damage(amount: int) -> void:
	if player != null and player.has_method("take_damage"):
		player.take_damage(amount)

# --- Take damage ---
func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		hp = 0
		velocity = Vector2.ZERO
		can_attack = false
		is_in_cooldown = false
		animated_sprite.play("death")

# --- Trigger Area Detection ---
func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body.name == 'Player' and not talked_to:
		talked_to = true
		Global.is_talking = true
		current_state = NPCState.IDLE
		
		Dialogic.Choices.choice_selected.connect(_on_dialogic_choice_selected)
		Dialogic.timeline_ended.connect(_on_dialogue_finished)
		Dialogic.start("boss2_dialog") # Swap out if using a different timeline resource name

func _on_dialogic_choice_selected(info: Dictionary) -> void:
	if info.text == "Fight!":
		is_fighting = true

# --- Dialogue Sequence Transitions ---
func _on_dialogue_finished() -> void:
	if Dialogic.Choices.choice_selected.is_connected(_on_dialogic_choice_selected):
		Dialogic.Choices.choice_selected.disconnect(_on_dialogic_choice_selected)
	if Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_dialogue_finished)

	if is_fighting:
		arena_center = Vector2(-3076, -1492)
		
		# 1. Teleport Player
		if player:
			player.global_position = arena_center
		
		# 2. Teleport Boss slightly offset to the right
		global_position = arena_center + Vector2(150, 0)
		current_mode = BossMode.FIGHT
		_pick_random_walk_state()
		
		# 3. Call UIManager visual display countdown
		var ui_manager = get_parent().get_node_or_null("CanvasLayer/UIManager")
		if ui_manager:
			ui_manager.start_fight_countdown()
	else:
		# Return to standstill setup if peaceful options selected
		Global.is_talking = false
		current_mode = BossMode.STANDING
		current_state = NPCState.IDLE
