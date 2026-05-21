extends Control

var prologue_images = [
	"res://Scenes/Prologue/prologue_1.png",
	"res://Scenes/Prologue/prologue_2.png",
	"res://Scenes/Prologue/prologue_3.png"
]

var images = []
var index = 0

@onready var background: TextureRect = $Background

func _ready():
	# Make root fill the viewport
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	# Make Background fill the actual game window
	background.position = Vector2.ZERO
	background.size = get_viewport_rect().size
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE

	start_prologue()

func start_prologue():
	images = prologue_images
	index = 0
	show_image()

func show_image():
	if index >= images.size():
		get_tree().change_scene_to_file("res://Scenes/game.tscn")
		return

	var tex = load(images[index])
	if tex == null:
		print("FAILED TO LOAD: ", images[index])
		return

	background.texture = tex
	print("Showing image: ", images[index])

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		index += 1
		show_image()

func _notification(what):
	if what == NOTIFICATION_RESIZED and background != null:
		background.size = get_viewport_rect().size
