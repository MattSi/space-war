extends Area2D

@onready var sprite:AnimatedSprite2D = $AnimatedSprite2D
@onready var timer:Timer = $Timer

@export_enum("light01", "light02")
var select_anim:String ="light_01":
	set(value):
		select_anim = value
		if is_instance_valid(sprite):
			sprite.play(select_anim)
			
			
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.play(select_anim)
	_start_random_light()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _start_random_light() ->void:
	var wait_time = randf_range(2.0,3.0)
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.start()
	
	var anims = ["light_01", "light_02"]
	var chosen = anims[randi() % anims.size()]
	sprite.play(chosen)

func _on_timer_timeout() -> void:
	_start_random_light()


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
