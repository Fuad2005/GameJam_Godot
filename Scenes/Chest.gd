extends StaticBody2D

@export var coin_reward: int = 10
@export var chest_closed: Texture
@export var chest_open: Texture

var is_open: bool = false
@onready var sprite: Sprite2D = $Sprite2D
@onready var sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready():
	sprite.texture = chest_closed
	add_to_group("Chests")

# Call this from BladeTrigger
func hit_by_blade():
	if is_open:
		return
	is_open = true
	sprite.texture = chest_open
	
	# 1. Wait for exactly half a second (0.2 seconds)
	await get_tree().create_timer(0.2).timeout
	
	# 2. Play the coin sound after the delay
	sound.play()
	
	# 1. Add the coins to the global variable
	Global.coins += coin_reward
	print("Chest opened! Coins now: ", Global.coins)
	
	# 2. Find the UIManager and tell it to refresh the coin label display
	# Make sure this path exactly matches where your UIManager lives in your scene tree!
	var ui = get_node_or_null("/root/Game/CanvasLayer/UIManager")
	if ui:
		ui.update_coins()


func _on_blade_trigger_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:

	if area.name == "BladeHitbox": 
		hit_by_blade()
