extends Control

@onready var background = $Background
@onready var timer = $BackgroundTimer
@onready var button_sound = $BackgroundButton

var bg_images = [
	preload("res://Assets/back1_main.png"),
	preload("res://Assets/back2_main.png"),
	preload("res://Assets/back3_main.png")
]
var current_bg = 0

func _ready():
	background.texture = bg_images[0]
	timer.timeout.connect(_on_background_timer_timeout)

func _on_background_timer_timeout():
	current_bg = (current_bg + 1) % bg_images.size()
	background.texture = bg_images[current_bg]

func _on_play_button_pressed():
	button_sound.play()
	await button_sound.finished
	get_tree().change_scene_to_file("res://Scenes/game.tscn")
