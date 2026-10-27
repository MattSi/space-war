extends CharacterBody2D


var SPEED:float = 200.0
var BULLET_SPEED:float = 500.0
const JUMP_VELOCITY = -400.0
@export var BULLET_SCENE:PackedScene

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_left:RayCast2D = $RayLeft
@onready var ray_right:RayCast2D = $RayRight
@onready var sprite:AnimatedSprite2D = $AnimatedSprite2D
# Muzzle position when facing right; x is mirrored when facing left
const MUZZLE_OFFSET := Vector2(30, -40)
var direction: int=1

func _ready() -> void:
	_set_direction(direction)

# The sprite art faces left, so flip it when walking right
func _set_direction(dir: int) -> void:
	direction = dir
	animated_sprite_2d.flip_h = dir > 0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if ray_right.is_colliding():
		_set_direction(-1)
	if ray_left.is_colliding():
		_set_direction(1)

	velocity.x = direction * SPEED

	move_and_slide()


func _on_shoot_timer_timeout() -> void:
	var bullet_type:StringName = "default"
	var b = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = global_position + Vector2(MUZZLE_OFFSET.x * direction, MUZZLE_OFFSET.y)
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
