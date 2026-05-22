extends Node2D

@onready var player = $Player

var cutscene_scene = preload("res://Scenes/Cutscene.tscn")
var cutscene_instance

func _ready():
	start_prologue()

func start_prologue():
	player.set_process(false)
	player.set_physics_process(false)

	cutscene_instance = cutscene_scene.instantiate()
	add_child(cutscene_instance)

	cutscene_instance.start_prologue()
	cutscene_instance.tree_exited.connect(_on_cutscene_finished)

func _on_cutscene_finished():
	player.set_process(true)
	player.set_physics_process(true)
