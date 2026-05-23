extends Area2D

@export var key_name: String = "GoldKey"

func _ready():
	add_to_group("Keys")

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		Global.key = true   # set the global key boolean
		Global.current_mission = 3
		queue_free()        # remove the key from the scene
		print("Picked up key!")
