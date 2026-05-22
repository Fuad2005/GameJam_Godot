extends CharacterBody2D

@export var speed: float = 60.0
@export var patrol_distance: float = 100.0 

# Combat Tweaks
@export var combat_speed: float = 120.0     # How fast it dashes to a new spot
@export var fire_rate: float = 1.2          # Delay between arrows while standing still
@export var arrows_per_turn: int = 3        # How many arrows to shoot before moving

const ARROW_SCENE = preload("res://Scenes/arrow.tscn")

var talked_to: bool = false
var start_x: float = 0.0 

# State Layouts
enum BossMode { STANDING, FIGHT }
var current_mode: BossMode = BossMode.STANDING

enum NPCState { WALK_LEFT, WALK_RIGHT, IDLE }
var current_state: NPCState = NPCState.WALK_RIGHT 

# New Combat Sub-States
enum CombatState { SHOOTING, REPOSITIONING, WAITING }
var current_combat_state: CombatState = CombatState.SHOOTING

# Combat Trackers
var is_fighting: bool = false
var target_player: CharacterBody2D = null
var attack_timer: float = 0.0
var arrows_shot_this_turn: int = 0
var target_reposition_point: Vector2 = Vector2.ZERO
var arena_center: Vector2 = Vector2(-3296, 3008)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	start_x = global_position.x

func _physics_process(delta: float) -> void:
	if Global.is_talking:
		velocity = Vector2.ZERO
		_play_combat_or_normal_idle()
		move_and_slide()
		return

	if current_mode == BossMode.FIGHT:
		_process_fight_behavior(delta)
	else:
		_process_standing_behavior(delta)

	move_and_slide()

# --- Standing/Patrol Loop ---
func _process_standing_behavior(_delta: float) -> void:
	match current_state:
		NPCState.WALK_RIGHT:
			velocity.x = speed
			animated_sprite.flip_h = false
			animated_sprite.play("walking_right")
			if global_position.x >= start_x + patrol_distance:
				current_state = NPCState.WALK_LEFT
		NPCState.WALK_LEFT:
			velocity.x = -speed
			animated_sprite.flip_h = true
			animated_sprite.play("walking_right")
			if global_position.x <= start_x - patrol_distance:
				current_state = NPCState.WALK_RIGHT
		NPCState.IDLE:
			velocity.x = 0.0
			if animated_sprite.sprite_frames.has_animation("idle"):
				animated_sprite.play("idle")
			else:
				animated_sprite.stop()

# --- Dynamic Combat Loop ---
func _process_fight_behavior(delta: float) -> void:
	if not target_player:
		target_player = get_parent().get_node_or_null("Player")
		return

	match current_combat_state:
		CombatState.SHOOTING:
			velocity = Vector2.ZERO
			_look_at_node(target_player)
			_play_combat_or_normal_idle()
			
			attack_timer -= delta
			if attack_timer <= 0.0:
				var dir_to_player = (target_player.global_position - global_position).normalized()
				_shoot_arrow(dir_to_player)
				
				arrows_shot_this_turn += 1
				attack_timer = fire_rate # Reset timer for next arrow shot
				
				# If boss has fired all its shots, prepare to reposition
				if arrows_shot_this_turn >= arrows_per_turn:
					arrows_shot_this_turn = 0
					_choose_new_arena_spot()
					current_combat_state = CombatState.REPOSITIONING

		CombatState.REPOSITIONING:
			var dir_to_spot = (target_reposition_point - global_position).normalized()
			velocity = dir_to_spot * combat_speed
			animated_sprite.flip_h = velocity.x < 0
			
			if animated_sprite.sprite_frames.has_animation("running"):
				animated_sprite.play("running")
			else:
				animated_sprite.play("walking_right")
				
			# Check if we arrived close enough to our target coordinates
			if global_position.distance_to(target_reposition_point) < 15.0:
				velocity = Vector2.ZERO
				attack_timer = 0.5 # Small delay when arriving before firing opens up
				current_combat_state = CombatState.SHOOTING

func _choose_new_arena_spot() -> void:
	# Randomly pick an angle and radius inside your arena bounds relative to the center
	var random_angle = randf_range(0, 2 * PI)
	var random_radius = randf_range(100.0, 300.0) # Keeps the boss moving roughly within a 300px ring
	
	target_reposition_point = arena_center + Vector2(cos(random_angle), sin(random_angle)) * random_radius

func _look_at_node(target: Node2D) -> void:
	if target:
		animated_sprite.flip_h = (target.global_position.x - global_position.x) < 0

func _play_combat_or_normal_idle() -> void:
	if current_mode == BossMode.FIGHT and animated_sprite.sprite_frames.has_animation("battle_idle"):
		animated_sprite.play("battle_idle")
	elif animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
	else:
		animated_sprite.stop()
		
func _shoot_arrow(dir: Vector2) -> void:
	var arrow_instance = ARROW_SCENE.instantiate()
	
	# Spawn offset: push the arrow 30 pixels out in the direction it's firing
	# This keeps it clear of the boss's immediate collision hull
	var spawn_offset = dir * 30.0
	arrow_instance.global_position = global_position + spawn_offset
	
	get_parent().add_child(arrow_instance)
	
	if arrow_instance.has_method("launch"):
		arrow_instance.launch(dir)

# --- Trigger Area Detection ---
func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body.name == 'Player' and not talked_to:
		talked_to = true
		Global.is_talking = true
		current_state = NPCState.IDLE
		
		Dialogic.Choices.choice_selected.connect(_on_dialogic_choice_selected)
		Dialogic.timeline_ended.connect(_on_dialogue_finished)
		Dialogic.start("boss1_dialog")

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
		# Define arena focus center
		arena_center = Vector2(-3296, 3008)
		
		# 1. Teleport Player
		var player = get_parent().get_node_or_null("Player")
		if player:
			player.global_position = arena_center
		
		# 2. Teleport Boss slightly to the side and start shooting sequence
		global_position = arena_center + Vector2(150, 0)
		current_mode = BossMode.FIGHT
		current_combat_state = CombatState.SHOOTING
		attack_timer = 3.5 # Syncs up with the UIManager 3-second visual countdown
		
		# 3. Call UIManager to display announcement counter
		var ui_manager = get_parent().get_node_or_null("CanvasLayer/UIManager")
		if ui_manager:
			ui_manager.start_fight_countdown()
	else:
		Global.is_talking = false
		if global_position.x > start_x:
			current_state = NPCState.WALK_LEFT
		else:
			current_state = NPCState.WALK_RIGHT
