@onready var background = $Background
@onready var timer = $BackgroundTimer

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
