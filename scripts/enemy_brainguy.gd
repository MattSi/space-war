extends Area2D

@export var fire_interval: float = 0.9
@export var bullet_speed:float = 900.0
@export var bullet_damage:int = 1
@export var bullet_scene: PackedScene

@onready var muzzle_left:Marker2D = $Muzzle_Left
@onready var muzzle_right:Marker2D = $Muzzle_Right
@onready var fire_timer:Timer = $FireTimer
@onready var range_detector:Area2D = $RangeDetector

var _has_target:bool = false
var _player:Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fire_timer.wait_time = fire_interval
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _has_target and _player and is_instance_valid(_player):
		var dir:= (_player.global_position - global_position).angle()-90
		rotation = dir




func _on_fire_timer_timeout() -> void:
	# Shoot
	if not _has_target or bullet_scene == null or not _player:
		return
	
	var b_left = bullet_scene.instantiate()
	get_tree().current_scene.add_child(b_left)
	b_left.global_position = muzzle_left.global_position
	b_left.global_rotation = muzzle_left.global_rotation	
	b_left.collision_layer = 8
	b_left.collision_mask = 1
	var dir_left:= (_player.global_position - muzzle_left.global_position).normalized()
	if b_left.has_method("setup"):
		b_left.call("setup", dir_left, bullet_speed, bullet_damage, self)
	
	var b_right = bullet_scene.instantiate()
	get_tree().current_scene.add_child(b_right)
	b_right.global_position = muzzle_right.global_position
	b_right.global_rotation = muzzle_right.global_rotation
	b_right.collision_layer = 8
	b_right.collision_mask = 1
	var dir_right:=(_player.global_position - muzzle_right.global_position).normalized()
	if b_right.has_method("setup"):
		b_right.call("setup", dir_right, bullet_speed, bullet_damage, self)
	
	

func _on_range_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_has_target = true
		_player = body
		if fire_timer.is_stopped():
			fire_timer.start()


func _on_range_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_has_target = false
		_player = null
		fire_timer.stop()
