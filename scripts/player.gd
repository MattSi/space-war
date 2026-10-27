extends CharacterBody2D
class_name Player


signal health_changed(new_value : int)
signal score_changed(new_value : int)
signal died()

@export var is_powerup:bool = false
@export var max_health:int = 5
@export var invincibility_duration : float = 0.8
@export var flash_interval : float = 0.08
@export var hurt_tint :Color = Color(1, 0.6, 0.6, 1.0)
@export var SPEED: float = 300.0
@export var JUMP_VELOCITY: float = -600.0
@export var JUMP_CUT_MULTIPLIER : float = 0.5
@export var COYOTE_TIME: float = 0.12
@export var JUMP_BUFFER_TIME: float = 0.12
const MAX_JUMPS: int = 2

@export var AIM_DEADZONE:float = 0.25
@export var AIM_SECTORS:int = 16
@export var USE_MIRROS_FRAMES:bool = true
@export var RUN_WHEN_AIMING:bool = true

@export var SHOOT_COOLDOWN:float = 0.12
@export var SHOOT_ANIM_HOLD:float = 0.2
@export var BULLET_SPEED:float = 900.0
@export var BULLET_DAMAGE:int = 1
@export var MUZZLE_OFFSET:float=16.0
@export var BULLET_SCENE:PackedScene

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_hurt:AudioStreamPlayer2D = $SfxHurt
@onready var sfx_dead:AudioStreamPlayer2D = $SfxDead
@onready var i_frame_timer:Timer = $IFramesTimer
@onready var flash_timer:Timer = $FlashTimer
@onready var muzzles:Node = $Muzzles

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
var _shoot_anim_left: float = 0.0
var _base_modulate:Color = Color(1,1,1,1)

var flap_h_shoot_mapping ={
	0:180,
	45:135,
	90:90,
	135:45,
	180:0,
	225:315,
	315:225,
	270:270
}

func _ready() -> void:
	_base_modulate = animated_sprite_2d.modulate
	health = max_health
	# Hooks up death handling and moves us to the last checkpoint
	GameManager.register_player(self)
	
func get_health()->int:
	return _health
	
func set_health(amount: int)->void:
	var clamped := clampi(amount, 0, max_health)
	if clamped == _health:
		return
	_health = clamped
	emit_signal("health_changed", _health)
	
	if _health <=0:
		_start_die()

func take_damage(amount:int)->void:
	if _is_invincible or is_dying:
		return
	health -=abs(amount)
	if is_dying:
		return
	_play_hurt_feedback()
	
func _physics_process(delta: float) -> void:
	var direction:float = 0.0
	if is_dying:
		velocity.x = move_toward(velocity.x, 0, 5000.0*delta)
		velocity.y = move_toward(velocity.y, 0, 5000.0*delta)
		move_and_slide()
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
		AudioManager.play_at(&"jump", global_position)
	elif Input.is_action_just_pressed("jump") and jumps_left>0 and velocity.y < 0.0:
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1
			jump_buffer_left = 0.0
			AudioManager.play_at(&"jump_high", global_position)
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	var lt:=Input.get_action_strength("aim_lt") >=0.5
	var aim_dir:=_last_aim_dir
	
	if lt:
		var move_axis :=0.0
		if RUN_WHEN_AIMING:
			move_axis = Input.get_axis("move_left", "move_right")
		velocity.x = move_axis * SPEED
		_face(move_axis)

		var ls := Input.get_vector("mv_left", "mv_right", "mv_up", "mv_down")
		if ls.length() >= AIM_DEADZONE:
			aim_dir = ls.normalized()
			_last_aim_dir = aim_dir
		else:
			# No aim input: keep the last aim, mirrored to match the facing side
			var facing_x := -1.0 if animated_sprite_2d.flip_h else 1.0
			if aim_dir.x * facing_x < 0.0:
				aim_dir.x = -aim_dir.x
	else:
		direction = Input.get_axis("move_left","move_right")
		if direction != 0.0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		_face(direction)
	
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
	_shoot_anim_left = max(_shoot_anim_left - delta, 0.0)
	var rt:=Input.get_action_strength("shoot_rt")>=0.5
	var did_shoot:bool = false
	if rt:
		if lt:
			_shoot(aim_dir)
		else:
			# Not aiming: fire straight ahead in the facing direction
			_shoot(Vector2.LEFT if animated_sprite_2d.flip_h else Vector2.RIGHT)
		did_shoot = true
	#Animation
	if lt:
		if not did_shoot:
			var angle_anim:int = _play_angle_anim(aim_dir)
			var anim_pfix:="idle_"			
			_safe_play(anim_pfix+str(angle_anim))
	else:
		direction = Input.get_axis("move_left", "move_right")
		if is_on_floor():
			if direction == 0:
				# Let the shoot animation show briefly before going back to idle
				if _shoot_anim_left <= 0.0:
					_safe_play("idle")
			else:
				_safe_play("run")
		else:
			
			_safe_play("jump")

