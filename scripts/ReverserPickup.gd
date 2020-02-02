extends Area2D

func _physics_process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.get_reverser()
			get_parent().remove_child(self)
