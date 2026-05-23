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
@onready var panic_number: Label = $PanicNumber


#----
# ── NEW: Objective nodes ───────────────────────────────────────
#@onready var objective_text: Label = $PanelContainer/MarginContainer/VBoxContainer/ObjectiveText
@onready var objective_text: Label = find_child("ObjectiveText")
# ── Mission text for each stage ───────────────────────────────
#const MISSION_TEXTS: Array[String] = [
	#"",                              # index 0 unused
	#"Find the key",                  # Mission 1
	#"Defeat the boss",               # Mission 2
	#"Escape the dungeon",            # Mission 3
#]
const MISSION_TEXTS := {
	1: {
		"title": "MISSION 1",
		"text": "Talk to the Boss 1"
	},
	2: {
		"title": "MISSION 2",
		"text": "Find the key"
	},
	3: {
		"title": "MISSION 3",
		"text": "Talk to the Boss 2"
	},
	4: {
		"title": "MISSION 4",
		"text": "Escape the dungeon"
	},
	5: {
		"title": "MISSION 5",
		"text": "Come back to the Boss 2"
	},
	6: {
		"title": "MISSION 6",
		"text": "Come back to the Boss 1"
	}
}

var _last_mission: int = -1  # track changes so we don't update every frame
#-----
var _last_displayed_panic: int = -1 # Buffer tracker to monitor integer updates


func _ready() -> void:
	countdown_label.hide()
	
	# Hide the boss health meter initially so it doesn't show up during exploration
	if enemy_health_label:
		enemy_health_label.hide()
	
	# Initial sync right when the game loads for all UI elements
	update_health()
	update_stress()
	update_coins()

func _process(delta: float) -> void:
	# Only refresh when mission actually changed
	if Global.current_mission != _last_mission:
		update_objective()
		
	var current_panic_int := int(round(Global.panic))
	
	# Only rebuild the string and update the UI if the whole number changed!
	if current_panic_int != _last_displayed_panic:
		_last_displayed_panic = current_panic_int
		panic_number.text = str(current_panic_int) + "/100"

# ── NEW: Objective update ──────────────────────────────────────
func update_objective() -> void:
	_last_mission = Global.current_mission
	
	# Clamp safely between 1 and the maximum dictionary key size
	var index: int = clampi(Global.current_mission, 1, MISSION_TEXTS.size())
	
	# Check if the mission exists in our dictionary setup
	if MISSION_TEXTS.has(index):
		var mission_data = MISSION_TEXTS[index]
		
		# Option A: Display just the instruction text (e.g., "Find the key")
		objective_text.text = mission_data["text"]
		
		# Option B: If you want it to show both combined (e.g., "MISSION 1: Find the key"),
		# uncomment the line below and comment out Option A:
		# objective_text.text = mission_data["title"] + ": " + mission_data["text"]
	else:
		objective_text.text = ""
	
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
