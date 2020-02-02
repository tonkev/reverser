extends Node2D

var finished = false

func _process(delta):
	if not finished:
		for body in $Area2D.get_overlapping_bodies():
			if body.is_in_group("player"):
				$AnimationPlayer.play("Finish")
				finished = true
