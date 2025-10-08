extends Area2D

@export var speed: float = 900.0
@export var damage: int = 1
@export var life_time: float = 2.0


var velocity:Vector2 = Vector2.ZERO
var shooter:Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(true)
	$CollisionShape2D.disabled = false
	get_tree().create_timer(life_time).timeout.connect(queue_free)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position += velocity * delta

func setup(dir:Vector2, spd:float, dmg:int, bullet_owner:Node)->void:
	speed = spd
	damage = dmg
	velocity = dir.normalized()*speed
	shooter = bullet_owner
	


func _on_area_entered(area: Area2D) -> void:
	if area == shooter:
		return
	#print("Heat area： " + area.name)
	#if area.has_method("take_damage"):
		#area.call("take_damage", damage)
	#queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	print("Head body: "+ body.name)
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	queue_free()
