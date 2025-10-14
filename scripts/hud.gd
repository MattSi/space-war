extends CanvasLayer


@onready var player: Player = get_tree().get_first_node_in_group("Player")
@onready var score_label: Label = $ScoreLabel
@onready var health_label: Label = $HealthLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if player is Player:
		player.health_changed.connect(_on_health_changed)
		player.score_changed.connect(_on_scroe_changed)
		player.died.connect(_on_player_died)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_health_changed(value:int)->void:
	health_label.text = "Health: %d / %d" %[value, player.max_health]
	
func _on_scroe_changed(value:int)->void:
	score_label.text = "Score: " + str(value)
	
func _on_player_died(value:int)->void:
	pass
	
