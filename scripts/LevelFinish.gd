extends Area2D

signal player_entered

func _ready():
	connect("player_entered", LevelSequencer, "_on_LevelFinish_player_entered")

func _process(_delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			emit_signal("player_entered")
