extends StaticBody2D

@onready var ray_up:RayCast2D = $RayCast_Up
@onready var timer:Timer = $Timer
@onready var sprite:AnimatedSprite2D = $AnimatedSprite2D

var trigger:bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ray_up.enabled = true
	timer.one_shot = true
	timer.stop()
	timer.timeout.connect(_on_timer_timeout)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if trigger:
		return 
	
	ray_up.force_raycast_update()
	if ray_up.is_colliding():	
		var hit: = ray_up.get_collider()
		if hit and (hit.is_in_group("Player") or hit.name == "Player"):
			trigger = true
			timer.start(1.0)
			ray_up.enabled = false
	pass


func _on_timer_timeout() -> void:
	if sprite.sprite_frames.has_animation("explode"):
		AudioManager.play_at(&"explode_enemy", global_position)
		sprite.play("explode")
		await sprite.animation_finished
	queue_free()
