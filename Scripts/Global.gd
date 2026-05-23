extends Node


# Variables
var game_camera: Camera2D = null
var hp: int = 3
var coins: int = 0
var panic: float = 0
var panic_change: float = 0
var enemyHP: int = 5
var key: bool = false
var dash_duration: float = 0.1
var dash_speed: float = 600.0
var speed: float = 200.0
var is_talking: bool = false
var dash_multiplier: int = 1

signal mission_changed(new_mission)

var current_mission := 1:
	set(value):
		current_mission = value
		emit_signal("mission_changed", value)
		
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
