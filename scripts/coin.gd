extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var coin_type:int = 1


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * 1.5 * delta
	move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if body.has_method("power_up"):
			body.call("power_up",)
		$Area2D.monitoring = false
		call_deferred("queue_free")
		
