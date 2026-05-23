extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $Area2D

var talked_to: bool = false

# Potion boosts and price
@export var speed_boost: float = 50.0
@export var dash_boost: float = 150.0
@export var dash_duration_boost: float = 0.05
@export var potion_price: int = 20

func _ready() -> void:
	# Connect the area signal to automatically catch when the player walks into range
	interact_area.body_entered.connect(_on_area_body_entered)

func _on_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not talked_to:
		talked_to = true
		Global.is_talking = true

		# Cleanly connect Dialogic's signal and timeline trackers
		Dialogic.signal_event.connect(_on_dialogic_signal)
		Dialogic.timeline_ended.connect(_on_dialogue_finished)
		
		# Open up the shop timeline
		Dialogic.start("merchant_dialogue")

func _on_dialogic_signal(argument: String) -> void:
	# This reads the EXACT "argument" string from your timeline screenshot!
	match argument:
		"buy_speed_potion":
			if Global.coins >= potion_price:
				Global.coins -= potion_price
				Global.speed += speed_boost
				
				var ui = get_node_or_null("/root/Game/CanvasLayer/UIManager")
				if ui:
					ui.update_coins()
				print("Speed potion bought! New speed: ", Global.speed, " Coins left: ", Global.coins)
			else:
				print("Not enough coins for speed potion!")
				
		"buy_dash_potion":
			if Global.coins >= potion_price:
				Global.coins -= potion_price
				
				# Update Global variables directly. 
				Global.dash_speed += dash_boost
				Global.dash_duration += dash_duration_boost
				
				var ui = get_node_or_null("/root/Game/CanvasLayer/UIManager")
				if ui:
					ui.update_coins()
				print("Dash potion bought! New dash speed: ", Global.dash_speed, " Coins left: ", Global.coins)
			else:
				print("Not enough coins for dash potion!")
				
		"run_away":
			print("Player chose to run away.")

func _on_dialogue_finished() -> void:
	# Disconnect the signals so they don't stack up or duplicate next time you talk
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	if Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_dialogue_finished)

	# Free up movement and reset trigger tracking
	Global.is_talking = false
	talked_to = false
	print("Merchant transaction completed. Movement restored.")
