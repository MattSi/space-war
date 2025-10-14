extends CharacterBody2D



const JUMP_VELOCITY = -400.0
@export var speed: float = 400.0
@export var gravity_scale: float = 1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var range: Area2D = $RangeDetector
@onready var t_explode: Timer = $ExplodeTimer

enum State {IDLE, CHARGE}
var state:State = State.IDLE

var player:Node2D = null
var charge_dir: int = 1
var charge_time: float = 0.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * gravity_scale * delta
	
	match state:
		State.IDLE:
			velocity.x = 0.0
		State.CHARGE:
			velocity.x = charge_dir * speed
			charge_time += delta
			if sprite:
				sprite.flip_h = (velocity.x < 0)

	move_and_slide()


func _on_range_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and state == State.IDLE:
		player = body
		charge_dir = sign((player.global_position - global_position).x)
		if charge_dir ==0:
			charge_dir = 1
		state = State.CHARGE
		charge_time = 0.0
		t_explode.stop()
		t_explode.start()


func _on_range_detector_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
	
func _explode()->void:
	state = State.IDLE
	velocity = Vector2.ZERO
	sprite.play("explode")
	await sprite.animation_finished
	queue_free()


func _on_explode_timer_timeout() -> void:
	_explode()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		player.take_damage(1)
		t_explode.stop()
		velocity	 = Vector2.ZERO
		sprite.play("explode")
		await sprite.animation_finished
		queue_free()
	
