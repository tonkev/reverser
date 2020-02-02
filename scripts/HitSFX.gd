extends AudioStreamPlayer2D

func someone_died(someone):
	global_position = someone.global_position
	play()
