extends CharacterBody2D

@export var speed: float = 80.0
@export var left_limit: float = 1828.0
@export var right_limit: float = 2325.0
@export var wait_time: float = 2.0
@export var hp: int = 1
@export var coin_reward: int = 20

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction: int = 1 # 1 = right, -1 = left
var waiting: bool = false

func _ready():
	sprite.play("idle") # default animation
	add_to_group("Enemies") # <-- Add slime to Enemies group for blade detection

func _physics_process(delta):
	if hp <= 0:
		return # dead, no movement

	if waiting:
		velocity.x = 0
		return

	velocity.x = speed * direction
	move_and_slide()

	# Set walking animation
	if sprite.sprite_frames.has_animation("right"):
		if direction == 1:
			sprite.play("right")
			sprite.flip_h = false
		else:
			sprite.play("left")
			sprite.flip_h = false

	# Check limits
	if position.x >= right_limit and direction == 1:
		_start_wait(-1)
	elif position.x <= left_limit and direction == -1:
		_start_wait(1)

func _start_wait(new_direction: int) -> void:
	waiting = true
	velocity.x = 0
	sprite.play("idle")
	direction = new_direction
	# Start a timer for waiting
	var t = Timer.new()
	t.wait_time = wait_time
	t.one_shot = true
	add_child(t)
	t.start()
	t.timeout.connect(func():
		waiting = false
		t.queue_free()
	)

func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp -= amount
	if hp <= 0:
		die()

func die() -> void:
	sprite.play("death")
	Global.coins += coin_reward
	# Disable collision so player can pass through
	for c in get_children():
		if c is CollisionShape2D:
			c.disabled = true
