extends CharacterBody2D
class_name Player


signal health_changed(new_value : int)
signal score_changed(new_value : int)
signal died()


@export var max_health:int = 5

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

@export var SHOOT_COOLDOWN:float = 0.12
@export var BULLET_SPEED:float = 900.0
@export var BULLET_DAMAGE:int = 1
@export var MUZZLE_OFFSET:float=16.0
@export var BULLET_SCENE:PackedScene

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var jumps_left: int = MAX_JUMPS
var was_on_floor:bool = false
var is_dying: bool  = false
var coyote_time_left:float = 0.0
var jump_buffer_left:float = 0.0
var _is_invincible : bool = false
var health : set=set_health, get=get_health
var _health : int = 0
var _last_aim_dir:Vector2 = Vector2.RIGHT
var _shoot_cd: float = 0.0
var _angle_map = {
	0:180,
	23:158,
	45:135,
	68:113,
	90:90,
	135:45,
	158:23,
	180:0,
	203:338,
	225:315,
	248:293,
	270:270,
	293:248,
	315:225,
	338:203
}
@export var MUZZLE_OFFSETS := {
	0:  Vector2(16,-6),
	23: Vector2(15,-7),
	45: Vector2(13,-9),
	68: Vector2(10,-10),
	90: Vector2( 8,-11),
	135:Vector2( 6,-8),
	158:Vector2( 8,-6),
	180:Vector2(10,-5),
	203:Vector2(10,-5),
	225:Vector2( 8,-6),
	248:Vector2( 6,-8),
	270:Vector2( 8,-11),
	293:Vector2(10,-10),
	315:Vector2(13,-9),
	338:Vector2(15,-7)
}

func get_health()->int:
	return _health
	
func set_health(amount: int)->void:
	var clamped := clampi(amount, 0, max_health)
	if clamped == _health:
		# if there is no change, we can stop here
		return
	_health = clamped
	emit_signal("health_changed", _health)
	
	if _health <=0:
		emit_signal("died")

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
	
	# Deal with Jump buffer / Second Jump
	if not was_on_floor and is_on_floor():
		if jump_buffer_left > 0.0:
			velocity.y = JUMP_VELOCITY
			jumps_left = MAX_JUMPS - 1
			jump_buffer_left = 0.0
		else:
			jumps_left = MAX_JUMPS				

	#Shooting
	_shoot_cd = max(_shoot_cd -delta, 0.0)
	var rt:=Input.get_action_strength("shoot_rt")>=0.5
	var did_shoot:bool = false
	if lt and rt:
		_shoot(aim_dir)		
		did_shoot = true
	#Animation
	if lt:
		if not did_shoot:
			var angle_anim:int =_play_angle_anim(aim_dir)
			var anim_pfix:="idle_"
			_safe_play(anim_pfix+str(angle_anim))
	else:
		direction = Input.get_axis("move_left", "move_right")
		if is_on_floor():
			if direction == 0:
				_safe_play("idle") 
			else:
				_safe_play("run")
		else:
			_safe_play("jump")

func _shoot(dir:Vector2)->void:
	if _shoot_cd > 0.0:
		return
	if BULLET_SCENE == null:
		push_warning("No bullet_scene, can not shoot")
		return
	if dir.length() < 0.5:
		return
	_shoot_cd = SHOOT_COOLDOWN
	var angle_anim:int =_play_angle_anim(dir)
	var anim_pfix:="shoot_"
	
	_safe_play(anim_pfix+str(angle_anim))
	var local_position :Vector2 = MUZZLE_OFFSETS.get(angle_anim, Vector2(16, -6))
	var new_bullet:=BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(new_bullet)
	new_bullet.global_position = global_position + local_position
	new_bullet.rotation = dir.angle()
	
	
	if new_bullet.has_method("setup"):
		new_bullet.call("setup", dir.normalized(), BULLET_SPEED, BULLET_DAMAGE, self)
	
	
func _muzzle_global_pos(dir:Vector2)->Vector2:
	return global_position + Vector2(MUZZLE_OFFSET, 0.0).rotated(dir.angle())
func _ready() -> void:
	pass
	
	
func _play_angle_anim(dir: Vector2)->int:
	if dir.length() < 0.5:
		return 0
	var deg:= rad_to_deg(atan2(-dir.y, dir.x))
	deg = int(fposmod(deg, 360.0))
	
	var angle_label:=_sector_label_from_angle(deg)	
	return angle_label
	
	
		
func _sector_label_from_angle(deg:int) ->int:
	var step := 360.0 / float(AIM_SECTORS)
	var idx := int(floor(((deg + 360) % 360) / step)) % AIM_SECTORS
	var final_angle := int(round(idx * step))
	if animated_sprite_2d.flip_h == true:
		final_angle = _angle_map.get(final_angle, 45)
	return final_angle
	
func _safe_play(anim_name: String) -> void:
	if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation(anim_name):
		if animated_sprite_2d.animation != anim_name:
			animated_sprite_2d.play(anim_name)

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
	
func _play_hurt_feedback()->void:
	pass
	
func take_damage(amount:int)->void:
	if _is_invincible:
		return
	health -=abs(amount)
	_play_hurt_feedback()
	
