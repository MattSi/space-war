extends Area2D
## Touch to save progress. After dying, the player respawns here.

## Respawn position relative to the checkpoint (slightly above the ground)
@export var spawn_offset: Vector2 = Vector2(0, -60)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _active: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_set_active(GameManager.is_checkpoint_activated(self))


func _on_body_entered(body: Node2D) -> void:
	if _active or not body is Player:
		return
	GameManager.set_checkpoint(self, global_position + spawn_offset)
	_set_active(true)
	AudioManager.play_at(&"pickup", global_position)


func _set_active(value: bool) -> void:
	_active = value
	sprite.play(&"on" if value else &"off")
