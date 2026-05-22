extends RigidBody2D

@export var speed: float = 400.0

func launch(direction: Vector2) -> void:
	linear_velocity = direction.normalized() * speed
	rotation = atan2(direction.y, direction.x)
	
	# Clear out any built-in physics contact monitoring with the boss
	add_collision_exception_with(get_parent().get_node_or_null("Boss_1"))


# --- 1. DETECTS PLAYERS (Areas) ---
func _on_arrow_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "HitCheck":
		Global.hp -= 1
		
		var ui = get_node_or_null("/root/Game/CanvasLayer/UIManager")
		if ui:
			ui.update_health()
			
		# Delete the arrow because it hit the player
		queue_free()


# --- 2. DETECTS WALLS (Physical Bodies) ---
func _on_arrow_hitbox_body_entered(body: Node2D) -> void:
	# Ignore the boss who shot it just in case
	if body.name == "Boss_1" or "Boss" in body.name:
		return
		
	# Ignore the player body here since your area_entered handles damage
	if body.name == "Player":
		return
		
	# If it hits anything else (Walls, Floor, Obstacles), destroy it!
	print("Arrow hit a wall: ", body.name)
	queue_free()
