extends CharacterBody2D


@export var SPEED: float = 300.0
@export var JUMP_VELOCITY: float = -600.0
@export var JUMP_CUT_MULTIPLIER : float = 0.5
@export var COYOTE_TIME: float = 0.12
@export var JUMP_BUFFER_TIME: float = 0.12
const MAX_JUMPS: int = 2

@export var AIM_DEADZONE:float = 0.25
@export var AIM_SECTORS:int = 16
@export var USE_MIRROS_FRAMES:bool = true
@export var RUN_WHEN_AIMING:bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var jumps_left: int = MAX_JUMPS
var was_on_floor:bool = false
var is_dying: bool  = false
var coyote_time_left:float = 0.0
var jump_buffer_left:float = 0.0

var _last_aim_dir:Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	var direction:float = 0.0
	if is_dying:
		velocity.x = move_toward(velocity.x, 0, 5000.0*delta)
		velocity.y = move_toward(velocity.y, 0, 5000.0*delta)
		move_and_slide()
		return

	if Input.is_action_just_pressed("test_action"):
		_start_die()
		return		
	
	was_on_floor = is_on_floor()
	
	# Update coyote time
	if is_on_floor():
		coyote_time_left = COYOTE_TIME
	else:
		coyote_time_left = max(coyote_time_left - delta, 0.0)
		
	# JUMP BUFFER 
	if Input.is_action_just_pressed("jump"):
		jump_buffer_left = JUMP_BUFFER_TIME
	else:
		jump_buffer_left = max(jump_buffer_left-delta, 0.0)
	# Add the gravity.
	if not is_on_floor():
		velocity += 1.5*get_gravity() * delta

	# Handle jump.
	if jump_buffer_left>0.0 and (is_on_floor() or coyote_time_left>0.0):
		velocity.y = JUMP_VELOCITY
		jumps_left = MAX_JUMPS - 1
		coyote_time_left = 0.0
		jump_buffer_left = 0.0	
	elif Input.is_action_just_pressed("jump") and jumps_left>0 and velocity.y < 0.0:
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1
			jump_buffer_left = 0.0
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	var lt:=Input.get_action_strength("aim_lt") >=0.5
	var aim_dir:=_last_aim_dir
	
	if lt:
		var ls := Input.get_vector("mv_left", "mv_right", "mv_up", "mv_down")
		if ls.length() >= AIM_DEADZONE:
			aim_dir = ls.normalized()
			_last_aim_dir = aim_dir
		
		var move_axis :=0.0
		if RUN_WHEN_AIMING:
			move_axis = Input.get_axis("move_left", "move_right")
		velocity.x = move_axis * SPEED
	else:
		direction = Input.get_axis("move_left","move_right")
		if direction != 0.0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
		if direction > 0:
			animated_sprite_2d.flip_h = false
		elif direction < 0:
			animated_sprite_2d.flip_h = true
	
	move_and_slide()
	
	if not was_on_floor and is_on_floor():
		if jump_buffer_left > 0.0:
			velocity.y = JUMP_VELOCITY
			jumps_left = MAX_JUMPS - 1
			jump_buffer_left = 0.0
		else:
			jumps_left = MAX_JUMPS
			
	#Animation
	if lt:
		_play_angle_anim(aim_dir)
	else:
		direction = Input.get_axis("move_left", "move_right")
		if is_on_floor():
			if direction == 0:
				_safe_play("idle") 
			else:
				_safe_play("run")
		else:
			_safe_play("jump")

	var rt:=Input.get_action_strength("shoot_rt")>=0.5
	if lt and rt:
		_shoot(aim_dir)		
	
	# TODO ADD JUMP BUFFER
func _shoot(dir:Vector2)->void:
	pass
	
func _play_angle_anim(dir: Vector2)->void:
	if dir.length() < 0.5:
		return
	var deg:= rad_to_deg(atan2(-dir.y, dir.x))
	deg = int(ceil(deg+360.0)) % 360
	
	var label:=_sector_label_from_angle(deg)
	
	var base:="idle_"
	_safe_play(base+label)
	
	
	
	pass
func _sector_label_from_angle(deg:int) ->String:
	var step := 360.0 / float(AIM_SECTORS)
	var idx := int(floor(((deg + 360) % 360) / step)) % AIM_SECTORS
	var snapped := int(round(idx * step))
	return str(snapped)
	
func _safe_play(name: String) -> void:
	if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation(name):
		if animated_sprite_2d.animation != name:
			animated_sprite_2d.play(name)

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_dying and animated_sprite_2d.animation == "die":
		is_dying = false
		jumps_left = MAX_JUMPS
		
		if is_on_floor():
			var direction := Input.get_axis("move_left", "move_right")
			if direction == 0:
				animated_sprite_2d.play("idle")
			else:
				animated_sprite_2d.play("run")
		else:
			animated_sprite_2d.play("jump")

func _start_die()->void:
	is_dying = true
	velocity = Vector2.ZERO
	
	animated_sprite_2d.play("die")
	
