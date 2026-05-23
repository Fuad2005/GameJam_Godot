extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $Area2D

var talked_to: bool = false

# Potion boosts and price
@export var speed_boost: float = 50.0
@export var dash_boost: float = 150.0
@export var potion_price: int = 20

func _ready() -> void:
	# Connect the interact area signal
	interact_area.body_entered.connect(_on_area_body_entered)

func _on_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not talked_to:
		talked_to = true
		Global.is_talking = true

		# Start Dialogic dialogue
		Dialogic.start("merchant_dialogue")

		# Connect Dialogic signals
		if not Dialogic.Choices.choice_selected.is_connected(_on_dialogic_choice_selected):
			Dialogic.Choices.choice_selected.connect(_on_dialogic_choice_selected)
		if not Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
			Dialogic.timeline_ended.connect(_on_dialogue_finished)

func _on_dialogic_choice_selected(info: Dictionary) -> void:
	var choice_text = info.get("text", "")
	match choice_text:
		"Buy speed potion":
			if Global.coins >= potion_price:
				Global.coins -= potion_price
				Global.speed += speed_boost
				print("Speed potion bought! New speed:", Global.speed, " Coins left:", Global.coins)
			else:
				print("Not enough coins for speed potion!")
		"Buy dash potion":
			if Global.coins >= potion_price:
				Global.coins -= potion_price
				# Update global dash values
				Global.dash_speed += dash_boost
				Global.dash_multiplier = 2  # allows player to dash twice
				# Update actual player node dash speed
				var player = get_tree().get_root().get_node("root_path_to_player")  # replace with actual path
				if player != null:
					player.dash_speed = Global.dash_speed
				print("Dash potion bought! New dash speed:", Global.dash_speed, " Coins left:", Global.coins)
			else:
				print("Not enough coins for dash potion!")
		"Run away":
			print("Player chose to run away.")

func _on_dialogue_finished() -> void:
	# Disconnect signals to avoid duplicate connections
	if Dialogic.Choices.choice_selected.is_connected(_on_dialogic_choice_selected):
		Dialogic.Choices.choice_selected.disconnect(_on_dialogic_choice_selected)
	if Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_dialogue_finished)

	Global.is_talking = false
	talked_to = false
