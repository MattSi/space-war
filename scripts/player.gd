extends CharacterBody2D


const SPEED: float = 300.0
const JUMP_VELOCITY: float = -600.0
const JUMP_CUT_MULTIPLIER : float = 0.5
const MAX_JUMPS: int = 2



@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var jumps_left: int = MAX_JUMPS
var was_on_floor:bool = false

func _physics_process(delta: float) -> void:
	was_on_floor = is_on_floor()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += 1.5*get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true
	
	move_and_slide()
	
	if not was_on_floor and is_on_floor():
		jumps_left = MAX_JUMPS
			
	if is_on_floor():
		if direction == 0:
			animated_sprite_2d.play("idle") 
		else:
			animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("jump")
		
	# TODO ADD COYOTE TIME
	# TODO ADD JUMP BUFFER
