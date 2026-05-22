extends Control

@export_group("Stress Bar Setup")
@export var stress_bar: TextureRect
@export var stress_textures: Array[Texture2D]

@export_group("Health Bar Setup")
@export var health_container: HBoxContainer
@export var full_heart: Texture2D
@export var empty_heart: Texture2D

@onready var countdown_label: Label = $CountdownLabel

func _ready() -> void:
	countdown_label.hide()
	
	# Initial sync right when the game loads
	update_health()
	update_stress()


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
	
	await get_tree().create_timer(1.0).timeout
	countdown_label.hide()


# --- STRESS LOGIC ---
func update_stress() -> void:
	if not stress_bar or stress_textures.is_empty():
		return
		
	# 1. Convert the 0-100 range to a 0-9 index by dividing by 10.
	# Example: Panic 45 / 10 = 4.5. Storing it as an int automatically drops the decimal to 4.
	var index: int = int(Global.panic / 10)
	
	# 2. Use clampi() as a safety net so the index never goes below 0 
	# or higher than your maximum array size (index 9 for 10 textures).
	index = clampi(index, 0, stress_textures.size() - 1)
	
	# 3. Swap the image texture to match the mapped range
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
