extends StaticBody2D

var is_open: bool = false
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision1: CollisionShape2D = $CollisionShape2D
@onready var collision2: CollisionShape2D = $BladeTrigger/CollisionShape2D
@export var door_open: Texture
@export var door_closed: Texture

func _ready() -> void:
	sprite.texture = door_closed

func hit_by_blade():
	if is_open:
		return
	if Global.key:  # Only open if player has the key
		is_open = true
		sprite.texture = door_open
		Global.key = false
		
		# Replace direct assignment with set_deferred
		collision1.set_deferred("disabled", true)
		collision2.set_deferred("disabled", true)
		
		print("Door opened!")
	else:
		print("You need a key!")

func _on_blade_trigger_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area.name == "BladeHitbox":
		hit_by_blade()
