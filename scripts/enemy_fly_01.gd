extends Area2D

enum State {PATROL, CHASE, DIVE, DEAD}

@export var carry_coin:int =0
@export var COIN_SCENE:PackedScene
@export_group("Patrol")
@export var patrol_radius: float = 120.0
@export var patrol_speed: float = 1.0
@export var patrol_center_offset: Vector2 = Vector2.ZERO

@export_group("CHASE")
@export var detect_range:float = 360.0
@export var dive_speed:float=520.0
@export var dive_accel:float=1600.0
@export var dive_trigger_dist:float = 180
@export var self_destruct_time:float = 2.0

@export_group("EXPLOSION")
@export var explode_radius:float = 64.0
@export var explode_damage:int = 1

@onready var sprite:AnimatedSprite2D = $AnimatedSprite2D
@onready var explosion_area:Area2D = $ExplosionArea
@onready var self_destruct_timer:Timer = $SelfDestruct


var _state:State = State.PATROL
var _origin:Vector2
var _theta:float = 0.0
var _player:Node2D
var _velocity:Vector2 = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_origin = global_position + patrol_center_offset
	explosion_area.monitoring = false
	
	self_destruct_timer.wait_time = self_destruct_time
	
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _state == State.DEAD:
		return
	
	_find_player_if_needed()
	match _state:
		State.PATROL:
			_patrol(delta)
			_try_detect_player()
		State.CHASE:
			_chase(delta)
			_try_start_dive()
		State.DIVE:
			_dive(delta)
	position += _velocity * delta
	
	if _velocity.x !=0:
		sprite.flip_h = _velocity.x>0
	
func _try_detect_player()->void:
	if _player and position.distance_to(_player.global_position) < detect_range:
		_state = State.CHASE
		
func _patrol(delta: float) ->void:
	_theta += patrol_speed * delta
	position = _origin + Vector2(cos(_theta), sin(_theta)) * patrol_radius
	
func _try_start_dive()->void:
	if _player and position.distance_to(_player.global_position)<dive_trigger_dist:
		_state = State.DIVE
		self_destruct_timer.start()
		
func _find_player_if_needed()->void:
	if not _player:
		_player = get_tree().get_first_node_in_group("Player")

func _chase(delte:float)->void:
	if not _player:
		return
	var dir = (_player.global_position - position).normalized()
	_velocity = dir * 200.0

func _dive(delta:float) ->void:
	if not _player:
		return
	var dir = (_player.global_position - position).normalized()
	_velocity = _velocity.move_toward(dir * dive_speed, dive_accel*delta)
	if position.distance_to(_player.global_position) < explode_radius*0.8:
		_explode()
	
func _explode() -> void:
	if _state == State.DEAD:
		return
	if carry_coin>0:
		var new_coin:=COIN_SCENE.instantiate()
		new_coin.global_position = global_position		
		get_tree().current_scene.call_deferred("add_child", new_coin)
	
	AudioManager.play_at(&"explode_enemy", global_position)	
	_state = State.DEAD
	explosion_area.monitoring = false
	sprite.play("explode")
	await sprite.animation_finished
	queue_free()


func _on_self_destruct_timeout() -> void:
	_explode()

func take_damage(amount:int)->void:
	_explode()

func _on_explosion_area_body_entered(body: Node2D) -> void:
	print("YYYYYYYYYYYYYYY")
	if body.is_in_group("Player"):
		body.call_deferred("take_damage", explode_damage)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.call_deferred("take_damage", explode_damage)
