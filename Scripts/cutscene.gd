extends Control

var voice_path := "res://Scenes/Prologue/cutscene_sound.ogg"

var prologue_slides = [
	{
		"image": "res://Scenes/Prologue/prologue_1.png",
		"subtitle": "There was a child who learned early that silence was safer than words. A child who grew up in rooms where laughter was rare… and footsteps meant fear.",
		"duration": 7.0
	},
	{
		"image": "res://Scenes/Prologue/prologue_2.png",
		"subtitle": "Over time, his mind built a place of its own — a space where nothing could hurt him. But minds are strange things… What is built to protect… can also become a prison.",
		"duration": 8.0
	},
	{
		"image": "res://Scenes/Prologue/prologue_3.png",
		"subtitle": "And in this space… the child still runs. From things he cannot name. From things he cannot escape.",
		"duration": 6.0
	}
]

var index := 0
var fade_time := 0.4

var subtitle_label: Label
var voice_player: AudioStreamPlayer
var black_bg: ColorRect
var current_tween: Tween

var skip_requested := false
var playing := false

@onready var background: TextureRect = $Background


func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Black background behind image for fade effect
	black_bg = ColorRect.new()
	black_bg.color = Color.BLACK
	add_child(black_bg)
	black_bg.z_index = -10

	# Background image
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 0
	background.offset_top = 0
	background.offset_right = 0
	background.offset_bottom = 0
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = 0

	# Subtitle label created by script
	subtitle_label = Label.new()
	add_child(subtitle_label)

	subtitle_label.text = ""
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 26)
	subtitle_label.add_theme_color_override("font_color", Color.WHITE)
	subtitle_label.add_theme_color_override("font_outline_color", Color.BLACK)
	subtitle_label.add_theme_constant_override("outline_size", 4)
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle_label.z_index = 10

	# Voice player created by script
	voice_player = AudioStreamPlayer.new()
	add_child(voice_player)
	voice_player.volume_db = 0.0

	resize_nodes()

	set_alpha(background, 0.0)
	set_alpha(subtitle_label, 0.0)

	play_cutscene()


func resize_nodes():
	var screen_size = get_viewport_rect().size

	black_bg.position = Vector2.ZERO
	black_bg.size = screen_size

	background.position = Vector2.ZERO
	background.size = screen_size

	subtitle_label.position = Vector2(80, screen_size.y - 260)
	subtitle_label.size = Vector2(screen_size.x - 160, 220)


func play_cutscene() -> void:
	if playing:
		return

	playing = true

	# Load and play one full voice recording
	var voice_stream: AudioStream = load(voice_path)

	if voice_stream == null:
		print("FAILED TO LOAD VOICE: ", voice_path)
	else:
		voice_player.stream = voice_stream
		voice_player.play()

	while index < prologue_slides.size():
		skip_requested = false
		await play_slide(prologue_slides[index])
		index += 1

	if voice_player.playing:
		voice_player.stop()

	get_tree().change_scene_to_file("res://Scenes/game.tscn")


func play_slide(slide: Dictionary) -> void:
	var tex = load(slide["image"])

	if tex == null:
		print("FAILED TO LOAD IMAGE: ", slide["image"])
		return

	background.texture = tex
	subtitle_label.text = slide["subtitle"]

	print("Showing image: ", slide["image"])

	# Start invisible
	set_alpha(background, 0.0)
	set_alpha(subtitle_label, 0.0)

	# Fade in
	await fade_to(1.0)

	# Stay visible
	var elapsed := 0.0
	var duration: float = slide["duration"]

	while elapsed < duration and not skip_requested:
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	# Fade out
	await fade_to(0.0)


func fade_to(alpha: float) -> void:
	if current_tween != null:
		current_tween.kill()

	current_tween = create_tween()
	current_tween.set_parallel(true)

	current_tween.tween_property(background, "modulate:a", alpha, fade_time)
	current_tween.tween_property(subtitle_label, "modulate:a", alpha, fade_time)

	await current_tween.finished


func set_alpha(node: CanvasItem, alpha: float):
	var c = node.modulate
	c.a = alpha
	node.modulate = c


func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		skip_requested = true


func _notification(what):
	if what == NOTIFICATION_RESIZED:
		resize_nodes()
