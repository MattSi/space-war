extends Node

const MAIN_MENU := "res://levels/main_menu.tscn"
## Short pause after touching the goal before the next level loads
const LEVEL_END_DELAY := 0.6

# Checkpoint progress for the level currently being played
var _checkpoint_scene: String = ""
var _checkpoint_pos: Vector2 = Vector2.ZERO
var _activated_checkpoints: Dictionary = {}  # checkpoint id -> true
var _changing_level: bool = false


## Called by the player when it spawns. Moves it to the last checkpoint, if any.
func register_player(player: Node2D) -> void:
	_changing_level = false
	player.died.connect(_on_player_died)
	if _checkpoint_scene != "" and _checkpoint_scene == _scene_path_of(player):
		player.global_position = _checkpoint_pos


func set_checkpoint(checkpoint: Node2D, spawn_pos: Vector2) -> void:
	_checkpoint_scene = _scene_path_of(checkpoint)
	_checkpoint_pos = spawn_pos
	_activated_checkpoints[_checkpoint_id(checkpoint)] = true


func is_checkpoint_activated(checkpoint: Node2D) -> bool:
	return _activated_checkpoints.has(_checkpoint_id(checkpoint))


## Forget all checkpoint progress (new game, or moving to another level).
func reset_progress() -> void:
	_checkpoint_scene = ""
	_checkpoint_pos = Vector2.ZERO
	_activated_checkpoints.clear()


func complete_level(next_level: String) -> void:
	if _changing_level:
		return
	_changing_level = true
	await get_tree().create_timer(LEVEL_END_DELAY).timeout
	reset_progress()
	if next_level == "" or not ResourceLoader.exists(next_level):
		next_level = MAIN_MENU
	get_tree().change_scene_to_file(next_level)


func _on_player_died() -> void:
	if _changing_level:
		return
	AudioManager.play_sfx(&"die")
	get_tree().call_deferred("reload_current_scene")


# The level a node belongs to (its owner is the level's root node)
func _scene_path_of(node: Node) -> String:
	if node.owner:
		return node.owner.scene_file_path
	var scene := get_tree().current_scene
	return scene.scene_file_path if scene else ""


func _checkpoint_id(checkpoint: Node) -> String:
	var root: Node = checkpoint.owner if checkpoint.owner else get_tree().current_scene
	return "%s:%s" % [_scene_path_of(checkpoint), root.get_path_to(checkpoint)]
