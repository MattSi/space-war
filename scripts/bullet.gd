extends Area2D

@export var speed: float = 900.0
@export var damage: int = 1
@export var life_time: float = 2.5


@onready var sprite:AnimatedSprite2D = $AnimatedSprite2D
@onready var collider:CollisionShape2D = $CollisionShape2D

var velocity:Vector2 = Vector2.ZERO
var shooter:Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(true)
	$CollisionShape2D.disabled = false
	get_tree().create_timer(life_time).timeout.connect(queue_free)
	sprite.animation_changed.connect(_on_animation_changed)
	sprite.frame_changed.connect(_on_frame_changed)

func _on_animation_changed()->void:
	pass

func _on_frame_changed()->void:
	pass
	
func _update_collider_to_frame()->void:
	var tex:Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex and collider.shape is RectangleShape2D:
		var shape := collider.shape as RectangleShape2D
		shape.size = tex.get_size() * sprite.scale
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position += velocity * delta

func setup(dir:Vector2, spd:float, dmg:int, _animation:StringName, bullet_owner:Node)->void:
	speed = spd
	damage = dmg
	velocity = dir.normalized()*speed
	shooter = bullet_owner
	sprite.play(_animation)
	

func _on_area_entered(area: Area2D) -> void:
	if area == shooter:
		return
	if area.has_method("take_damage"):
		area.call("take_damage", damage)
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	queue_free()
