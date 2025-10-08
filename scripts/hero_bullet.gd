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
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup(dir:Vector2, spd:float, dmg:int, owner:Node)->void:
	speed = spd
	damage = dmg
	velocity = dir.normalized()*speed
	shooter = owner
	


func _on_area_entered(area: Area2D) -> void:
	pass # Replace with function body.


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
