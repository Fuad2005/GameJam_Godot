extends CharacterBody2D

# --- Exported variables ---
@export var speed: float = 60.0
@export var combat_speed: float = 110.0   # Fast movement speed when tracking player

# Melee Balance Settings
@export var single_attack_damage: int = 1
@export var triple_attack_damage: int = 2

@export var single_attack_cooldown: float = 1.5  # Short delay after a normal hit
@export var triple_attack_cooldown: float = 4.5  # Much longer delay after a heavy rapid sequence

@export var attack_range: float = 45.0           # Close proximity range for melee strikes
@export var first_attack_delay: float = 0.4      # Short telegraph window before normal hit
@export var second_attack_delay: float = 0.9     # Longer telegraph window before heavy assault
@export var consecutive_hits: int = 3
@export var consecutive_delay: float = 0.25      # Rapid strike delay

# State Layouts
enum BossMode { STANDING, FIGHT, HURT, DEAD }
var current_mode: BossMode = BossMode.STANDING

enum CombatState { CHASING, ATTACKING, COOLDOWN }
var current_combat_state: CombatState = CombatState.CHASING

# Attack / tracking variables
var talked_to: int = 0
var is_fighting: bool = false
var target_player: CharacterBody2D = null
var attack_timer: float = 0.0
var arena_center: Vector2 = Vector2(-3076, -1492)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	current_mode = BossMode.STANDING

func _physics_process(delta: float) -> void:
	# Lock everything if dialog window is active
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

# --- Standing/Idle Loop ---
func _process_standing_behavior(_delta: float) -> void:
	velocity = Vector2.ZERO
	_play_combat_or_normal_idle()

# --- Melee Combat Loop ---
func _process_fight_behavior(delta: float) -> void:
	if not target_player:
		target_player = get_parent().get_node_or_null("Player")
		return

	match current_combat_state:
		CombatState.CHASING:
			var dist = global_position.distance_to(target_player.global_position)
			
			# If player is out of reach, track them down
			if dist > attack_range:
				var dir_to_player = (target_player.global_position - global_position).normalized()
				velocity = dir_to_player * combat_speed
				
				# Determine horizontal vs vertical movement dominance for fluid animations
				if abs(velocity.x) > abs(velocity.y):
					if velocity.x < 0:
						animated_sprite.flip_h = false # Explicitly use your 'left' animation asset
						animated_sprite.play("left")
					else:
						animated_sprite.flip_h = false
						animated_sprite.play("right")
				else:
					animated_sprite.flip_h = false
					if velocity.y < 0:
						animated_sprite.play("up")
					else:
						animated_sprite.play("down")
			else:
				# Target reached! Halt movement and spin up attack routines
				velocity = Vector2.ZERO
				_look_at_node(target_player)
				
				# 50/50 RNG check to choose attack execution
				if randi() % 2 == 0:
					_start_single_attack()
				else:
					_start_triple_attack()

		CombatState.ATTACKING:
			# Keep physical velocity completely halted while slashing away
			velocity = Vector2.ZERO

		CombatState.COOLDOWN:
			velocity = Vector2.ZERO
			_look_at_node(target_player)
			_play_combat_or_normal_idle()
			
			attack_timer -= delta
			if attack_timer <= 0.0:
				current_combat_state = CombatState.CHASING

# --- Attacks Execution Logic ---
func _start_single_attack() -> void:
	current_combat_state = CombatState.ATTACKING
	
	# Telegraph delay wait
	await get_tree().create_timer(first_attack_delay).timeout
	if current_mode == BossMode.DEAD or Global.is_talking: return
	
	animated_sprite.play("attack")
	await animated_sprite.animation_finished
	
	# Check if player is still in melee range when the attack lands
	if global_position.distance_to(target_player.global_position) <= attack_range + 10.0:
		_deal_melee_damage(single_attack_damage)
		
	_start_cooldown_timer(single_attack_cooldown)

func _start_triple_attack() -> void:
	current_combat_state = CombatState.ATTACKING
	
	# Heavy swing telegraph delay wait
	await get_tree().create_timer(second_attack_delay).timeout
	
	for i in range(consecutive_hits):
		if current_mode == BossMode.DEAD or Global.is_talking: return
		
		animated_sprite.play("attack")
		await animated_sprite.animation_finished
		
		# Check range on every hit of the combo
		if global_position.distance_to(target_player.global_position) <= attack_range + 15.0:
			_deal_melee_damage(triple_attack_damage)
			
		# Minor delay window between rapid hits
		await get_tree().create_timer(consecutive_delay).timeout
		
	_start_cooldown_timer(triple_attack_cooldown)

func _start_cooldown_timer(time: float) -> void:
	attack_timer = time
	current_combat_state = CombatState.COOLDOWN