# Turn the sprite toward the movement direction (no change when standing still)
func _face(move_dir: float) -> void:
	if move_dir > 0:
		animated_sprite_2d.flip_h = false
	elif move_dir < 0:
		animated_sprite_2d.flip_h = true

func _shoot(dir:Vector2)->void:
	if _shoot_cd > 0.0:
		return
	if BULLET_SCENE == null:
		push_warning("No bullet_scene, can not shoot")
		return
	if dir.length() < 0.5:
		return
	
	
	var angle_anim:int =_play_angle_anim(dir)
	
	var muzzle:Marker2D = _get_muzzle_by_angle(angle_anim)
	if muzzle == null:
		return	
	var muzzle_center:Marker2D = muzzles.get_node("Muzzle_Center")
	var anim_pfix:="shoot_"
	_shoot_cd = SHOOT_COOLDOWN
	_shoot_anim_left = SHOOT_ANIM_HOLD
	_safe_play(anim_pfix+str(angle_anim))
	
	var new_bullet:=BULLET_SCENE.instantiate()
	var shoot_dir = (muzzle.global_position - muzzle_center.global_position).normalized()
	new_bullet.global_position = muzzle.global_position
	get_tree().current_scene.add_child(new_bullet)
	
	new_bullet.rotation = dir.angle()
	new_bullet.collision_layer = 2
	new_bullet.collision_mask = 8
	
	var anim_name:StringName = "default"
	if is_powerup:
		anim_name="powerup"
	if new_bullet.has_method("setup"):
		new_bullet.call("setup", shoot_dir.normalized(), BULLET_SPEED, BULLET_DAMAGE,anim_name, self)
	AudioManager.play_at(&"player_shot", global_position)
		
	
	

func _get_muzzle_by_angle(angle_deg:int)->Marker2D:
	if animated_sprite_2d.flip_h:
		angle_deg = flap_h_shoot_mapping.get(angle_deg)
	var muzzle_name = "Muzzle_"+str(angle_deg)	
	if muzzles.has_node(muzzle_name):
		return muzzles.get_node(muzzle_name)
	else:
		return null
	
func _muzzle_global_pos(dir:Vector2)->Vector2:
	return global_position + Vector2(MUZZLE_OFFSET, 0.0).rotated(dir.angle())

	
	
func _play_angle_anim(dir: Vector2)->int:
	if dir.length() < 0.5:
		return 0
	
	var d:=dir
	if animated_sprite_2d.flip_h:
		d.x = -d.x
	var angle:float = d.angle_to(Vector2.RIGHT)
	var angle_deg:float = rad_to_deg(angle)
	if angle_deg < 0:
		angle_deg += 360
	
	if angle_deg > 338 or angle_deg <=23:
		return 0
	elif angle_deg>23 and angle_deg <=68:
		return 45
	elif angle_deg>68 and angle_deg<=113:
		return 90
	elif angle_deg>113 and angle_deg<=158:
		return 135
	elif angle_deg>158 and angle_deg<=203:
		return 180
	elif angle_deg>203 and angle_deg<=248:
		return 225
	elif angle_deg>293 and angle_deg<=338:
		return 315
	else:
		return 270 # Never use this angle
	

	
func _safe_play(anim_name: String) -> void:
	if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation(anim_name):
		if animated_sprite_2d.animation != anim_name:
			animated_sprite_2d.play(anim_name)

func _start_die()->void:
	if is_dying:
		return
	is_dying = true
	velocity = Vector2.ZERO

	# Cancel hurt feedback so the death animation is fully visible
	_is_invincible = false
	i_frame_timer.stop()
	flash_timer.stop()
	visible = true
	animated_sprite_2d.modulate = _base_modulate

	animated_sprite_2d.play("die")
	await animated_sprite_2d.animation_finished
	died.emit()
	
func _play_hurt_feedback()->void:
	# 1. Sound
	if sfx_hurt and sfx_hurt.stream:
		sfx_hurt.play()
	# 2. invincibility on
	_is_invincible = true
	# 3. visual feedback: start flashing + tint
	animated_sprite_2d.modulate = hurt_tint
	flash_timer.wait_time = flash_interval	                       
	flash_timer.start()
	# 4. start i-frames timer
	i_frame_timer.start(invincibility_duration)
	pass
	

	


func _on_i_frames_timer_timeout() -> void:
	_is_invincible = false
	flash_timer.stop()
	visible = true	
	animated_sprite_2d.modulate = _base_modulate


func _on_flash_timer_timeout() -> void:
	visible = not visible

func power_up()->void:
	is_powerup = true
	pass
