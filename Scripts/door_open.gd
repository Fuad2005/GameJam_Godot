extends StaticBody2D

# Safety tracker to prevent the dialogue from instantly re-firing
var dialogue_active: bool = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func hit_by_blade() -> void:
	# 1. Lock the door script from firing this function again
	dialogue_active = true
	Global.is_talking = true
	
	# 2. Connect the end signal cleanly
	if not Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.connect(_on_dialogue_finished)
	
	# 3. Start the dialogue
	Dialogic.start("escape_dialog")
	Global.current_mission = 5


func _on_dialogue_finished() -> void:
	if Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_dialogue_finished)
		
	Global.is_talking = false
	
	# 4. Wait a tiny fraction of a second before letting the door be hit again.
	# This gives the player enough time to finish their attack animation and 
	# lets the BladeHitbox clear out of the area!
	await get_tree().create_timer(0.5).timeout
	dialogue_active = false


# --- Trigger Handling ---
func _on_blade_trigger_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	# Only hit the door if the blade enters AND we aren't already handling a dialogue
	if area.name == "BladeHitbox" and not dialogue_active and not Global.is_talking:
		hit_by_blade()
