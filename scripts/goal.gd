extends Area2D
## Level exit. Touch it to finish the level and load `next_level`.

## Scene to load when the player reaches the goal (main menu if empty)
@export_file("*.tscn") var next_level: String = "res://levels/main_menu.tscn"

@onready var sprite: Sprite2D = $Sprite2D

var _reached: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Gentle floating motion so the goal stands out
	var base_y := sprite.position.y
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "position:y", base_y - 12.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", base_y, 0.6).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node2D) -> void:
	if _reached or not body is Player:
		return
	_reached = true
	AudioManager.play_sfx(&"pickup")
	GameManager.complete_level(next_level)