# --- Damage Application Handler ---
func _deal_melee_damage(amount: int) -> void:
	Global.hp -= amount
	print("Player hit by boss melee! Remaining HP: ", Global.hp)
	
	# Direct UI updating logic matching arrow.gd structure
	var ui = get_node_or_null("/root/Game/CanvasLayer/UIManager")
	if ui:
		ui.update_health()

# --- Shared Utility Handlers ---
func _look_at_node(target: Node2D) -> void:
	if target:
		# If target is on the left, check if you have a custom 'left' animation state or just flip horizontal asset
		if (target.global_position.x - global_position.x) < 0:
			if animated_sprite.sprite_frames.has_animation("left"):
				animated_sprite.play("left")
			else:
				animated_sprite.flip_h = true
				animated_sprite.play("right")
		else:
			animated_sprite.flip_h = false
			animated_sprite.play("right")

func _play_combat_or_normal_idle() -> void:
	# Fallback system if battle_idle layout doesn't exist, use down or standard stop routines
	if current_mode == BossMode.FIGHT and animated_sprite.sprite_frames.has_animation("battle_idle"):
		animated_sprite.play("battle_idle")
	elif animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
	elif animated_sprite.sprite_frames.has_animation("down"):
		animated_sprite.play("down")
	else:
		animated_sprite.stop()

# --- Take damage ---
func take_damage() -> void:
	if current_mode == BossMode.HURT or current_mode == BossMode.DEAD:
		return
		
	Global.enemyHP -= 1
	print("Boss 2 took damage! Current HP: ", Global.enemyHP)
	
	var ui_manager = get_parent().get_node_or_null("CanvasLayer/UIManager")
	if ui_manager:
		ui_manager.update_enemy_health()
		
	if Global.enemyHP <= 0:
		_handle_death()
		return
		
	var previous_combat_state = current_combat_state
	current_mode = BossMode.HURT
	
	if animated_sprite.sprite_frames.has_animation("hurt"):
		animated_sprite.play("hurt")
		await animated_sprite.animation_finished
		
	current_mode = BossMode.FIGHT
	current_combat_state = previous_combat_state

func _handle_death() -> void:
	current_mode = BossMode.DEAD
	velocity = Vector2.ZERO
	
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	
	Global.is_talking = false
	is_fighting = false
	
	# Teleport coordinates setup
	if target_player:
		target_player.global_position = Vector2(313, -1479)
	global_position = Vector2(546, -1484)
	
	var ui_manager = get_parent().get_node_or_null("CanvasLayer/UIManager")
	if ui_manager and ui_manager.has_node("EnemyHealthLabel"):
		ui_manager.get_node("EnemyHealthLabel").hide()

# --- Trigger Area Detection ---
func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body.name == 'Player':
		# FIRST INTERACTION
		if talked_to == 0:
			talked_to = 1
			Global.is_talking = true
			
			Dialogic.Choices.choice_selected.connect(_on_dialogic_choice_selected)
			Dialogic.timeline_ended.connect(_on_dialogue_finished)
			Dialogic.start("boss2_dialog")
			Global.current_mission = 2
			
		# RE-ENTRY INTERACTION (Only runs if the first condition was NOT met)
		elif talked_to == 1:
			talked_to = 2
			Global.is_talking = true
			
			Dialogic.Choices.choice_selected.connect(_on_dialogic_choice_selected)
			Dialogic.timeline_ended.connect(_on_dialogue_finished)
			Dialogic.start("boss2_fight_dialog")
			Global.current_mission = 6


func _on_dialogic_choice_selected(info: Dictionary) -> void:
	if info.text == "Fight!":
		is_fighting = true

# --- Dialogue Transitions Layout ---
func _on_dialogue_finished() -> void:
	if Dialogic.Choices.choice_selected.is_connected(_on_dialogic_choice_selected):
		Dialogic.Choices.choice_selected.disconnect(_on_dialogic_choice_selected)
	if Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_dialogue_finished)

	if is_fighting:
		arena_center = Vector2(-3076, -1492)
		
		target_player = get_parent().get_node_or_null("Player")
		if target_player:
			target_player.global_position = arena_center
		
		global_position = arena_center + Vector2(150, 0)
		current_mode = BossMode.FIGHT
		current_combat_state = CombatState.CHASING
		
		var ui_manager = get_parent().get_node_or_null("CanvasLayer/UIManager")
		if ui_manager:
			ui_manager.start_fight_countdown()
			ui_manager.show_boss_health()	
	else:
		Global.is_talking = false
		current_mode = BossMode.STANDING

func _on_hitbox_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area.name == "BladeHitbox":
		take_damage()
