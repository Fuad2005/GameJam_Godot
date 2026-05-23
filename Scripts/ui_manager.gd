extends Control

@export_group("Stress Bar Setup")
@export var stress_bar: TextureRect
@export var stress_textures: Array[Texture2D]

@export_group("Health Bar Setup")
@export var health_container: HBoxContainer
@export var full_heart: Texture2D
@export var empty_heart: Texture2D

@onready var countdown_label: Label = $CountdownLabel
@onready var coin_count: Label = $CoinCount
# New node reference for the boss's health display text
@onready var enemy_health_label: Label = $EnemyHealthLabel

func _ready() -> void:
	countdown_label.hide()
	
	# Hide the boss health meter initially so it doesn't show up during exploration
	if enemy_health_label:
		enemy_health_label.hide()
	
	# Initial sync right when the game loads for all UI elements
	update_health()
	update_stress()
	update_coins()


func start_fight_countdown() -> void:
	countdown_label.show()
	
	countdown_label.text = "3"
	await get_tree().create_timer(1.0).timeout
	
	countdown_label.text = "2"
	await get_tree().create_timer(1.0).timeout
	
	countdown_label.text = "1"
	await get_tree().create_timer(1.0).timeout
	
	countdown_label.text = "FIGHT!"
	Global.is_talking = false 
	
	# Reveal the boss health bar right as the action starts!
	show_boss_health()
	
	await get_tree().create_timer(1.0).timeout
	countdown_label.hide()


# --- STRESS LOGIC ---
func update_stress() -> void:
	if not stress_bar or stress_textures.is_empty():
		return
		
	var index: int = int(Global.panic / 10)
	index = clampi(index, 0, stress_textures.size() - 1)
	stress_bar.texture = stress_textures[index]


# --- HEALTH LOGIC ---
func update_health() -> void:
	if not health_container:
		return
		
	var hearts = health_container.get_children()
	
	for i in range(hearts.size()):
		if i < Global.hp:
			hearts[i].texture = full_heart
		else:
			hearts[i].texture = empty_heart


# --- COIN LOGIC ---
func update_coins() -> void:
	if not coin_count:
		return
		
	coin_count.text = ": " + str(Global.coins)


# --- BOSS HEALTH LOGIC ---

# Call this to reveal the label and set the initial text values
func show_boss_health() -> void:
	if not enemy_health_label:
		return
	
	update_enemy_health() # Sync text values first
	enemy_health_label.show() # Reveal it on screen

# Call this from your player or sword scripts whenever the boss takes a hit!
func update_enemy_health() -> void:
	if not enemy_health_label:
		return
		
	enemy_health_label.text = "Enemy Health: " + str(Global.enemyHP)
