extends CharacterBody2D

@export var speed: float = 60.0
@export var patrol_distance: float = 100.0 

# Combat Tweaks
@export var combat_speed: float = 120.0     # How fast it dashes to a new spot
@export var fire_rate: float = 1.2          # Delay between arrows while standing still
@export var arrows_per_turn: int = 3        # How many arrows to shoot before moving

const ARROW_SCENE = preload("res://Scenes/arrow.tscn")

var talked_to: int = 0
var start_x: float = 0.0 

# State Layouts
enum BossMode { STANDING, FIGHT, HURT, DEAD }
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
# NEW COORDINATES SPECIFIED:
var arena_center: Vector2 = Vector2(-2957, 3152)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	start_x = global_position.x

func _physics_process(delta: float) -> void:
	if Global.is_talking:
		velocity = Vector2.ZERO
		_play_combat_or_normal_idle()
		move_and_slide()
		return

	# Lock movement processing completely if hurt or defeated
	if current_mode == BossMode.HURT or current_mode == BossMode.DEAD:
		velocity = Vector2.ZERO
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
	var random_angle = randf_range(0, 2 * PI)
	var random_radius = randf_range(100.0, 300.0)
	
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
	var spawn_offset = dir * 30.0
	arrow_instance.global_position = global_position + spawn_offset
	
	get_parent().add_child(arrow_instance)
	
	if arrow_instance.has_method("launch"):
		arrow_instance.launch(dir)

# --- DAMAGE LOGIC ---
func take_damage() -> void:
	# Ignore hits if already hurt or dead
	if current_mode == BossMode.HURT or current_mode == BossMode.DEAD:
		return
		
	Global.enemyHP -= 1
	print("Boss took damage! Current HP: ", Global.enemyHP)
	
	# Update UIManager health readout text layout
	var ui_manager = get_parent().get_node_or_null("CanvasLayer/UIManager")
	if ui_manager:
		ui_manager.update_enemy_health()
		
	# Check if boss is defeated
	if Global.enemyHP <= 0:
		_handle_death()
		return
		
	# Otherwise, play hurt state processing animation flash
	var previous_state = current_combat_state
	current_mode = BossMode.HURT
	
	if animated_sprite.sprite_frames.has_animation("hurt"):
		animated_sprite.play("hurt")
		await animated_sprite.animation_finished
		
	# Resume fight routines if still standing
	current_mode = BossMode.FIGHT
	current_combat_state = previous_state

func _handle_death() -> void:
	current_mode = BossMode.DEAD
	
	# Turn off the hitboxes right away so the player can't keep hitting the dead body
	# Assuming your Area2D is named "Hitbox" based on your signal name
	var hitbox = get_node_or_null("Hitbox")
	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false
	
	# 1. Play the death animation if it exists
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	
	# 2. Dramatic pause: Wait for 2 seconds after the death animation finishes
	print("Boss defeated! Waiting 2 seconds before teleporting...")
	await get_tree().create_timer(2.0).timeout
	
	# Reset exploration flags and warp out of arena
	Global.is_talking = false
	is_fighting = false
	
	# 3. Teleport Player back to requested safe zone coords
	var player = get_parent().get_node_or_null("Player")
	if player:
		player.global_position = Vector2(890, -336)
		
	# 4. Teleport Boss to its resting coordinates
	global_position = Vector2(963, -444)
	
	# 5. Clean up UI elements layout
	var ui_manager = get_parent().get_node_or_null("CanvasLayer/UIManager")
	if ui_manager and ui_manager.has_node("EnemyHealthLabel"):
		ui_manager.get_node("EnemyHealthLabel").hide()
		
	# Optional: Remove the boss node completely if you don't want it sitting at the resting spot
	# queue_free()
	
	
# --- Trigger Area Detection ---
func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body.name == 'Player':
		# FIRST INTERACTION
		if talked_to == 0:
			talked_to = 1
			Global.is_talking = true
			current_state = NPCState.IDLE
			
			Dialogic.Choices.choice_selected.connect(_on_dialogic_choice_selected)
			Dialogic.timeline_ended.connect(_on_dialogue_finished)
			Dialogic.start("boss1_dialog")
			Global.current_mission = 2
			
		# RE-ENTRY INTERACTION (Only runs if the first condition was NOT met)
		elif talked_to == 1:
			talked_to = 2
			Global.is_talking = true
			current_state = NPCState.IDLE
			
			Dialogic.Choices.choice_selected.connect(_on_dialogic_choice_selected)
			Dialogic.timeline_ended.connect(_on_dialogue_finished)
			Dialogic.start("boss1_fight_dialog")

func _on_dialogic_choice_selected(info: Dictionary) -> void:
	if info.text == "Fight!!!":
		is_fighting = true


# --- Dialogue Sequence Transitions ---
func _on_dialogue_finished() -> void:
	if Dialogic.Choices.choice_selected.is_connected(_on_dialogic_choice_selected):
		Dialogic.Choices.choice_selected.disconnect(_on_dialogic_choice_selected)
	if Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_dialogue_finished)

	if is_fighting:
		# Ensure our dynamic calculations use the updated center position
		arena_center = Vector2(-2957, 3152)
		
		# --- RESET GLOBAL STATS TO DEFAULT COMBAT VALUES ---
		Global.hp = 3
		Global.enemyHP = 5
		Global.panic = 0.0
		
		var player = get_parent().get_node_or_null("Player")
		if player:
			player.global_position = arena_center
			
		global_position = arena_center + Vector2(150, 0)
		current_mode = BossMode.FIGHT
		current_combat_state = CombatState.SHOOTING
		attack_timer = 3.5 
		
		var ui_manager = get_parent().get_node_or_null("CanvasLayer/UIManager")
		if ui_manager:
			# Force a structural layout layout call to match the refreshed values immediately
			ui_manager.update_health()
			ui_manager.update_stress()
			ui_manager.update_enemy_health()
			
			ui_manager.start_fight_countdown()
			ui_manager.show_boss_health()
	else:
		Global.is_talking = false
		if global_position.x > start_x:
			current_state = NPCState.WALK_LEFT
		else:
			current_state = NPCState.WALK_RIGHT

func _on_hitbox_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area.name == "BladeHitbox":
		print(area)
		take_damage() # Triggers damage sequence routine
