extends KinematicBody2D

var _animation_player
var _repaired_sfx

var repaired = false

func _ready():
	_animation_player = $AnimationPlayer
	_repaired_sfx = $RepairedSFX
	_animation_player.connect("animation_finished", self, "_on_AnimationPlayer_finished")

func repair():
	if not repaired:
		_animation_player.play("Repair")
		repaired = true
	return _animation_player.is_playing()

func _on_AnimationPlayer_finished(anim_name):
	if anim_name == "Repair":
		_repaired_sfx.play()
