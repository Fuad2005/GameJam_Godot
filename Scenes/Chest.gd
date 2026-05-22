extends StaticBody2D

@export var coin_reward: int = 10
@export var chest_closed: Texture
@export var chest_open: Texture

var is_open: bool = false
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	sprite.texture = chest_closed
	add_to_group("Chests")

# Call this from BladeTrigger
func hit_by_blade():
	if is_open:
		return
	is_open = true
	sprite.texture = chest_open
	Global.coins += coin_reward
	print("Chest opened! Coins now: ", Global.coins)




func _on_blade_trigger_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void: # Replace with function body.
	print("JSlfiJASDlkfjsDJFSKDJF")

	if area.name == "BladeHitbox": 
		hit_by_blade()
