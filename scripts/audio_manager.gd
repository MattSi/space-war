extends Node


@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var ui_player:AudioStreamPlayer = $UIPlayer
@onready var sfx_player:AudioStreamPlayer2D = $SFXPlayer

const MUSIC:={
	&"level1":preload("res://assets/Audio/The Only Thing They Fear Is You.mp3")
}
const SFX:={
	&"jump" :      preload("res://assets/Audio/sfx_jump.ogg"),
	&"jump_high" : preload("res://assets/Audio/sfx_jump-high.ogg"),
	&"player_shot": preload("res://assets/Audio/cg1.wav"),
	&"explode_enemy" : preload("res://assets/Audio/explosionCrunch_000.ogg"),
	&"explode_player" : preload("res://assets/SpritePack/Sounds/explode.ogg"),
	&"pickup" : preload("res://assets/Audio/pickup1.ogg"),
	&"impactMetal" : preload("res://assets/Audio/impactMetal_004.ogg"),
	&"laser_shot" : preload("res://assets/Audio/laserLarge_000.ogg")
}


func play_music(music_name:StringName)->void:
	var stream:AudioStream = MUSIC.get(music_name, null)
	if stream == null:
		push_warning("Unknown Music: %s" % String(music_name))
		return
	music_player.stream = stream
	music_player.volume_linear = 0.3
	music_player.play()
	
func stop_music(music_name:StringName)->void:
	music_player.stop();
	
func play_at(sfx_name :StringName, world_pos:Vector2)->void:
	var stream:AudioStream = SFX.get(sfx_name, null)
	if stream == null:
		push_warning("Unknown SFX: %s" % String(sfx_name))
		return
	var p:=AudioStreamPlayer2D.new()
	p.bus = sfx_player.bus
	p.stream = stream
	p.global_position = world_pos
	add_child(p)	
	p.finished.connect(p.queue_free)
	p.play()

func play_sfx(sfx_name:StringName)->void:
	var stream:AudioStream = SFX.get(sfx_name, null)
	if stream == null:
		push_warning("Unknown SFX: %s" % String(sfx_name))
		return
	ui_player.stream = stream
	ui_player.play()
	
func _ready() -> void:
	#pass
	play_music(&"level1")
		
		
		
