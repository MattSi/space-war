extends CanvasLayer


@onready var player: Player = get_tree().get_first_node_in_group("Player")
@onready var score_label: Label = $ScoreLabel
@onready var health_label: Label = $HealthLabel


func _ready() -> void:
	if player is Player:
		player.health_changed.connect(_on_health_changed)
		player.score_changed.connect(_on_score_changed)
		# The player sets its health before the HUD exists, so show it now
		_on_health_changed(player.health)


func _on_health_changed(value:int)->void:
	health_label.text = "Health: %d / %d" %[value, player.max_health]

func _on_score_changed(value:int)->void:
	score_label.text = "Score: " + str(value)
