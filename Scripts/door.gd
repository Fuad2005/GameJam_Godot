extends StaticBody2D


var is_open: bool = false
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision = $CollisionShape2D
@export var door_open: Texture
@export var door_closed: Texture
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func hit_by_blade():
	if is_open:
		return
	is_open = true
	sprite.texture = door_open
	collision.disabled = true
	


func _on_blade_trigger_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area.name == "BladeHitbox": 
		hit_by_blade()
