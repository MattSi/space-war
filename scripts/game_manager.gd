extends Node

@export var level1:PackedScene = preload("res://levels/level1.tscn")
@export var level2:PackedScene = preload("res://levels/level2.tscn")
@export var main_menu:PackedScene = preload("res://levels/main_menu.tscn")

func	 _ready() -> void:
	_connect_player_signals()
	get_tree().node_added.connect(_on_node_added)
	
func _on_node_added(_n:Node)->void:
	_connect_player_signals()
	
func _connect_player_signals()->void:
	var player:=get_tree().get_first_node_in_group("Player")
	if player and not player.is_connected("died", Callable(self, "_on_player_died")):
		player.died.connect(_on_player_died)
		
func _on_player_died()->void:
	AudioManager.play_sfx("die")
	get_tree().call_deferred("reload_current_scene")
	
func _on_player_wins()->void:
	get_tree().call_deferred("change_scene_to_packed", level1)
