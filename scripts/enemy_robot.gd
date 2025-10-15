extends CharacterBody2D


var SPEED:float = 200.0
var BULLET_SPEED:float = 500.0
const JUMP_VELOCITY = -400.0
@export var BULLET_SCENE:PackedScene

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_left:RayCast2D = $RayLeft
@onready var ray_right:RayCast2D = $RayRight
@onready var sprite:AnimatedSprite2D = $AnimatedSprite2D
var muzzle_offset:=Vector2(-30, -40)
var direction: int=1

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if ray_right.is_colliding():
		direction = -1
		muzzle_offset.x = -muzzle_offset.x
		animated_sprite_2d.flip_h = false
	if ray_left.is_colliding():
		direction = 1
		animated_sprite_2d.flip_h = true

	velocity.x = direction * SPEED

	move_and_slide()


func _on_shoot_timer_timeout() -> void:
	var bullet_type:StringName = "default"
	var b = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = global_position + muzzle_offset
	b.global_rotation = global_rotation	
	b.collision_layer = 8
	b.collision_mask = 5
	var dir:Vector2 = Vector2(direction, 0).normalized()
	if b.has_method("setup"):
		b.call("setup", dir, BULLET_SPEED, 1,bullet_type, self)


func _explode() -> void:

	AudioManager.play_at(&"explode_enemy", global_position)	
	#velocity.x=velocity.y=0
	$Area2D.monitoring = true
	sprite.play("dead")
	await sprite.animation_finished
	queue_free()
	


func take_damage(amount:int)->void:
	_explode()
